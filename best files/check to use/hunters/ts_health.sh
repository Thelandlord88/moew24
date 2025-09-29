#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/ts_health.json"
TS_ANY="$REPORT_DIR/type_safety.json"
TS_DIAG="$REPORT_DIR/ts_diagnostics.json"
if [[ ! -f $TS_ANY || ! -f $TS_DIAG ]]; then
  cat > "$OUT" <<EOF
{ "module":"ts_health","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"critical","critical_issues":1,"warning_issues":0,"issues_total":1,"findings":{"error":"missing component reports"},"policy_invariants":["issues_total>=0"] }
EOF
  echo "ts_health: critical"; exit 2; fi
anyCount=$(jq '.type_safety_metrics.total_any_count' "$TS_ANY")
errors=$(jq '.findings.errors // .findings.error // 0' "$TS_DIAG")
warnings=$(jq '.findings.warnings // 0' "$TS_DIAG")
status=pass; crit=0; warn=0
if (( errors>0 )); then status=critical; crit=1; fi
if (( errors==0 && (anyCount>20 || warnings>0) )); then status=warn; warn=1; fi
cat > "$OUT" <<EOF
{ "module":"ts_health","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$status","critical_issues":$crit,"warning_issues":$warn,"issues_total":$((crit+warn)),"findings":{"any_count":$anyCount,"errors":$errors,"warnings":$warnings},"recommendations":["Reduce TypeScript errors to zero","Drive any_count below threshold"],"upstream_analysis":{"box":"Type safety degradation","closet":"Fragmented TS hygiene & correctness","policy":"Composite TS health gating"},"policy_invariants":["findings.errors==0"] }
EOF
echo "ts_health: $status"; [[ "$status" == critical ]] && exit 2 || { [[ "$status" == warn ]] && exit 1 || exit 0; }
