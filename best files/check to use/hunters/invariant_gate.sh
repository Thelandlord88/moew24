#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/invariant_gate.json"
STATUS="pass"; CRIT=0; WARN=0
FAILURES=()
for f in $REPORT_DIR/*.json; do
  mod=$(jq -r '.module // .hunter // empty' "$f" 2>/dev/null || echo '')
  [[ -z "$mod" || "$mod" == "invariant_gate" ]] && continue
  invs=$(jq -r '.policy_invariants[]?' "$f" 2>/dev/null || true)
  if [[ -z "$invs" ]]; then
    FAILURES+=("$mod:missing_invariants"); CRIT=$((CRIT+1)); STATUS="critical"; continue
  fi
  while IFS= read -r expr; do
    [[ -z "$expr" ]] && continue
    ok=$(jq "$expr" "$f" 2>/dev/null || echo 'false')
    if [[ "$ok" != true ]]; then
      FAILURES+=("$mod:expr:$expr"); CRIT=$((CRIT+1)); STATUS="critical"
    fi
  done < <(echo "$invs")
done
cat > "$OUT" <<EOF
{ "module":"invariant_gate","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$STATUS","critical_issues":$CRIT,"warning_issues":$WARN,"issues_total":$((CRIT+WARN)),"findings":{"failures":$(printf '%s\n' "${FAILURES[@]}" | jq -R . | jq -s .)},"recommendations":["Fix failing invariants or add missing policy_invariants"],"upstream_analysis":{"box":"Invariant regressions","closet":"Missing or broken policy assertions","policy":"Central invariant gate hunter"},"policy_invariants":["findings.failures|length==0"] }
EOF
if (( CRIT>0 )); then echo "invariant_gate: critical"; exit 2; else echo "invariant_gate: pass"; fi
