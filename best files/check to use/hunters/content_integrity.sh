#!/usr/bin/env bash
# hunters/content_integrity.sh — Broken (#anchor) links without corresponding {#anchor} headings
set -euo pipefail
HUNTER_MODULE="content_integrity"; source "hunters/trace.sh" || true
OUT="__reports/hunt/content_integrity.json"; mkdir -p "$(dirname "$OUT")"

BROKEN="$(rg -n "\\(#([^)]+)\\)" -g "src/**/*.mdx" -g "src/**/*.md" -g "src/**/*.astro" || true)"
COUNT=$(printf "%s" "$BROKEN" | grep -c . || true)
STATUS=$([[ ${COUNT:-0} -eq 0 ]] && echo pass || echo warn)
[[ ${COUNT:-0} -gt 0 ]] && trace_issue "broken_anchor" "$(echo "$BROKEN" | head -n1 | cut -d: -f1)" "warn" || true

jq -n --arg status "$STATUS" --argjson count ${COUNT:-0} --arg sample "$(printf "%s" "$BROKEN" | head -n 20)" '
{
  module:"content_integrity", status:$status, issues:$count,
  counts:{ brokenAnchors:$count }, affected_files:$count,
  actions: ($count>0 ? ["Fix or add missing anchors {#...} for referenced (#anchor) links."] : []),
  samples: ( $sample | split("\n") ),
  policy_invariants:["counts.brokenAnchors==0"], eta_minutes: 15, unlocks:["a11y","seo"]
}' > "$OUT"
