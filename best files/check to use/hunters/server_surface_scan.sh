#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/server_surface_scan.json"
LOG="$REPORT_DIR/server_surface_scan.log"
echo "[server-surface-scan] scanning" > "$LOG"

RAW=$(node scripts/ssg-classification-probe.mjs 2>>"$LOG" || echo '{}')
mw=$(echo "$RAW" | jq '.middlewareFiles | length // 0') || mw=0
srv=$(echo "$RAW" | jq '.serverNamedFiles | length // 0') || srv=0
req=$(echo "$RAW" | jq '.onRequestFiles | length // 0') || req=0
mods=$(echo "$RAW" | jq '.nodeModulesAtTopLevel | length // 0') || mods=0
regen=$(echo "$RAW" | jq '.regenScripts | length // 0') || regen=0
total=$((mw+srv+req+mods+regen))
status="pass"
(( total>0 )) && status="critical"

cat > "$OUT" <<EOF
{ "module":"server_surface_scan", "timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)", "status":"$status", "findings": $RAW,
  "policy_invariants":[
    "findings.middlewareFiles|length==0",
    "findings.serverNamedFiles|length==0",
    "findings.onRequestFiles|length==0",
    "findings.nodeModulesAtTopLevel|length==0",
    "findings.regenScripts|length==0"
  ],
  "recommendations":[
    "Remove middleware from src/ to preserve SSG",
    "Rename or refactor .server.* if not required",
    "Eliminate onRequest exports unless adapter installed",
    "Lazy-load Node core usage or confine to build scripts",
    "Disable or quarantine scripts that recreate middleware during build"
  ] }
EOF

echo "server_surface_scan: $status"
[[ "$status" == critical ]] && exit 2 || exit 0
