#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/code_quality.sh — Code Quality & Technical Debt Analysis
#
# PURPOSE: Detect code quality issues and technical debt accumulation
# ELIMINATION TARGET: Dead code, complexity hotspots, duplication
#
# Box: Code quality degradation and technical debt
# Closet: Source code patterns and structure
# Policy: Maintain clean, maintainable codebase

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
QUALITY_REPORT="$REPORT_DIR/code_quality.json"
QUALITY_LOG="$REPORT_DIR/code_quality.log"

echo "🔍 Code Quality Analysis" > "$QUALITY_LOG"
echo "========================" >> "$QUALITY_LOG"

ISSUES=0
CRITICAL=0

# 1) Dead code detection (unused imports/exports)
echo "Scanning for potential dead code..." | tee -a "$QUALITY_LOG"
UNUSED_IMPORTS=$(rg -n "^import.*from" src/ --type js --type ts | \
  awk -F: '{print $3}' | sed 's/import[^{]*{\([^}]*\)}.*/\1/' | \
  tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort | uniq -c | \
  awk '$1 == 1 {print $2}' | head -5 || true)

if [[ -n "$UNUSED_IMPORTS" ]]; then
  UNUSED_COUNT=$(echo "$UNUSED_IMPORTS" | wc -l)
  warn "Found $UNUSED_COUNT potentially unused import(s):"
  echo "$UNUSED_IMPORTS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No obvious unused imports detected"
fi

# 2) Long functions detection
echo "Checking for overly long functions..." | tee -a "$QUALITY_LOG"
LONG_FUNCTIONS=$(rg -A 100 "function|=>|const.*=" src/ --type js --type ts | \
  awk '/function|=>/ {start=NR; name=$0} /^}$/ {if(NR-start > 50) print name " (" (NR-start) " lines)"}' | \
  head -5 || true)

if [[ -n "$LONG_FUNCTIONS" ]]; then
  LONG_COUNT=$(echo "$LONG_FUNCTIONS" | wc -l)
  warn "Found $LONG_COUNT function(s) >50 lines:"
  echo "$LONG_FUNCTIONS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No excessively long functions found"
fi

# 3) Magic numbers detection
echo "Scanning for magic numbers..." | tee -a "$QUALITY_LOG"
MAGIC_NUMBERS=$(rg -n "[^a-zA-Z_][0-9]{3,}[^a-zA-Z_]" src/ --type js --type ts | \
  grep -v "1000\|2000\|3000" | head -5 || true)

if [[ -n "$MAGIC_NUMBERS" ]]; then
  MAGIC_COUNT=$(echo "$MAGIC_NUMBERS" | wc -l)
  warn "Found $MAGIC_COUNT potential magic number(s):"
  echo "$MAGIC_NUMBERS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No obvious magic numbers found"
fi

# 4) Deep nesting detection
echo "Checking for deep nesting..." | tee -a "$QUALITY_LOG"
DEEP_NESTING=$(rg -n "^\s{12,}" src/ --type js --type ts | head -5 || true)

if [[ -n "$DEEP_NESTING" ]]; then
  NESTING_COUNT=$(echo "$DEEP_NESTING" | wc -l)
  warn "Found $NESTING_COUNT deeply nested line(s) (>3 levels):"
  echo "$DEEP_NESTING" | while IFS= read -r line; do
    echo "  • $(echo "$line" | cut -c1-80)..." | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No excessive nesting found"
fi

# 5) TODO/FIXME/HACK markers
echo "Counting technical debt markers..." | tee -a "$QUALITY_LOG"
TODO_MARKERS=$(rg -n "\b(TODO|FIXME|HACK|XXX)\b" src/ --type js --type ts --type astro || true)

if [[ -n "$TODO_MARKERS" ]]; then
  TODO_COUNT=$(echo "$TODO_MARKERS" | wc -l)
  if (( TODO_COUNT > 20 )); then
    warn "High TODO/FIXME count: $TODO_COUNT markers"
    ((ISSUES++))
  else
    okay "Manageable TODO/FIXME count: $TODO_COUNT markers"
  fi
else
  okay "No TODO/FIXME markers found"
fi

# 6) Code duplication detection (simple pattern matching)
echo "Scanning for potential code duplication..." | tee -a "$QUALITY_LOG"
DUPLICATE_PATTERNS=$(rg -n "console\.log\(|\.map\(|\.filter\(|\.reduce\(" src/ --type js --type ts | \
  awk -F: '{print $3}' | sort | uniq -c | awk '$1 > 5 {print $1 " occurrences: " $2}' | head -3 || true)

if [[ -n "$DUPLICATE_PATTERNS" ]]; then
  DUPLICATE_COUNT=$(echo "$DUPLICATE_PATTERNS" | wc -l)
  warn "Found $DUPLICATE_COUNT potentially duplicated pattern(s):"
  echo "$DUPLICATE_PATTERNS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No obvious code duplication detected"
fi

# 7) Large parameter lists
echo "Checking for functions with many parameters..." | tee -a "$QUALITY_LOG"
LARGE_PARAM_LISTS=$(rg -n "function.*\([^)]*,[^)]*,[^)]*,[^)]*,[^)]*,[^)]*" src/ --type js --type ts || true)

if [[ -n "$LARGE_PARAM_LISTS" ]]; then
  PARAM_COUNT=$(echo "$LARGE_PARAM_LISTS" | wc -l)
  warn "Found $PARAM_COUNT function(s) with >5 parameters:"
  echo "$LARGE_PARAM_LISTS" | head -3 | while IFS= read -r line; do
    echo "  • $(echo "$line" | cut -c1-80)..." | tee -a "$QUALITY_LOG"
  done
  ((ISSUES++))
else
  okay "No functions with excessive parameters found"
fi

# 8) Error handling analysis
echo "Checking error handling patterns..." | tee -a "$QUALITY_LOG"
TRY_CATCH_COUNT=$(rg -c "try\s*{|catch\s*\(" src/ --type js --type ts | awk -F: '{sum+=$2} END {print sum}' || echo "0")
THROW_COUNT=$(rg -c "throw\s" src/ --type js --type ts | awk -F: '{sum+=$2} END {print sum}' || echo "0")

if (( TRY_CATCH_COUNT < THROW_COUNT )); then
  warn "More throws ($THROW_COUNT) than try/catch blocks ($TRY_CATCH_COUNT)"
  ((ISSUES++))
else
  okay "Error handling appears balanced (try/catch: $TRY_CATCH_COUNT, throws: $THROW_COUNT)"
fi

# Update final report
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

# Generate final JSON report
cat > "$QUALITY_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "code_quality",
  "status": "$STATUS",
  "findings": {
    "unused_imports": $(echo "$UNUSED_IMPORTS" | wc -l),
    "long_functions": $(echo "$LONG_FUNCTIONS" | wc -l),
    "magic_numbers": $(echo "$MAGIC_NUMBERS" | wc -l),
    "deep_nesting": $(echo "$DEEP_NESTING" | wc -l),
    "todo_markers": ${TODO_COUNT:-0},
    "duplicate_patterns": $(echo "$DUPLICATE_PATTERNS" | wc -l),
    "large_param_lists": $(echo "$LARGE_PARAM_LISTS" | wc -l)
  },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "recommendations": [
    "Remove unused imports and dead code",
    "Break down large functions into smaller units",
    "Replace magic numbers with named constants",
    "Reduce nesting with early returns or guard clauses",
    "Address TODO/FIXME markers",
    "Extract common patterns into reusable functions"
  ]
}
EOF

# Summary
echo | tee -a "$QUALITY_LOG"
echo "Code Quality Analysis Summary:" | tee -a "$QUALITY_LOG"
echo "=============================" | tee -a "$QUALITY_LOG"
echo "Issues: $ISSUES" | tee -a "$QUALITY_LOG"
echo "Critical: $CRITICAL" | tee -a "$QUALITY_LOG"
echo "Status: $STATUS" | tee -a "$QUALITY_LOG"
echo "Report: $QUALITY_REPORT" | tee -a "$QUALITY_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2  # Critical issues
elif (( ISSUES > 0 )); then
  exit 1  # Warning issues
else
  exit 0  # Clean
fi
