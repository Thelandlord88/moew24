#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/build_ssg_guard.json"
PROBE_JSON=$(node scripts/ssg-classification-probe.mjs 2>/dev/null || echo '{}')
MIDDLEWARE=$(echo "$PROBE_JSON" | jq '.middlewarePresent//false')
SERVER_EP=$(echo "$PROBE_JSON" | jq '.serverEndpoints|length')
STATUS="pass"; CRIT=0; WARN=0
LOG_FILE="$REPORT_DIR/build_ssg_guard.log"
echo "[build_ssg_guard] probe: $PROBE_JSON" > "$LOG_FILE"
BUILD_LOG="$REPORT_DIR/build_ssg_guard.build.txt"
if [[ "$MIDDLEWARE" == true || $SERVER_EP -gt 0 ]]; then
  STATUS="critical"; CRIT=1
else
  # Run minimal build to detect NoAdapterInstalled
  rm -rf .astro dist || true
  if ! (ASTRO_TELEMETRY_DISABLED=1 npx astro build > "$BUILD_LOG" 2>&1); then
    if grep -q NoAdapterInstalled "$BUILD_LOG"; then
      STATUS="critical"; CRIT=1
    else
      STATUS="warn"; WARN=1
    fi
  fi
fi
cat > "$OUT" <<EOF
{ "module":"build_ssg_guard","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$STATUS","critical_issues":$CRIT,"warning_issues":$WARN,"issues_total":$((CRIT+WARN)),"findings":{ "probe":$PROBE_JSON, "no_adapter":$(grep -q NoAdapterInstalled "$BUILD_LOG" && echo true || echo false) },"recommendations":["Remove middleware or server endpoints in SSG mode","If intentional, install adapter and set ALLOW_ADAPTER=1"],"upstream_analysis":{"box":"Build classification mismatch","closet":"Residual server surface or config forcing server mode","policy":"Fail-fast guard before full hunter run"},"policy_invariants":["findings.probe.middlewarePresent==false","findings.probe.serverEndpoints|length==0","findings.no_adapter==false"] }
EOF
echo "build_ssg_guard: $STATUS"; [[ "$STATUS" == critical ]] && exit 2 || { [[ "$STATUS" == warn ]] && exit 1 || exit 0; }
