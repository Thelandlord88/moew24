#!/usr/bin/env bash
# performance.sh — large assets, heavy modules, barrel imports, CSS sprawl (cheap, static signals)
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/performance.json"
mkdir -p "$REPORT_DIR"

# thresholds (override via env)
LARGE_IMG_KB="${LARGE_IMG_KB:-500}"
LARGE_JS_KB="${LARGE_JS_KB:-500}"
LONG_CSS_BYTES="${LONG_CSS_BYTES:-20000}" # ~20KB as a rough heuristic

scan() {
  local large_images=0 large_js=0 barrel_imports=0 css_sprawl=0

  # Large images (png/jpg > threshold)
  large_images=$(( $(find public src -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -size +"${LARGE_IMG_KB}"k 2>/dev/null | wc -l | tr -d ' ') ))

  # Large JS/TS modules
  large_js=$(( $(find src -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.ts' -o -iname '*.tsx' \) -size +"${LARGE_JS_KB}"k 2>/dev/null | wc -l | tr -d ' ') ))

  # Barrel imports (index.ts that re-exports *)
  barrel_imports=$(( $(grep -RIl --binary-files=without-match -E 'export\s+\*\s+from' src 2>/dev/null | wc -l | tr -d ' ') ))

  # CSS sprawl (very large css files)
  css_sprawl=$(( $(find src -type f -iname '*.css' -size +"${LONG_CSS_BYTES}"c 2>/dev/null | wc -l | tr -d ' ') ))

  local issues=$(( large_images + large_js + barrel_imports + css_sprawl ))
  local status="pass"; [[ $issues -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "performance",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "large_images": $large_images,
    "large_js_modules": $large_js,
    "barrel_imports": $barrel_imports,
    "css_sprawl": $css_sprawl
  },
  "actions": [
    "Convert images to WebP/AVIF; resize or lazy-load",
    "Split large JS/TS modules; code-split where appropriate",
    "Avoid barrel exports; import directly from leaf modules",
    "Modularize large CSS; remove unused rules"
  ],
  "policy_invariants": [
    "counts.large_images == 0",
    "counts.large_js_modules == 0"
  ],
  "eta_minutes": 30,
  "unlocks": ["accessibility","code_quality"]
}
JSON
}

scan "."
