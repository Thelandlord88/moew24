#!/usr/bin/env bash
# css_architecture.sh — CSS baseline & architecture hunter
# Ensures single global bundle + controlled growth vs baseline.
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/css_architecture.json"

if [[ -f hunters/_common.sh ]]; then source hunters/_common.sh || true; fi

SOFT_GROWTH_PCT=${CSS_SOFT_GROWTH_PCT:-5}
HARD_GROWTH_PCT=${CSS_HARD_GROWTH_PCT:-15}

if declare -f init_report >/dev/null 2>&1; then init_report css_architecture >/dev/null; else
  cat > "$REPORT_FILE" <<EOF
{ "module":"css_architecture","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"running","critical_issues":0,"warning_issues":0,"issues_total":0,"findings":{},"recommendations":[],"upstream_analysis":{"box":"","closet":"","policy":""} }
EOF
fi

critical=0; warn=0
log(){ echo "[css-arch] $*"; }

log "Assert one global bundle"
ONE_OUT=$(npm run css:assert:one-global 2>&1 || true)
if echo "$ONE_OUT" | grep -qi "FAIL\|error"; then critical=$((critical+1)); fi
update_report_kv "$REPORT_FILE" '.findings.one_global_output=$o' --arg o "$ONE_OUT"

log "Baseline check"
BASE_OUT=$(npm run css:baseline:check 2>&1 || true)
update_report_kv "$REPORT_FILE" '.findings.baseline_check_output=$o' --arg o "$BASE_OUT"

BASELINE_FILE="__reports/css-baseline.json"
CURRENT_SIZE=0; BASE_SIZE=0; GROWTH_PCT=0
if [[ -f $BASELINE_FILE ]]; then
  CURRENT_SIZE=$(jq '..|objects|select(has("current"))|.current.total_size_bytes? // empty' "$BASELINE_FILE" 2>/dev/null | tail -1 || echo 0)
  BASE_SIZE=$(jq '..|objects|select(has("baseline"))|.baseline.total_size_bytes? // empty' "$BASELINE_FILE" 2>/dev/null | tail -1 || echo 0)
  if [[ -n "$CURRENT_SIZE" && -n "$BASE_SIZE" && $BASE_SIZE -gt 0 ]]; then
    GROWTH_PCT=$(( ( (CURRENT_SIZE-BASE_SIZE) * 100 ) / BASE_SIZE ))
  fi
fi
SAFE_CURRENT=${CURRENT_SIZE:-0}
SAFE_BASE=${BASE_SIZE:-0}
SAFE_GROWTH=${GROWTH_PCT:-0}
update_report_kv "$REPORT_FILE" ".findings.current_size_bytes=$SAFE_CURRENT | .findings.baseline_size_bytes=$SAFE_BASE | .findings.growth_pct=$SAFE_GROWTH | .findings.soft_growth_pct=$SOFT_GROWTH_PCT | .findings.hard_growth_pct=$HARD_GROWTH_PCT"

if (( GROWTH_PCT > HARD_GROWTH_PCT )); then critical=$((critical+1)); elif (( GROWTH_PCT > SOFT_GROWTH_PCT )); then warn=$((warn+1)); fi

EXIT_CODE=0
if declare -f finalize_report_status >/dev/null 2>&1; then EXIT_CODE=$(finalize_report_status "$REPORT_FILE" $critical $warn); else
  status=pass; [[ $critical -gt 0 ]] && { status=critical; EXIT_CODE=2; } || ([[ $warn -gt 0 ]] && { status=warn; EXIT_CODE=1; })
  jq --arg s "$status" '.status=$s | .critical_issues=$crit | .warning_issues=$warn | .issues_total=($crit+$warn)' --argjson crit $critical --argjson warn $warn "$REPORT_FILE" > "$REPORT_FILE.tmp" && mv "$REPORT_FILE.tmp" "$REPORT_FILE"
fi

BOX="CSS growth / bundle sprawl"; CLOSET="Missing enforced single bundle + regression guard"; POLICY="One global bundle + growth thresholds (${SOFT_GROWTH_PCT}%/${HARD_GROWTH_PCT}%)";
update_report_kv "$REPORT_FILE" '.upstream_analysis.box=$b | .upstream_analysis.closet=$c | .upstream_analysis.policy=$p' --arg b "$BOX" --arg c "$CLOSET" --arg p "$POLICY"

RECS=("Maintain single global bundle")
(( GROWTH_PCT > SOFT_GROWTH_PCT )) && RECS+=("Refactor heavy selectors/utilities causing +${GROWTH_PCT}% growth")
(( GROWTH_PCT > HARD_GROWTH_PCT )) && RECS+=("Investigate abnormal CSS size spike > hard threshold")
(( critical > 0 )) && RECS+=("Resolve multiple global bundle or baseline violation")
RECS_JSON=$(printf '%s\n' "${RECS[@]}" | jq -R . | jq -s .)
update_report_kv "$REPORT_FILE" '.recommendations=$r' --argjson r "$RECS_JSON"

echo "css_architecture: $(jq -r .status "$REPORT_FILE") (growth=${GROWTH_PCT}% size=${CURRENT_SIZE}B base=${BASE_SIZE}B)"
exit $EXIT_CODE
