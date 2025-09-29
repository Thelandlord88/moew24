#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/asset_weight.json"
LIM_BIG=${ASSET_IMG_MAX_KB:-500}
IMAGES=$(find src/assets/images -type f -maxdepth 1 2>/dev/null || true)
declare -i BIG=0; TOP_SIZE=0; LARGEST=""
LIST=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
  kb=$(( (sz+1023)/1024 ))
  if (( kb > TOP_SIZE )); then TOP_SIZE=$kb; LARGEST=$f; fi
  if (( kb > LIM_BIG )); then BIG=$((BIG+1)); LIST+=("$f:$kb") ; fi
done < <(printf '%s\n' "$IMAGES")
status=pass; crit=0; warn=0
if (( BIG>0 )); then status=warn; warn=1; fi
cat > "$OUT" <<EOF
{ "module":"asset_weight","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"$status","critical_issues":$crit,"warning_issues":$warn,"issues_total":$((crit+warn)),"findings":{"largest_kb":$TOP_SIZE,"largest_file":"$LARGEST","over_limit":$BIG,"limit_kb":$LIM_BIG,"over_list":$(printf '%s\n' "${LIST[@]}" | jq -R . | jq -s .)},"recommendations":["Convert large PNGs to WebP/AVIF","Enforce size budget"],"upstream_analysis":{"box":"Oversized images inflate load","closet":"Unoptimized assets","policy":"Weight budget + conversion guidance"},"policy_invariants":["findings.largest_kb<=findings.limit_kb"] }
EOF
echo "asset_weight: $status"; [[ "$status" == warn ]] && exit 1 || exit 0
