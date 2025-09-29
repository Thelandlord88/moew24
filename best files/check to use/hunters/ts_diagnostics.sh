#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
RAW_JSON="$REPORT_DIR/typescript.diagnostics.raw.json"
OUT="$REPORT_DIR/ts_diagnostics.json"
node scripts/ts-type-health-plan.mjs --hunter || true
if [[ ! -f $RAW_JSON ]]; then
  cat > "$OUT" <<EOF
{ "timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","module":"ts_diagnostics","status":"critical","critical_issues":1,"warning_issues":0,"issues_total":1,"findings":{"error":"missing diagnostics report"},"recommendations":["Ensure ts-type-health-plan executed"],"upstream_analysis":{"box":"No diagnostics","closet":"Script failure","policy":"Generate & gate on TS diagnostics"},"policy_invariants":["issues_total>=0"] }
EOF
  echo "ts_diagnostics: critical (missing)"; exit 2; fi
errors=$(jq '.summary.errors' "$RAW_JSON")
warnings=$(jq '.summary.warnings' "$RAW_JSON")
plan=$(jq '.remediation_plan[0:10]' "$RAW_JSON")
status=pass; exit_code=0; crit=0; warn=0
if (( errors>0 )); then status=critical; exit_code=2; crit=$errors; fi
if (( errors==0 && warnings>0 )); then status=warn; exit_code=1; warn=$warnings; fi
cat > "$OUT" <<EOF
{ "timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","module":"ts_diagnostics","status":"$status","critical_issues":$crit,"warning_issues":$warn,"issues_total":$((crit+warn)),"findings":{"errors":$errors,"warnings":$warnings,"top_files":$plan},"recommendations":["Resolve TypeScript errors first","Then address warnings"],"upstream_analysis":{"box":"TS compile errors","closet":"Mismatched or missing types","policy":"Diagnostics hunter gating"},"policy_invariants":["findings.errors==0"] }
EOF
echo "ts_diagnostics: $status (errors=$errors warnings=$warnings)"; exit $exit_code
