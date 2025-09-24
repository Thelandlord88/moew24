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
    has_import_assert=$(printf "%s\n" "$paths" | grep -c 'assert' || true)
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

  # Issues & status (bash-safe arithmetic; no ternary)
  local mismatch=0
  [[ "$truthPin" != "ok" ]] && mismatch=1
  local issues=$(( has_import_assert + has_dynamic_json + mismatch ))
  local status="pass"
  if [[ "$truthPin" != "ok" || $has_import_assert -gt 0 || $has_dynamic_json -gt 0 ]]; then
    status="critical"
  fi

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
