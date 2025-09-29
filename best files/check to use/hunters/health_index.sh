#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/health_index.json"
if [[ -f hunters/_common.sh ]]; then source hunters/_common.sh || true; fi
SCORE=100; CRIT=0; WARN=0; PASS=0; TOTAL=0
for f in "$REPORT_DIR"/*.json; do
  b=$(basename "$f"); [[ $b == "health_index.json" || $b == "master.json" ]] && continue
  status=$(jq -r '.status // empty' "$f" 2>/dev/null || echo "")
  [[ -z "$status" ]] && continue
  ((TOTAL++))
  case "$status" in
    critical) ((CRIT++)); SCORE=$((SCORE-15));;
    warn) ((WARN++)); SCORE=$((SCORE-5));;
    pass|info) ((PASS++));;
  esac
done
(( SCORE<0 )) && SCORE=0
cat > "$OUT" <<EOF
{ "module":"health_index","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$( ((CRIT>0)) && echo critical || ((WARN>0)) && echo warn || echo pass )","critical_issues":$CRIT,"warning_issues":$WARN,"issues_total":$((CRIT+WARN)),"findings":{"score":$SCORE,"critical":$CRIT,"warnings":$WARN,"passed":$PASS,"total_reports":$TOTAL},"recommendations":["Reduce critical hunter failures","Address warnings to raise score"],"upstream_analysis":{"box":"Aggregate health degradation","closet":"Multiple failing domains","policy":"Weighted health scoring & gating"},"policy_invariants":["findings.score>=20"] }
EOF
echo "health_index: $(jq -r .findings.score "$OUT") (crit=$CRIT warn=$WARN)"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) score=$SCORE critical=$CRIT warn=$WARN" >> "$REPORT_DIR/health_index.trend.log"
