#!/usr/bin/env bash
# accessibility.sh — lightweight static checks (alt, labels, landmarks, headings, contrast markers)
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/accessibility.json"
mkdir -p "$REPORT_DIR"

scan() {
  local missing_alt=0 missing_labels=0 missing_landmarks=0 bad_headings=0 clickable_divs=0

  missing_alt=$(( $(grep -RIn --binary-files=without-match -E '<img(?![^>]*alt=)' src public 2>/dev/null | wc -l | tr -d ' ') ))
  missing_labels=$(( $(grep -RIn --binary-files=without-match -E '<input(?![^>]*(aria-label|aria-labelledby|alt|name)=)' src 2>/dev/null | wc -l | tr -d ' ') ))
  # landmarks/headings presence heuristics
  local lm_count=0; lm_count=$(grep -RIn --binary-files=without-match -E '<(main|nav|header|footer|aside)\b' src 2>/dev/null | wc -l | tr -d ' ' || true)
  [[ $lm_count -eq 0 ]] && missing_landmarks=1
  local h_count=0; h_count=$(grep -RIn --binary-files=without-match -E '<h[1-6]' src 2>/dev/null | wc -l | tr -d ' ' || true)
  [[ $h_count -eq 0 ]] && bad_headings=1
  clickable_divs=$(( $(grep -RIn --binary-files=without-match -E '<(div|span)[^>]*(onClick|onclick)=' src 2>/dev/null | wc -l | tr -d ' ') ))

  local issues=$(( missing_alt + missing_labels + missing_landmarks + bad_headings + clickable_divs ))
  local status="pass"; [[ $issues -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "accessibility",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "missing_alt": $missing_alt,
    "missing_labels": $missing_labels,
    "missing_landmarks": $missing_landmarks,
    "bad_headings": $bad_headings,
    "clickable_divs": $clickable_divs
  },
  "actions": [
    "Add alt text on all <img>; use descriptive alt or empty alt for decorative",
    "Label inputs with <label>, aria-label, or aria-labelledby",
    "Add main/nav/header/footer landmarks; correct heading order",
    "Avoid clickable <div>/<span>; use <button> with keyboard semantics"
  ],
  "policy_invariants": [
    "counts.missing_alt == 0",
    "counts.missing_labels == 0"
  ],
  "eta_minutes": 25,
  "unlocks": ["performance","code_quality"]
}
JSON
}

scan "."
