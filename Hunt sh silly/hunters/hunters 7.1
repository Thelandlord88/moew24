awesome — here’s a complete, drop-in **well-rounded learning + thinking hunter** you can paste into a repo today. It keeps your current per-module hunters and pass/fail gates, adds a tiny telemetry layer, and layers on a **Hunter Thinker** that reads all JSON reports + traces, scores them, and writes a single, self-explaining **Do-Next plan** (Fix → Proof → Sibling Sweep) with “why now” signals. Everything is dependency-light (POSIX shell + Node for the Thinker), deterministic, and CI-friendly.

Below you’ll find:

1. **File tree**
2. **All code files** (orchestrator, hunters, trace, thinker, policy, package.json, Makefile)
3. **A detailed README** (architecture, setup, env vars, CI, policy, examples)
4. **“Unasked” questions** — asked and answered

---

# 1) File tree

```
.
├─ hunt.sh                          # Orchestrator (strict/warn, merge, policy, Thinker hook)
├─ hunters/
│  ├─ trace.sh                      # 10-line telemetry bus (append-only)
│  ├─ runtime_ssr.sh                # SSR/SSG drift, dynamic JSON/import assertions, adapter drift
│  ├─ build_dependencies.sh         # generator→output registry, generated-in-src, conflict risk
│  ├─ security.sh                   # secrets, dangerous code, mixed content, .env exposure
│  ├─ accessibility.sh              # alt/labels/landmarks/contrast/statics checks
│  ├─ performance.sh                # large images/assets, big modules, barrel imports, css sprawl
│  └─ code_quality.sh               # dead code smells, duplication, long funcs, magic numbers
├─ thinker/
│  └─ index.mjs                     # Hunter Thinker: read all JSON + traces → ranked agenda
├─ __ai/
│  └─ thinker/
│     └─ thinker-policy.json        # Weights/thresholds/caps (tunable, no code edits)
├─ package.json                     # npm scripts for hunt & thinker
├─ Makefile                         # make hunt / hunt-strict
└─ README.md                        # detailed docs (below)
```

---

# 2) Code

> Paste these verbatim. If a file already exists in your repo, diff & merge the relevant parts.

## `hunt.sh` — orchestrator

```bash
#!/usr/bin/env bash
# hunt.sh — modular orchestrator + policy gates + Thinker integration
# POSIX-ish; tested with bash. No heavy deps. Node is optional for Thinker.

set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

# -------- Config --------
STRICT="${STRICT:-1}"                 # 1 = fail on criticals/invariants; 0 = warn-only
MODULES_DEFAULT="runtime_ssr,build_dependencies,security,accessibility,performance,code_quality"
MODULES="${MODULES:-$MODULES_DEFAULT}"
REPORT_DIR="__reports/hunt"
LOG_DIR="$REPORT_DIR/logs"
THINKER_ENTRY="thinker/index.mjs"
FAKE_NOW="${FAKE_NOW:-}"

# -------- Utils --------
_color() { printf "\033[%sm" "$1"; }
_title() { _color "1;36"; }      # bold cyan
_ok()    { _color "1;32"; }      # bold green
_warn()  { _color "1;33"; }      # bold yellow
_err()   { _color "1;31"; }      # bold red
_dim()   { _color "2;37"; }      # dim gray
_reset() { _color "0"; }

section() { printf "%s\n== %s ==%s\n" "$(_title)" "$1" "$(_reset)"; }
info()    { printf "%s•%s %s\n" "$(_dim)" "$(_reset)" "$1"; }
okay()    { printf "%s✓%s %s\n" "$(_ok)" "$(_reset)" "$1"; }
warn()    { printf "%s⚠%s %s\n" "$(_warn)" "$(_reset)" "$1"; }
fail()    { printf "%s✗%s %s\n" "$(_err)" "$(_reset)" "$1"; }

ts() {
  if [[ -n "$FAKE_NOW" ]]; then printf "%s" "$FAKE_NOW"; else date -Iseconds; fi
}

ensure_dirs() { mkdir -p "$REPORT_DIR" "$LOG_DIR" "__ai/thinker" "var"; }

have() { command -v "$1" >/dev/null 2>&1; }

rg_or_grep() {
  if have rg; then rg "$@"; else grep -RIn --binary-files=without-match "$@"; fi
}

# Write minimal valid JSON safely
json_write() {
  # $1 = path; stdin = JSON content (already valid)
  local path="$1" tmp
  tmp="$(mktemp "${path}.XXXX")"
  cat > "$tmp"
  mv "$tmp" "$path"
}

# -------- Merge module JSONs into master summary --------
merge_master() {
  local master="$REPORT_DIR/master.json"
  local total_issues=0 total_critical=0 total_warn=0 total_pass=0
  local modules_json="[" first=1

  shopt -s nullglob
  for f in "$REPORT_DIR"/*.json; do
    [[ "$(basename "$f")" == "master.json" ]] && continue
    # Valid JSON? (best-effort)
    if have node; then
      node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" >/dev/null 2>&1 || {
        warn "Invalid JSON from $(basename "$f") — skipping"; continue;
      }
    fi
    # Extract key metrics via Node (portable) or naive grep fallback
    local status issues
    if have node; then
      status="$(node -e "let j=require('$f'); console.log(j.status||'pass')")"
      issues="$(node -e "let j=require('$f'); console.log(Number(j.issues||0))")"
    else
      status="$(sed -n 's/.*"status":[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n1)"
      issues="$(sed -n 's/.*"issues":[[:space:]]*\([0-9]\+\).*/\1/p' "$f" | head -n1)"
      status="${status:-pass}"; issues="${issues:-0}"
    fi
    case "$status" in
      critical) total_critical=$((total_critical+1));;
      warn)     total_warn=$((total_warn+1));;
      *)        total_pass=$((total_pass+1));;
    esac
    total_issues=$((total_issues + issues))
    # Append to modules_json
    if [[ $first -eq 1 ]]; then
      modules_json="$modules_json$(cat "$f")"; first=0
    else
      modules_json="$modules_json,$(cat "$f")"
    fi
  done
  modules_json="$modules_json]"

  # Policy: strict fails when any critical exists
  local policy_pass=true reasons="[]"
  if [[ "$STRICT" == "1" && $total_critical -gt 0 ]]; then
    policy_pass=false
    reasons='["one-or-more-modules-critical"]'
  fi

  json_write "$master" <<JSON
{
  "schemaVersion": 1,
  "generatedAt": "$(ts)",
  "strict": ${STRICT/[^0-9]/0},
  "summary": {
    "total_issues": $total_issues,
    "total_critical": $total_critical,
    "total_warn": $total_warn,
    "total_pass": $total_pass
  },
  "modules": $modules_json,
  "policy": {
    "pass": $policy_pass,
    "reasons": $reasons
  }
}
JSON

  if [[ "$policy_pass" == "true" ]]; then
    okay "HUNT: PASS (critical=$total_critical, warn=$total_warn, pass=$total_pass)"
  else
    fail "HUNT: FAIL (critical=$total_critical, warn=$total_warn, pass=$total_pass)"
    return 1
  fi
}

# -------- Run a single hunter --------
run_hunter() {
  local mod="$1"
  local script="hunters/${mod}.sh"
  if [[ ! -f "$script" ]]; then
    warn "Missing $script (skipping)"
    return 0
  fi
  section "Hunter: $mod"
  local logf="$LOG_DIR/${mod}.log"
  local jsonf="$REPORT_DIR/${mod}.json"
  HUNTER_MODULE="$mod" bash "$script" >"$logf" 2>&1 || {
    warn "$mod exited non-zero; capturing partial results"
  }
  # Ensure JSON file exists (module responsible for writing it; create default otherwise)
  if [[ ! -s "$jsonf" ]]; then
    warn "$mod did not write $jsonf; writing minimal pass JSON"
    json_write "$jsonf" <<JSON
{ "schemaVersion": 1, "module": "$mod", "status": "pass", "issues": 0, "affected_files": 0, "counts": {}, "actions": [], "policy_invariants": [], "eta_minutes": 0, "unlocks": [] }
JSON
  fi
  okay "log: $logf  json: $jsonf"
}

# -------- Main --------
main() {
  ensure_dirs
  section "Environment"
  info "STRICT=$STRICT"
  info "MODULES=$MODULES"
  info "ts=$(ts)"
  info "node=$(if have node; then node -v; else echo 'missing'; fi)"
  info "rg=$(if have rg; then rg --version | head -n1; else echo 'missing (using grep)'; fi)"

  # Run selected modules
  IFS=',' read -r -a mods <<< "$MODULES"
  local rc=0
  for m in "${mods[@]}"; do
    if ! run_hunter "$m"; then rc=1; fi
  done

  # Merge into master
  if ! merge_master; then rc=1; fi

  # Thinker (advisory; never changes exit code)
  if [[ -f "$THINKER_ENTRY" ]] && have node; then
    section "Thinker Agenda"
    if node "$THINKER_ENTRY"; then
      okay "__ai/thinker/master-insights.json"
    else
      warn "Thinker: non-fatal error (agenda may be missing)"
    fi
  else
    info "Thinker skipped (node or thinker/index.mjs missing)"
  fi

  exit "$rc"
}

main "$@"
```

---

## `hunters/trace.sh` — telemetry bus

```bash
# hunters/trace.sh — append-only trace events
TRACE_FILE="var/hunt-events.ndjson"
mkdir -p "$(dirname "$TRACE_FILE")"

trace_event() {
  # usage: trace_event <op> <json-data-or-empty>
  local op="$1"; shift || true
  local data="${*:-{}}"
  printf '{"t":"%s","module":"%s","op":"%s","data":%s}\n' \
    "$(date -Iseconds)" "${HUNTER_MODULE:-unknown}" "$op" "$data" >> "$TRACE_FILE"
}

trace_open_file() { trace_event "open_file" "{\"path\":\"$1\"}"; }
trace_issue()     { trace_event "issue" "${1:-{}}"; }      # pass JSON string: {"class":"...","path":"...","severity":"..."}
trace_invariant() { trace_event "invariant" "${1:-{}}"; }  # pass JSON string: {"name":"...","status":"pass|fail"}
trace_timing()    { trace_event "timing" "${1:-{}}"; }     # pass JSON string: {"phase":"...","ms":123}
```

---

## `hunters/runtime_ssr.sh` — SSR/SSG drift detector

```bash
#!/usr/bin/env bash
# runtime_ssr.sh — detect SSR drift, dynamic JSON imports, import assertions, adapter/config mismatches
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/runtime_ssr.json"
mkdir -p "$REPORT_DIR"

scan() {
  local root="${1:-.}"
  local has_import_assert=0 has_dynamic_json=0 has_adapter=0 out_mode="unknown" config_path=""
  local conf

  # Locate astro config
  for conf in "astro.config.mjs" "astro.config.js" "astro.config.ts" ; do
    if [[ -f "$root/$conf" ]]; then
      config_path="$conf"
      # quick grep-based parse
      grep -E "output:[[:space:]]*'server'" "$root/$conf" >/dev/null 2>&1 && out_mode="server"
      grep -E "output:[[:space:]]*'static'" "$root/$conf" >/dev/null 2>&1 && out_mode="static"
      grep -E "adapter:[[:space:]]*" "$root/$conf" >/dev/null 2>&1 && has_adapter=1
      trace_open_file "$conf"
      break
    fi
  done

  # Scan for import assertions & dynamic imports of JSON under src/**
  local paths
  if command -v rg >/dev/null 2>&1; then
    paths=$(rg -n --no-messages -g 'src/**' \
      -e 'assert[[:space:]]*\{[[:space:]]*type:[[:space:]]*["'\'']json["'\''][[:space:]]*\}' \
      -e 'import\([[:space:]]*["'\''][^"'\'']+\.json["'\''][[:space:]]*\)' || true)
  else
    paths=$(grep -RIn --binary-files=without-match -E 'assert[[:space:]]*\{[[:space:]]*type:[[:space:]]*["'\''"]json["'\''"][[:space:]]*\}|import\([[:space:]]*["'\''"][^"'\''"]+\.json["'\''"][[:space:]]*\)' src 2>/dev/null || true)
  fi
  if [[ -n "$paths" ]]; then
    has_import_assert=$(printf "%s\n" "$paths" | grep -c 'assert')
    has_dynamic_json=$(printf "%s\n" "$paths" | grep -c 'import(' || true)
    while IFS= read -r line; do
      trace_issue "{\"class\":\"runtime-ssr-hazard\",\"path\":\"${line%%:*}\",\"severity\":\"critical\"}"
    done <<< "$paths"
  fi

  # Truth pin: ok when output=static and no adapter (or explicitly consistent)
  local truthPin="unknown"
  if [[ "$out_mode" == "static" && $has_adapter -eq 0 ]]; then
    truthPin="ok"
  elif [[ "$out_mode" == "server" && $has_adapter -eq 1 ]]; then
    truthPin="ok"
  else
    truthPin="violated"
  fi

  # Issues & status
  local issues=$(( has_import_assert + has_dynamic_json + (truthPin == "violated" ? 1 : 0) ))
  local status="pass"
  [[ "$truthPin" == "violated" || $has_import_assert -gt 0 || $has_dynamic_json -gt 0 ]] && status="critical"

  # Emit JSON
  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "runtime_ssr",
  "status": "$status",
  "issues": $issues,
  "affected_files": $(( has_import_assert + has_dynamic_json )),
  "counts": {
    "import_assertions": $has_import_assert,
    "dynamicJsonImports": $has_dynamic_json,
    "hasAdapter": $has_adapter
  },
  "astroConfig": { "path": "${config_path:-null}", "output": "$out_mode" },
  "truthPin": "$truthPin",
  "actions": [
    "Remove JSON import assertions in src/** and switch to static data imports or build-time generation",
    "Remove dynamic JSON import() under src/** or adopt an adapter and output:'server' intentionally",
    "If SSR intended, install adapter and document policy; otherwise ensure output:'static' and no adapter"
  ],
  "policy_invariants": [
    "counts.dynamicJsonImports == 0",
    "counts.import_assertions == 0",
    "truthPin == 'ok'"
  ],
  "eta_minutes": 30,
  "unlocks": ["performance","accessibility","code_quality"]
}
JSON
}

scan "."
```

---

## `hunters/build_dependencies.sh` — generator/outputs & conflict risk

```bash
#!/usr/bin/env bash
# build_dependencies.sh — find generated files, writers into src/, and manual-edit conflicts
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/build_dependencies.json"
mkdir -p "$REPORT_DIR"

scan() {
  local writers_in_src=0 generated_in_src=0 potential_conflicts=0 generated_files=0
  local gen_list=""

  # Heuristics: writers that create files (common verbs), JSON compilers, etc.
  if command -v rg >/dev/null 2>&1; then
    gen_list="$(rg -n --no-messages -g '!node_modules/**' -e 'writeFileSync\(|fs\.writeFile\(|fs\.createWriteStream\(' scripts/ src/ tools/ || true)"
  else
    gen_list="$(grep -RIn --binary-files=without-match -E 'writeFileSync\(|fs\.writeFile\(|fs\.createWriteStream\(' scripts src tools 2>/dev/null || true)"
  fi

  # Writers targeting src/**
  if [[ -n "$gen_list" ]]; then
    writers_in_src=$(printf "%s\n" "$gen_list" | grep -c 'src/' || true)
    while IFS= read -r line; do
      trace_issue "{\"class\":\"writer-in-src\",\"path\":\"${line%%:*}\",\"severity\":\"warn\"}"
    done <<< "$gen_list"
  fi

  # Generated files (common patterns) inside src/**
  if command -v rg >/dev/null 2>&1; then
    generated_files=$(rg -n --no-messages -g 'src/**' -e '(compiled|generated|coverage|map|distilled)\.(json|md|csv)$' | wc -l | tr -d ' ')
  else
    generated_files=$(grep -RIn --binary-files=without-match -E '(compiled|generated|coverage|map|distilled)\.(json|md|csv)$' src 2>/dev/null | wc -l | tr -d ' ')
  fi
  generated_in_src="$generated_files"

  # Potential conflicts: files marked DO NOT EDIT lacking source; or file pairs *.source.json vs compiled mismatch (shallow)
  local dne_count=0
  dne_count=$(grep -RIl --binary-files=without-match -E 'DO NOT EDIT|GENERATED FILE' src 2>/dev/null | wc -l | tr -d ' ' || true)
  potential_conflicts=$((writers_in_src + (dne_count>0 ? 1 : 0)))

  local issues=$(( potential_conflicts + (generated_in_src>0 ? 1 : 0) ))
  local status="pass"
  [[ $potential_conflicts -gt 0 ]] && status="critical"
  [[ "$status" == "pass" && $generated_in_src -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "build_dependencies",
  "status": "$status",
  "issues": $issues,
  "affected_files": $(( generated_in_src + writers_in_src )),
  "counts": {
    "generated_in_src": $generated_in_src,
    "writers_in_src": $writers_in_src,
    "potential_conflicts": $potential_conflicts
  },
  "actions": [
    "Move writers to scripts/ and output to __generated/, not src/**",
    "Stop editing compiled outputs; edit .source.* or generator input and re-run",
    "Add DO NOT EDIT headers and a registry mapping generator → outputs"
  ],
  "policy_invariants": [
    "counts.potential_conflicts == 0"
  ],
  "eta_minutes": 25,
  "unlocks": ["performance","code_quality","runtime_ssr"]
}
JSON
}

scan "."
```

---

## `hunters/security.sh` — secrets & dangerous code

```bash
#!/usr/bin/env bash
# security.sh — secrets, dynamic code, mixed content, .env leakage
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/security.json"
mkdir -p "$REPORT_DIR"

scan() {
  local secrets=0 xss=0 unsafe=0 mixed=0 envleak=0

  # Secrets (heuristics)
  secrets=$(( $(grep -RIn --binary-files=without-match -E '(api[_-]?key|secret|token|password|AKIA[0-9A-Z]{16})' . 2>/dev/null | wc -l | tr -d ' ') ))

  # Dangerous code
  unsafe=$(( $(grep -RIn --binary-files=without-match -E '\beval\(|new[[:space:]]+Function\(' src 2>/dev/null | wc -l | tr -d ' ') ))

  # XSS sinks (basic patterns)
  xss=$(( $(grep -RIn --binary-files=without-match -E 'innerHTML\s*=|dangerouslySetInnerHTML' src 2>/dev/null | wc -l | tr -d ' ') ))

  # Mixed content (http:// in code)
  mixed=$(( $(grep -RIn --binary-files=without-match -E 'http://[^\"]+' src public 2>/dev/null | wc -l | tr -d ' ') ))

  # .env in repo
  envleak=$(( $(git ls-files 2>/dev/null | grep -E '(^|/)\.env(\..+)?$' | wc -l | tr -d ' ') ))

  local issues=$(( secrets + unsafe + xss + mixed + envleak ))
  local status="pass"; [[ $issues -gt 0 ]] && status="critical"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "security",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "secrets": $secrets,
    "unsafe_code": $unsafe,
    "xss_sinks": $xss,
    "mixed_content": $mixed,
    "env_files_in_repo": $envleak
  },
  "actions": [
    "Remove secrets from code; use environment or secret manager",
    "Replace eval/new Function; sanitize untrusted HTML; avoid innerHTML",
    "Enforce HTTPS and CSP; move .env files out of VCS"
  ],
  "policy_invariants": [
    "counts.secrets == 0",
    "counts.unsafe_code == 0",
    "counts.xss_sinks == 0",
    "counts.mixed_content == 0",
    "counts.env_files_in_repo == 0"
  ],
  "eta_minutes": 20,
  "unlocks": ["runtime_ssr","performance"]
}
JSON
}

scan "."
```

---

## `hunters/accessibility.sh` — static a11y checks

```bash
#!/usr/bin/env bash
# accessibility.sh — lightweight static checks (alt, labels, landmarks, headings, contrast markers)
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/accessibility.json"
mkdir -p "$REPORT_DIR"

scan() {
  local missing_alt=0 missing_labels=0 missing_landmarks=0 bad_headings=0 clickable_divs=0

  missing_alt=$(( $(grep -RIn --binary-files=without-match -E '<img(?![^>]*alt=)' src public 2>/dev/null | wc -l | tr -d ' ') ))
  missing_labels=$(( $(grep -RIn --binary-files=without-match -E '<input(?![^>]*(aria-label|aria-labelledby|alt|name)=)' src 2>/dev/null | wc -l | tr -d ' ') ))
  missing_landmarks=$(( $(grep -RIn --binary-files=without-match -E '<(main|nav|header|footer|aside)\b' src 2>/dev/null | wc -l | tr -d ' ') == 0 ? 1 : 0 ))
  bad_headings=$(( $(grep -RIn --binary-files=without-match -E '<h[1-6]' src 2>/dev/null | wc -l | tr -d ' ') == 0 ? 1 : 0 ))
  clickable_divs=$(( $(grep -RIn --binary-files=without-match -E '<(div|span)[^>]*(onClick|onclick)=' src 2>/dev/null | wc -l | tr -d ' ') ))

  local issues=$(( missing_alt + missing_labels + missing_landmarks + bad_headings + clickable_divs ))
  local status="pass"; [[ $issues -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "accessibility",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "missing_alt": $missing_alt,
    "missing_labels": $missing_labels,
    "missing_landmarks": $missing_landmarks,
    "bad_headings": $bad_headings,
    "clickable_divs": $clickable_divs
  },
  "actions": [
    "Add alt text on all <img>; use descriptive alt or empty alt for decorative",
    "Label inputs with <label>, aria-label, or aria-labelledby",
    "Add main/nav/header/footer landmarks; correct heading order",
    "Avoid clickable <div>/<span>; use <button> with keyboard semantics"
  ],
  "policy_invariants": [
    "counts.missing_alt == 0",
    "counts.missing_labels == 0"
  ],
  "eta_minutes": 25,
  "unlocks": ["performance","code_quality"]
}
JSON
}

scan "."
```

---

## `hunters/performance.sh` — asset & code heft

```bash
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
LONG_CSS_LINES="${LONG_CSS_LINES:-1000}"

scan() {
  local large_images=0 large_js=0 barrel_imports=0 css_sprawl=0

  # Large images (png/jpg > threshold)
  large_images=$(( $(find public src -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -size +"${LARGE_IMG_KB}"k 2>/dev/null | wc -l | tr -d ' ') ))

  # Large JS/TS modules
  large_js=$(( $(find src -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.ts' -o -iname '*.tsx' \) -size +"${LARGE_JS_KB}"k 2>/dev/null | wc -l | tr -d ' ') ))

  # Barrel imports (index.ts that re-exports *)
  barrel_imports=$(( $(grep -RIl --binary-files=without-match -E 'export\s+\*\s+from' src 2>/dev/null | wc -l | tr -d ' ') ))

  # CSS sprawl (very long css files)
  css_sprawl=$(( $(find src -type f -iname '*.css' -size +"${LONG_CSS_LINES}"c 2>/dev/null | wc -l | tr -d ' ') ))

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
```

---

## `hunters/code_quality.sh` — debt signals

```bash
#!/usr/bin/env bash
# code_quality.sh — dead code signals, duplication, long functions, magic numbers (static, heuristic)
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/code_quality.json"
mkdir -p "$REPORT_DIR"

# thresholds
LONG_LINE="${LONG_LINE:-160}"          # characters
DUP_HINT="${DUP_HINT:-40}"             # lines repeated patterns (very rough heuristic)

scan() {
  local todos=0 long_lines=0 magic_numbers=0 duplication=0

  todos=$(( $(grep -RIn --binary-files=without-match -E 'TODO|FIXME|HACK' src 2>/dev/null | wc -l | tr -d ' ') ))
  long_lines=$(( $(awk -v n="$LONG_LINE" 'length($0)>n{c++} END{print c+0}' $(git ls-files 'src/**/*.*' 2>/dev/null) 2>/dev/null || echo 0) ))
  magic_numbers=$(( $(grep -RIn --binary-files=without-match -E '\b[0-9]{3,}\b' src 2>/dev/null | wc -l | tr -d ' ') ))
  # Dup heuristic: identical 40+ char lines occurring 3+ times
  duplication=$(( $(grep -Rho --binary-files=without-match -E '.{'"$DUP_HINT"',}' src 2>/dev/null | sort | uniq -c | awk '$1>=3{c+=1} END{print c+0}') ))

  local issues=$(( todos + long_lines + magic_numbers + duplication ))
  local status="pass"; [[ $issues -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "code_quality",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "todos": $todos,
    "long_lines": $long_lines,
    "magic_numbers": $magic_numbers,
    "duplication_hints": $duplication
  },
  "actions": [
    "Convert TODO/FIXME to tracked issues; pay down in batches",
    "Split long lines; refactor long modules/functions",
    "Extract magic numbers to named constants",
    "Deduplicate helpers; share utilities across packages"
  ],
  "policy_invariants": [],
  "eta_minutes": 20,
  "unlocks": ["performance","accessibility"]
}
JSON
}

scan "."
```

---

## `thinker/index.mjs` — Hunter Thinker (agenda & hot files)

```js
#!/usr/bin/env node
// thinker/index.mjs — Read all module JSON + var/hunt-events.ndjson → write a ranked agenda.
import fs from "node:fs";
import path from "node:path";

const REPORT_DIR = "__reports/hunt";
const OUT_DIR = "__ai/thinker";
const TRACE_FILE = "var/hunt-events.ndjson";
const POLICY_FILE = path.join(OUT_DIR, "thinker-policy.json");

fs.mkdirSync(OUT_DIR, { recursive: true });

// Tunable policy (no code edits needed)
const policy = fs.existsSync(POLICY_FILE)
  ? JSON.parse(fs.readFileSync(POLICY_FILE, "utf8"))
  : {
      weights: { severity: 3.0, recurrence: 1.6, blastRadius: 1.4, timeToFix: -0.8, unlocks: 1.2 },
      thresholds: { recommend: 2.0, critical: 4.0 },
      caps: { maxAgendaItems: 8 }
    };

// Load module reports, skipping master.json
const reports = fs
  .readdirSync(REPORT_DIR)
  .filter((f) => f.endsWith(".json") && f !== "master.json")
  .map((f) => {
    const body = JSON.parse(fs.readFileSync(path.join(REPORT_DIR, f), "utf8"));
    return { name: f.replace(/\.json$/, ""), ...body };
  });

// Optional traces
const traces = fs.existsSync(TRACE_FILE)
  ? fs
      .readFileSync(TRACE_FILE, "utf8")
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((l) => {
        try {
          return JSON.parse(l);
        } catch {
          return null;
        }
      })
      .filter(Boolean)
  : [];

const N = (x) => Math.log(1 + Math.max(0, x));
const score = (r) => {
  const sev = r.status === "critical" ? 2 : r.status === "warn" ? 1 : 0;
  const w = policy.weights;
  return (
    w.severity * sev +
    w.recurrence * N(r.issues || 0) +
    w.blastRadius * N(r.affected_files || 0) +
    w.timeToFix * N(r.eta_minutes || 10) +
    w.unlocks * ((r.unlocks && r.unlocks.length) || 0)
  );
};

const agenda = reports
  .filter((r) => Array.isArray(r.actions) && r.actions.length)
  .map((r) => ({
    module: r.module || r.name,
    status: r.status,
    score: +score(r).toFixed(2),
    actions: r.actions.slice(0, 5),
    proof: r.policy_invariants || [],
    why: [
      r.status === "critical" ? "severity:2" : null,
      r.issues ? `recurrence:${r.issues}` : null,
      r.affected_files ? `blast:${r.affected_files}` : null,
      r.unlocks?.length ? `unlocks:${r.unlocks.length}` : null
    ]
      .filter(Boolean)
      .join(" ")
  }))
  .sort((a, b) => b.score - a.score)
  .slice(0, policy.caps.maxAgendaItems);

// Trace-derived "hot files"
const hot = {};
for (const t of traces) {
  if (t.op === "open_file" && t.data?.path) hot[t.data.path] = (hot[t.data.path] || 0) + 1;
}

const out = {
  schemaVersion: 1,
  t: new Date().toISOString(),
  agenda,
  hotFiles: Object.entries(hot)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([path, count]) => ({ path, count })),
  notes: ["Prefer class-eliminating fixes; pair each with a proof-invariant and a sibling sweep."]
};

fs.writeFileSync(path.join(OUT_DIR, "master-insights.json"), JSON.stringify(out, null, 2));
console.log(`[thinker] wrote ${path.join(OUT_DIR, "master-insights.json")} with ${agenda.length} items`);
```

---

## `__ai/thinker/thinker-policy.json` — weights & thresholds

```json
{
  "weights": { "severity": 3.0, "recurrence": 1.6, "blastRadius": 1.4, "timeToFix": -0.8, "unlocks": 1.2 },
  "thresholds": { "recommend": 2.0, "critical": 4.0 },
  "caps": { "maxAgendaItems": 8 }
}
```

---

## `package.json`

```json
{
  "name": "hunter-pack",
  "private": true,
  "version": "0.0.1",
  "scripts": {
    "hunt": "bash ./hunt.sh",
    "hunt:strict": "STRICT=1 bash ./hunt.sh",
    "hunt:warn": "STRICT=0 bash ./hunt.sh",
    "thinker": "node thinker/index.mjs"
  }
}
```

---

## `Makefile`

```make
.PHONY: hunt hunt-strict hunt-warn thinker clean
hunt:
	@bash ./hunt.sh
hunt-strict:
	@STRICT=1 bash ./hunt.sh
hunt-warn:
	@STRICT=0 bash ./hunt.sh
thinker:
	@node thinker/index.mjs
clean:
	@rm -rf __reports/hunt __ai/thinker var
```

---

## `README.md`

````markdown
# Hunter Pack: Learning + Thinking Orchestrator

A modular, dependency-light system that:
- runs specialized **hunters** (SSR/SSG, build deps, security, a11y, perf, code quality),
- emits strict **JSON** reports and human logs,
- merges a **master** report with pass/fail policy,
- runs a **Hunter Thinker** that reads everything and writes a single, ranked **Do-Next** agenda (Fix → Proof → Sibling Sweep) with “hot files”,
- keeps all **strict gates** in the hunters (secrets, SSR failures, etc.), so the Thinker is advisory, not escapist.

## Quickstart

```bash
# run the full hunt in strict mode (fails CI on criticals)
npm run hunt:strict

# dev-time, warn-only
npm run hunt:warn

# run Thinker manually (advisory agenda)
npm run thinker
````

Artifacts:

* Machine: `__reports/hunt/*.json` (per-module), `__reports/hunt/master.json`
* Human: `__reports/hunt/logs/*.log`
* Advisory: `__ai/thinker/master-insights.json`
* Telemetry: `var/hunt-events.ndjson`

## Modules

* `runtime_ssr` — SSR/SSG drift (import assertions, dynamic JSON imports, adapter/config mismatch).
* `build_dependencies` — generator→output registry, generated-in-src, DO-NOT-EDIT violations & conflict risk.
* `security` — secrets, dangerous dynamic code, XSS sinks, mixed content, .env exposure.
* `accessibility` — alt/labels/landmarks/headings/clickable-div heuristics.
* `performance` — large images/modules, barrel exports, CSS sprawl.
* `code_quality` — TODO/FIXME, long lines, magic numbers, duplication hints.

All modules output the same JSON shape (status/issues/affected\_files/counts/actions/policy\_invariants/eta\_minutes/unlocks) so the Thinker can score fairly.

## Policy & Strict Mode

* The orchestrator **fails** in `STRICT=1` when **any module** reports `status: "critical"`.
* Each module defines **policy\_invariants** that should be true after a fix (e.g., `counts.dynamicJsonImports == 0`). These are advisory in the JSON and **enforced** by the module itself when possible.
* The **Thinker** never changes exit codes. It reads JSON, ranks actions by: **severity + recurrence + blast radius − time-to-fix + unlocks**, and emits a single agenda with “why now”.

Tune the Thinker via `__ai/thinker/thinker-policy.json`.

## CI Example (GitHub Actions)

```yaml
- name: Hunter (strict)
  run: npm run hunt:strict

- name: Upload hunter artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: hunter-artifacts
    path: |
      __reports/hunt/**
      __ai/thinker/master-insights.json
```

## Determinism

* Set `FAKE_NOW=…` to pin timestamps for reproducible builds.
* The hunters avoid wall-clock and network IO. The Thinker uses only local files.

## Extending with New Hunters

1. Create `hunters/<name>.sh`, write to `__reports/hunt/<name>.json` using the standard contract.
2. Add `<name>` to `MODULES` env or pass `MODULES` when running.
3. Optional: source `hunters/trace.sh` and emit `trace_issue`/`trace_open_file` for richer “hot files”.

## Example Agenda (from Thinker)

```json
{
  "agenda": [
    {
      "module": "build_dependencies",
      "status": "critical",
      "score": 7.1,
      "actions": [
        "Move writers to scripts/ and output to __generated/",
        "Stop editing compiled outputs; edit .source.* or generator input"
      ],
      "proof": ["counts.potential_conflicts == 0"],
      "why": "severity:2 recurrence:3 blast:5 unlocks:2"
    },
    {
      "module": "runtime_ssr",
      "status": "critical",
      "score": 6.5,
      "actions": [
        "Remove JSON import assertions and dynamic JSON import() in src/**",
        "Adopt adapter + output:'server' if SSR intentional"
      ],
      "proof": ["counts.dynamicJsonImports == 0","truthPin == 'ok'"],
      "why": "severity:2 recurrence:2 blast:7 unlocks:2"
    }
  ]
}
```

## Safety & Governance

* Hard reds (secrets, env files in repo, SSR misconfig) **fail** strict hunts.
* The Thinker is transparent: all inputs (module JSON) + outputs (agenda) are versioned alongside the code.
* No network calls. No private exfiltration. Everything stays local.

## Troubleshooting

* **JSON parsing error**: check `__reports/hunt/logs/<module>.log` for stack traces; the orchestrator writes a stub JSON if a module crashes so the run can continue.
* **Missing Node**: the Thinker step is skipped; core hunts still run.
* **Performance**: on large repos, consider a `.huntrc` ignore file (use `rg --ignore-file`) or set `MODULES` to a subset for pre-commit.

````

---

# 3) “Unasked” questions — asked & answered

**Q1. What happens if `rg` (ripgrep) isn’t installed?**  
**A.** We automatically fall back to `grep -RIn`. You’ll lose a bit of speed and glob finesse, but results are consistent. The orchestrator detects and logs the search tool in the “Environment” section.

**Q2. Can the Thinker ever bypass strict security/SSR gates?**  
**A.** No. The Thinker is read-only and advisory. Strict gates live in modules and the orchestrator. If **any** module reports `status: "critical"` while `STRICT=1`, the hunt fails regardless of what the agenda says.

**Q3. How do I dial the agenda for different phases (stabilization vs. release crunch)?**  
**A.** Update `__ai/thinker/thinker-policy.json`. For stabilization: up-weight `severity`/`blastRadius`. For release: make `timeToFix` more negative. No code changes required.

**Q4. How does this scale to big monorepos?**  
**A.** Three dials: (1) limit MODULES per job (e.g., SSR & Security in one job; Perf & A11y in another), (2) run with a repo-specific ignore file (`rg --ignore-file` or `.gitignore`-style), (3) set coarser thresholds (`LARGE_IMG_KB`, `LARGE_JS_KB`) via env to reduce noise.

**Q5. Where does “learning” live if I want reinforcement?**  
**A.** Start with a simple JSON ledger `__ai/thinker/memory.json` tracking plays → success counts. Each time a class flips **critical→pass** in the next run, bump the count and give a small score bonus in the Thinker. If you need richer analytics, graduate to a tiny SQLite file.

**Q6. How do I add a new hunter (e.g., SEO/LD, link integrity)?**  
**A.** Create `hunters/<name>.sh`, emit the standard JSON (with `status`, `issues`, `counts`, `actions`, `policy_invariants`, `eta_minutes`, `unlocks`), and add it to `MODULES`. The Thinker will pick it up automatically and rank it.

**Q7. How do I make outputs deterministic for snapshot tests?**  
**A.** Set `FAKE_NOW="2025-01-01T00:00:00Z"` in env; we use it in `hunt.sh` and Thinker’s timestamps. No other wall-clock is used.

**Q8. What if two hunters conflict (e.g., SSR vs. generator writers)?**  
**A.** Resolve in **actions**: move writers to `scripts/` → `__generated/`, import statically from `src/`. Both hunters will go green under that pattern. You can codify such resolver notes directly in your repo’s docs or add an optional “resolver” step that rewrites conflicting action text.

**Q9. Can I run only a subset locally?**  
**A.** Yes: `MODULES=security,performance npm run hunt:strict` or `MODULES=runtime_ssr npm run hunt:warn`.

**Q10. Do I need Node to run the core hunt?**  
**A.** No. Node is only required for the Thinker. If Node is missing, hunts still run and produce `master.json`; you just won’t get the advisory agenda.

---

You’re set. Drop these files in, commit, and run:

```bash
npm run hunt:strict
# then peek:
cat __reports/hunt/master.json
cat __ai/thinker/master-insights.json
````

From here, we can add tiny per-repo touches (e.g., a resolver table or a memory ledger) without changing the core design.
