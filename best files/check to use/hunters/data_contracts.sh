#!/usr/bin/env bash
# hunters/data_contracts.sh — Validate minimal schemas in src/data & src/content (keys only; fast, zero deps)
set -euo pipefail
HUNTER_MODULE="data_contracts"; source "hunters/trace.sh" || true
OUT="__reports/hunt/data_contracts.json"; mkdir -p "$(dirname "$OUT")"

miss=0; files=0; actions=()
check_req() { local file="$1"; shift; files=$((files+1))
  trace_open_file "$file" || true
  for key in "$@"; do
    if ! rg -q "\"$key\"\\s*:" "$file"; then
      miss=$((miss+1)); actions+=("Add key '$key' to $file"); trace_issue "missing_key:$key" "$file" "critical" || true
    fi
  done
}

while IFS= read -r f; do check_req "$f" "serviceId" "slug"; done < <(rg -l --glob "src/data/**/*.json" . || true)
while IFS= read -r f; do check_req "$f" "title" "updated"; done < <(rg -l --glob "src/content/**/*.json" . || true)

status=$([[ $miss -eq 0 ]] && echo pass || echo critical)
jq -n --arg status "$status" --argjson miss ${miss:-0} --argjson files ${files:-0} \
  --argjson actions "$(printf '%s\n' "${actions[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" '
{
  module:"data_contracts", status:$status, issues: $miss,
  counts: { schemasFailed: $miss }, affected_files: $files,
  actions: $actions, policy_invariants:["counts.schemasFailed==0"], eta_minutes: 20,
  unlocks:["runtime_ssr","build_dependencies"]
}' > "$OUT"
