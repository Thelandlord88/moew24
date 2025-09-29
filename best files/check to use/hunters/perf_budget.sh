#!/usr/bin/env bash
# hunters/perf_budget.sh — Build-time budgets using dist/ assets (no Lighthouse)
set -euo pipefail
HUNTER_MODULE="perf_budget"; source "hunters/trace.sh" || true
OUT="__reports/hunt/perf_budget.json"; mkdir -p "$(dirname "$OUT")"

BUDGET_JS_KB=${BUDGET_JS_KB:-350}      # tune as needed
BUDGET_IMG_KB=${BUDGET_IMG_KB:-512}

total_js_kb=0
large_images=0
if [[ -d "dist/assets" ]]; then
  while IFS= read -r f; do
    kb=$(( ( $(stat -c%s "$f" 2>/dev/null || stat -f%z "$f") + 1023 ) / 1024 ))
    [[ "$f" == *.js ]] && total_js_kb=$((total_js_kb + kb))
  done < <(find dist/assets -type f -maxdepth 1 2>/dev/null)

  while IFS= read -r f; do
    kb=$(( ( $(stat -c%s "$f" 2>/dev/null || stat -f%z "$f") + 1023 ) / 1024 ))
    if [[ $kb -gt $BUDGET_IMG_KB ]]; then
      large_images=$((large_images+1))
      trace_issue "large_image" "$f" "warn" || true
    fi
  done < <(find dist -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) 2>/dev/null)
fi

status="pass"
[[ $total_js_kb -gt $BUDGET_JS_KB ]] && status="warn"
[[ $large_images -gt 0 ]] && status="warn"

jq -n --arg status "$status" --argjson totalJsKb ${total_js_kb:-0} --argjson largeImages ${large_images:-0} --argjson jsBudget ${BUDGET_JS_KB:-350} --argjson imgBudget ${BUDGET_IMG_KB:-512} '
{
  module:"perf_budget", status:$status, issues: ( ($totalJsKb > $jsBudget ? 1 : 0) + ($largeImages>0 ? 1 : 0) ),
  counts: { totalJsKb: $totalJsKb, largeImages: $largeImages },
  budgets: { jsKb: $jsBudget, imageKb: $imgBudget },
  affected_files: $largeImages,
  actions: ( ($totalJsKb > $jsBudget) or ($largeImages>0) ? ["Reduce total JS (code-split, remove unused libs); compress/resize large images."] : [] ),
  policy_invariants: [], eta_minutes: 25, unlocks:["cls","ttfb"]
}' > "$OUT"
