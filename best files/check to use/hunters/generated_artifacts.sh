#!/usr/bin/env bash
# generated_artifacts.sh — Hunter wrapper around guardrails-pack generated file integrity
# Goal: Treat stale or hand-edited generated artifacts as a CLASS issue (content drift / source divergence)
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/generated_artifacts.json"

if [[ -f hunters/_common.sh ]]; then source hunters/_common.sh || true; fi
if declare -f init_report >/dev/null 2>&1; then init_report generated_artifacts >/dev/null; else
  cat > "$REPORT_FILE" <<EOF
{ "module":"generated_artifacts","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"running","critical_issues":0,"warning_issues":0,"issues_total":0,"findings":{},"recommendations":[],"upstream_analysis":{"box":"","closet":"","policy":""} }
EOF
fi

critical=0; warn=0

MAP_FILE="guardrails/generated.map.json"
[[ -f $MAP_FILE ]] || MAP_FILE="scripts/generated.map.json"
if [[ ! -f $MAP_FILE ]]; then
  warn=$((warn+1))
  update_report_kv "$REPORT_FILE" '.findings.map_present=false'
  update_report_kv "$REPORT_FILE" '.recommendations += ["Add generated.map.json to enable artifact guardrails"]'
else
  update_report_kv "$REPORT_FILE" '.findings.map_present=true'
  # Extract outputs for quick existence + freshness check
  OUTPUTS=$(jq -r '.rules[].output' "$MAP_FILE" 2>/dev/null || echo "")
  missing=()
  for o in $OUTPUTS; do
    if [[ ! -f $o ]]; then missing+=("$o"); fi
  done
  if (( ${#missing[@]} > 0 )); then
    warn=$((warn+1))
    miss_json=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .)
    update_report_kv "$REPORT_FILE" '.findings.missing_outputs=$m' --argjson m "$miss_json"
    update_report_kv "$REPORT_FILE" '.recommendations += ["Run generators: npm run gen:all"]'
  fi
  # Freshness check: run check script in --skip-gen mode to catch staged vs source mismatch (non-destructive)
  CHECK_SCRIPT="guardrails/check-generated.mjs"
  [[ -f scripts/check-generated.mjs ]] && CHECK_SCRIPT="scripts/check-generated.mjs"
  if [[ -f $CHECK_SCRIPT ]]; then
    if ! node "$CHECK_SCRIPT" --map="$MAP_FILE" --skip-gen >/dev/null 2>&1; then
      critical=$((critical+1))
      update_report_kv "$REPORT_FILE" '.findings.staging_violation=true'
      update_report_kv "$REPORT_FILE" '.recommendations += ["Commit generated outputs only with their sources"]'
    else
      update_report_kv "$REPORT_FILE" '.findings.staging_violation=false'
    fi
    # Now run full freshness regen (safe—scripts themselves decide write behavior)
    if ! node "$CHECK_SCRIPT" --map="$MAP_FILE" >/dev/null 2>&1; then
      critical=$((critical+1))
      update_report_kv "$REPORT_FILE" '.findings.freshness_violation=true'
      update_report_kv "$REPORT_FILE" '.recommendations += ["Run npm run gen:all and commit regenerated outputs"]'
    else
      update_report_kv "$REPORT_FILE" '.findings.freshness_violation=false'
    fi
  else
    warn=$((warn+1))
    update_report_kv "$REPORT_FILE" '.findings.check_script_missing=true'
    update_report_kv "$REPORT_FILE" '.recommendations += ["Install guardrails-pack check-generated.mjs script"]'
  fi
fi

BOX="Generated artifact drift"; CLOSET="No enforced source→output regeneration policy"; POLICY="Map-driven guardrail (map, run, verify) enforced in CI";
update_report_kv "$REPORT_FILE" '.upstream_analysis.box=$b | .upstream_analysis.closet=$c | .upstream_analysis.policy=$p' --arg b "$BOX" --arg c "$CLOSET" --arg p "$POLICY"

EXIT_CODE=0
if declare -f finalize_report_status >/dev/null 2>&1; then EXIT_CODE=$(finalize_report_status "$REPORT_FILE" $critical $warn); else
  status=pass; [[ $critical -gt 0 ]] && { status=critical; EXIT_CODE=2; } || ([[ $warn -gt 0 ]] && { status=warn; EXIT_CODE=1; })
  jq --arg s "$status" '.status=$s | .critical_issues=$crit | .warning_issues=$warn | .issues_total=($crit+$warn)' --argjson crit $critical --argjson warn $warn "$REPORT_FILE" > "$REPORT_FILE.tmp" && mv "$REPORT_FILE.tmp" "$REPORT_FILE"
fi

echo "generated_artifacts: $(jq -r .status "$REPORT_FILE")"
exit $EXIT_CODE
