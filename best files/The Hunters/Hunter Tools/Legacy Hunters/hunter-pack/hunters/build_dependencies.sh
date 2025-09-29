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

  # Heuristics: writers that create files (common verbs), JSON compilers, etc.
  local gen_list=""
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

  # Potential conflicts: files marked DO NOT EDIT; or presence of writers-in-src
  local dne_count=0 dne_flag=0 gen_flag=0
  dne_count=$(grep -RIl --binary-files=without-match -E 'DO NOT EDIT|GENERATED FILE' src 2>/dev/null | wc -l | tr -d ' ' || true)
  [[ $dne_count -gt 0 ]] && dne_flag=1
  [[ $writers_in_src -gt 0 ]] && gen_flag=1

  potential_conflicts=$((dne_flag + gen_flag))

  local gen_in_src_flag=0
  [[ $generated_in_src -gt 0 ]] && gen_in_src_flag=1

  local issues=$(( potential_conflicts + gen_in_src_flag ))
  local status="pass"
  if [[ $potential_conflicts -gt 0 ]]; then
    status="critical"
  elif [[ $generated_in_src -gt 0 ]]; then
    status="warn"
  fi

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
