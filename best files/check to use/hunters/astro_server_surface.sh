#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/astro_server_surface.json"
STATUS="pass"; CRIT=0; WARN=0
SERVER_ENDPOINTS=$(grep -R "export const GET" -n src/pages 2>/dev/null || true)
if [[ -n "$SERVER_ENDPOINTS" ]]; then
  STATUS="critical"; CRIT=1
fi
cat > "$OUT" <<EOF
{ "module":"astro_server_surface","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$STATUS","critical_issues":$CRIT,"warning_issues":$WARN,"issues_total":$((CRIT+WARN)),"findings":{"server_endpoints":$(jq -Rn --arg data "$SERVER_ENDPOINTS" '($data|split("\n")|map(select(length>0)))')},"recommendations":["Keep zero server endpoints in static output mode"],"upstream_analysis":{"box":"Server endpoint present in static mode","closet":"pages API surface","policy":"Static sitemap + hunter gating"},"policy_invariants":["findings.server_endpoints|length==0"] }
EOF
if [[ "$STATUS" == critical ]]; then echo "astro_server_surface: critical"; exit 2; else echo "astro_server_surface: pass"; fi
