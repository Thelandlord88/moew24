#!/usr/bin/env bash
# hunters/geo_fitness.sh — Enforce static geo imports (Sept 17 pattern) and ban dynamic JSON imports / import assertions
set -euo pipefail
HUNTER_MODULE="geo_fitness"; source "hunters/trace.sh" || true
OUT="__reports/hunt/geo_fitness.json"; mkdir -p "$(dirname "$OUT")"

rg -n "import\\s+.+\\s+from\\s+['\"][^'\"]+\\.json['\"][^\\n]*assert\\s*\\{\\s*type\\s*:\\s*['\"]json['\"]\\s*\\}" src || true > .tmp.geo_asserts || true
rg -n "await\\s+import\\([^)]*\\.json[^)]*\\)" src || true > .tmp.geo_dynamic || true

BAD_ASSERTS=$(wc -l < .tmp.geo_asserts || echo 0)
BAD_DYNAMIC=$(wc -l < .tmp.geo_dynamic || echo 0)
STATUS="pass"; [[ $BAD_ASSERTS -gt 0 || $BAD_DYNAMIC -gt 0 ]] && STATUS="critical"

ACTIONS=()
[[ $BAD_ASSERTS -gt 0 ]] && ACTIONS+=("Replace JSON import assertions with static imports (gold pattern: src/utils/geoCompat.ts with ~/lib/* aliases).")
[[ $BAD_DYNAMIC -gt 0 ]] && ACTIONS+=("Remove dynamic JSON imports; move data shaping to build step and consume static outputs.")

jq -n \
  --arg status "$STATUS" \
  --argjson asserts ${BAD_ASSERTS:-0} \
  --argjson dynamic ${BAD_DYNAMIC:-0} \
  --argjson actions "$(printf '%s\n' "${ACTIONS[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" '
{
  module:"geo_fitness", status:$status,
  issues: ($asserts + $dynamic),
  counts: { importAssertions: $asserts, dynamicJsonImports: $dynamic },
  affected_files: ($asserts + $dynamic),
  actions: $actions,
  policy_invariants: ["counts.importAssertions==0","counts.dynamicJsonImports==0"],
  eta_minutes: 30,
  unlocks: ["runtime_ssr","performance"]
}' > "$OUT"
