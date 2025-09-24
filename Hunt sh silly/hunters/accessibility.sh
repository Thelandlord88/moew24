#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/accessibility.sh — Accessibility Validation
#
# PURPOSE: Detect accessibility violations and ensure inclusive design
# ELIMINATION TARGET: Missing alt text, ARIA violations, contrast issues
#
# Box: Accessibility barriers for users
# Closet: HTML/Astro component accessibility patterns
# Policy: Enforce WCAG compliance and inclusive design

set -Eeuo pipefail

# Inherit environment from parent hunt.sh
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"
TIMESTAMP="${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}"
mkdir -p "$REPORT_DIR"

# Colors
if [[ -t 1 ]]; then
  RED='\e[31m'; YEL='\e[33m'; GRN='\e[32m'; CYA='\e[36m'; RST='\e[0m'
else
  RED=''; YEL=''; GRN=''; CYA=''; RST=''
fi

okay() { printf "${GRN}✓ %s${RST}\n" "$*"; }
warn() { printf "${YEL}⚠ %s${RST}\n" "$*"; }
fail() { printf "${RED}✗ %s${RST}\n" "$*"; }

# Output files
A11Y_REPORT="$REPORT_DIR/accessibility.json"
A11Y_LOG="$REPORT_DIR/accessibility.log"

echo "♿ Accessibility Analysis" > "$A11Y_LOG"
echo "========================" >> "$A11Y_LOG"

ISSUES=0
CRITICAL=0

# 1) Missing alt text detection
echo "Checking for missing alt text..." | tee -a "$A11Y_LOG"
MISSING_ALT=$(rg -n "<img(?![^>]*alt=)" src/ --type astro --type html || true)

if [[ -n "$MISSING_ALT" ]]; then
  ALT_COUNT=$(echo "$MISSING_ALT" | wc -l)
  fail "Found $ALT_COUNT image(s) without alt text:"
  echo "$MISSING_ALT" | head -5 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((CRITICAL++))
else
  okay "All images have alt attributes"
fi

# 2) Missing form labels
echo "Checking for unlabeled form inputs..." | tee -a "$A11Y_LOG"
UNLABELED_INPUTS=$(rg -n "<input(?![^>]*aria-label)(?![^>]*aria-labelledby)" src/ --type astro --type html | \
  grep -v "type=['\"]hidden['\"]" || true)

if [[ -n "$UNLABELED_INPUTS" ]]; then
  INPUT_COUNT=$(echo "$UNLABELED_INPUTS" | wc -l)
  warn "Found $INPUT_COUNT potentially unlabeled input(s):"
  echo "$UNLABELED_INPUTS" | head -3 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((ISSUES++))
else
  okay "Form inputs appear to be properly labeled"
fi

# 3) Missing heading hierarchy
echo "Checking heading hierarchy..." | tee -a "$A11Y_LOG"
HEADING_VIOLATIONS=$(rg -n "<h[1-6]" src/ --type astro --type html | \
  sort | awk -F'<h' '{print $2}' | sed 's/[^1-6].*//' | \
  awk 'BEGIN{prev=0} {curr=$1; if(curr>prev+1 && prev!=0) print "Heading skip: h"prev" to h"curr; prev=curr}' || true)

if [[ -n "$HEADING_VIOLATIONS" ]]; then
  warn "Found heading hierarchy issues:"
  echo "$HEADING_VIOLATIONS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((ISSUES++))
else
  okay "Heading hierarchy appears correct"
fi

# 4) Missing ARIA landmarks
echo "Checking for ARIA landmarks..." | tee -a "$A11Y_LOG"
HAS_MAIN=$(rg -q "<main|role=['\"]main['\"]" src/ || echo "NO_MAIN")
HAS_NAV=$(rg -q "<nav|role=['\"]navigation['\"]" src/ || echo "NO_NAV")

if [[ "$HAS_MAIN" == "NO_MAIN" ]]; then
  warn "No main landmark found in templates"
  ((ISSUES++))
fi

if [[ "$HAS_NAV" == "NO_NAV" ]]; then
  warn "No navigation landmark found in templates"
  ((ISSUES++))
fi

if [[ "$HAS_MAIN" != "NO_MAIN" && "$HAS_NAV" != "NO_NAV" ]]; then
  okay "ARIA landmarks present"
fi

# 5) Color contrast issues (basic text pattern check)
echo "Checking for potential color contrast issues..." | tee -a "$A11Y_LOG"
LOW_CONTRAST_PATTERNS=$(rg -n "color:\s*#(ccc|ddd|eee|f0f0f0|light)" src/ --type css --type astro || true)

if [[ -n "$LOW_CONTRAST_PATTERNS" ]]; then
  CONTRAST_COUNT=$(echo "$LOW_CONTRAST_PATTERNS" | wc -l)
  warn "Found $CONTRAST_COUNT potential low contrast color(s):"
  echo "$LOW_CONTRAST_PATTERNS" | head -3 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((ISSUES++))
else
  okay "No obvious low contrast colors found"
fi

# 6) Interactive elements without proper roles
echo "Checking interactive elements..." | tee -a "$A11Y_LOG"
CLICKABLE_DIVS=$(rg -n "<div[^>]*onclick|<span[^>]*onclick" src/ --type astro --type html || true)

if [[ -n "$CLICKABLE_DIVS" ]]; then
  CLICKABLE_COUNT=$(echo "$CLICKABLE_DIVS" | wc -l)
  warn "Found $CLICKABLE_COUNT clickable div/span element(s) (should use button/link):"
  echo "$CLICKABLE_DIVS" | head -3 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((ISSUES++))
else
  okay "No improper clickable elements found"
fi

# 7) Language declaration
echo "Checking for language declarations..." | tee -a "$A11Y_LOG"
LANG_DECLARATION=$(rg -n "lang=['\"]" src/ --type astro --type html || true)

if [[ -z "$LANG_DECLARATION" ]]; then
  warn "No language declarations found in HTML"
  ((ISSUES++))
else
  okay "Language declarations found"
fi

# 8) Focus management
echo "Checking focus management..." | tee -a "$A11Y_LOG"
FOCUS_TRAPS=$(rg -n "tabindex=['\"](-[0-9]+)['\"]" src/ --type astro --type html || true)

if [[ -n "$FOCUS_TRAPS" ]]; then
  FOCUS_COUNT=$(echo "$FOCUS_TRAPS" | wc -l)
  warn "Found $FOCUS_COUNT negative tabindex value(s) (removes from tab order):"
  echo "$FOCUS_TRAPS" | head -3 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$A11Y_LOG"
  done
  ((ISSUES++))
else
  okay "No concerning tabindex usage found"
fi

# Update final report
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

# Generate final JSON report
cat > "$A11Y_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "accessibility",
  "status": "$STATUS",
  "findings": {
    "missing_alt": $(echo "$MISSING_ALT" | wc -l),
    "unlabeled_inputs": $(echo "$UNLABELED_INPUTS" | wc -l),
    "heading_violations": $(echo "$HEADING_VIOLATIONS" | wc -l),
    "low_contrast": $(echo "$LOW_CONTRAST_PATTERNS" | wc -l),
    "clickable_divs": $(echo "$CLICKABLE_DIVS" | wc -l),
    "focus_traps": $(echo "$FOCUS_TRAPS" | wc -l)
  },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "recommendations": [
    "Add descriptive alt text to all images",
    "Ensure all form inputs have proper labels",
    "Follow proper heading hierarchy (h1->h2->h3)",
    "Use semantic HTML elements for interactive content",
    "Test with keyboard navigation",
    "Verify color contrast ratios meet WCAG guidelines"
  ]
}
EOF

# Summary
echo | tee -a "$A11Y_LOG"
echo "Accessibility Analysis Summary:" | tee -a "$A11Y_LOG"
echo "==============================" | tee -a "$A11Y_LOG"
echo "Issues: $ISSUES" | tee -a "$A11Y_LOG"
echo "Critical: $CRITICAL" | tee -a "$A11Y_LOG"
echo "Status: $STATUS" | tee -a "$A11Y_LOG"
echo "Report: $A11Y_REPORT" | tee -a "$A11Y_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2  # Critical issues
elif (( ISSUES > 0 )); then
  exit 1  # Warning issues
else
  exit 0  # Clean
fi
