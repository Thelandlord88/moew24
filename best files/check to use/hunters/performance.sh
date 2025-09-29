#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/performance.sh — Performance Issue Detection
#
# PURPOSE: Detect performance bottlenecks and optimization opportunities
# ELIMINATION TARGET: Large assets, unused dependencies, circular imports
#
# Box: Performance issues and bloat
# Closet: Asset optimization and dependency management
# Policy: Enforce performance budgets and optimization practices

set -euo pipefail
REPORT_COMPLETED=0
trap 'if [[ ! -s "$PERF_REPORT" || "$REPORT_COMPLETED" != 1 ]]; then mkdir -p "${REPORT_DIR:-__reports/hunt}"; printf "{\n  \"module\": \"performance\", \"status\": \"error\", \"issues\": %s, \"critical\": %s, \"counts\": { \"largeImages\": 0 }\n}\n" "${ISSUES:-0}" "${CRITICAL:-0}" > "$PERF_REPORT"; fi' EXIT

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
PERF_REPORT="$REPORT_DIR/performance.json"
PERF_LOG="$REPORT_DIR/performance.log"

echo "📈 Performance Analysis" > "$PERF_LOG"
echo "======================" >> "$PERF_LOG"

ISSUES=0
CRITICAL=0

# Allow detection to continue on non-zero (missing matches etc.)
set +e

# 1) Large image detection (>500KB)
echo "Scanning for large images..." | tee -a "$PERF_LOG"
LARGE_IMAGES=$( (find src/assets public/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) 2>/dev/null || true) | while IFS= read -r f; do [ -f "$f" ] || continue; sz=$(stat -c%s "$f" 2>/dev/null || echo 0); if [ "$sz" -gt 512000 ]; then echo "$f ($sz bytes)"; fi; done )

if [[ -n "$LARGE_IMAGES" ]]; then
  IMAGE_COUNT=$(echo "$LARGE_IMAGES" | wc -l)
  warn "Found $IMAGE_COUNT large image(s) >500KB:"
  echo "$LARGE_IMAGES" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$PERF_LOG"
  done
  ((ISSUES++))
else
  okay "No large images found"
fi

# 2) Check for WebP/AVIF alternatives
echo "Checking for modern image format usage..." | tee -a "$PERF_LOG"
PNG_COUNT=$(find src/assets public/ -name "*.png" 2>/dev/null | wc -l)
WEBP_COUNT=$(find src/assets public/ -name "*.webp" 2>/dev/null | wc -l)
AVIF_COUNT=$(find src/assets public/ -name "*.avif" 2>/dev/null | wc -l)

if (( PNG_COUNT > 0 && WEBP_COUNT == 0 && AVIF_COUNT == 0 )); then
  warn "Found $PNG_COUNT PNG files but no WebP/AVIF alternatives"
  ((ISSUES++))
else
  okay "Modern image formats in use or no PNG files found"
fi

# 3) Package.json dependency analysis
echo "Analyzing package dependencies..." | tee -a "$PERF_LOG"
if [[ -f package.json ]]; then
  DEP_COUNT=$(node -e "const p=require('./package.json'); console.log(Object.keys(p.dependencies||{}).length + Object.keys(p.devDependencies||{}).length)")
  
  if (( DEP_COUNT > 100 )); then
    warn "High dependency count: $DEP_COUNT packages"
    ((ISSUES++))
  else
    okay "Reasonable dependency count: $DEP_COUNT packages"
  fi
  
  # Check for duplicate functionality
  DUPLICATE_DEPS=$(node -e "
    const p=require('./package.json');
    const deps = {...(p.dependencies||{}), ...(p.devDependencies||{})};
    const suspects = [];
    if (deps.lodash && deps.ramda) suspects.push('lodash+ramda');
    if (deps.moment && deps.dayjs) suspects.push('moment+dayjs');
    if (deps.axios && deps.fetch) suspects.push('axios+fetch');
    console.log(suspects.join(', '));
  " || true)
  
  if [[ -n "$DUPLICATE_DEPS" ]]; then
    warn "Potential duplicate dependencies: $DUPLICATE_DEPS"
    ((ISSUES++))
  fi
else
  warn "No package.json found"
  ((ISSUES++))
fi

# 4) Bundle size estimation
echo "Estimating bundle impact..." | tee -a "$PERF_LOG"
LARGE_FILES=$(find src/ -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" 2>/dev/null | \
  xargs wc -l 2>/dev/null | sort -nr | head -5 | awk '$1 > 500 {print $2 " (" $1 " lines)"}' || true)

if [[ -n "$LARGE_FILES" ]]; then
  FILE_COUNT=$(echo "$LARGE_FILES" | wc -l)
  warn "Found $FILE_COUNT large source file(s) >500 lines:"
  echo "$LARGE_FILES" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$PERF_LOG"
  done
  ((ISSUES++))
else
  okay "No excessively large source files found"
fi

# 5) Import analysis for potential issues
echo "Analyzing import patterns..." | tee -a "$PERF_LOG"
BARREL_IMPORTS=$(rg -n "import.*from.*index" src/ -g '*.js' -g '*.ts' 2>/dev/null || true)
if [[ -n "$BARREL_IMPORTS" ]]; then
  BARREL_COUNT=$(echo "$BARREL_IMPORTS" | wc -l)
  warn "Found $BARREL_COUNT barrel import(s) (may impact tree-shaking):"
  echo "$BARREL_IMPORTS" | head -3 | while IFS= read -r line; do
    echo "  • $line" | tee -a "$PERF_LOG"
  done
  ((ISSUES++))
else
  okay "No concerning barrel imports found"
fi

# 6) CSS performance check
echo "Checking CSS performance patterns..." | tee -a "$PERF_LOG"
if [[ -d src/styles || -d src/css ]]; then
  CSS_FILES=$(find src/ -name "*.css" -o -name "*.scss" -o -name "*.sass" 2>/dev/null | wc -l)
  if (( CSS_FILES > 20 )); then
    warn "High CSS file count: $CSS_FILES files (consider consolidation)"
    ((ISSUES++))
  else
    okay "Reasonable CSS file count: $CSS_FILES files"
  fi
fi

# Re-enable strict mode before composing JSON
set -e

# Update final report
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

LARGE_IMAGE_COUNT=$(echo "$LARGE_IMAGES" | grep -c . || true)
LARGE_FILE_COUNT=$(echo "$LARGE_FILES" | grep -c . || true)
BARREL_COUNT=$(echo "$BARREL_IMPORTS" | grep -c . || true)

set +e
cat > "$PERF_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "performance",
  "status": "$STATUS",
  "findings": {
    "large_images": $LARGE_IMAGE_COUNT,
    "png_files": $PNG_COUNT,
    "webp_files": $WEBP_COUNT,
    "total_dependencies": ${DEP_COUNT:-0},
    "large_source_files": $LARGE_FILE_COUNT,
    "barrel_imports": $BARREL_COUNT
  },
  "counts": { "largeImages": $LARGE_IMAGE_COUNT },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "actions": [ $( (( LARGE_IMAGE_COUNT>0 )) && echo '"Compress images"') $( (( BARREL_COUNT>0 )) && echo ',"Reduce barrel imports"') ],
  "policy_invariants": [],
  "recommendations": [
    "Convert large PNG images to WebP/AVIF",
    "Implement lazy loading for images",
    "Review and remove unused dependencies",
    "Consider code splitting for large files",
    "Optimize import patterns for better tree-shaking"
  ]
}
EOF
set -e
REPORT_COMPLETED=1
sync || true

# Summary
echo | tee -a "$PERF_LOG"
echo "Performance Analysis Summary:" | tee -a "$PERF_LOG"
echo "============================" | tee -a "$PERF_LOG"
echo "Issues: $ISSUES" | tee -a "$PERF_LOG"
echo "Critical: $CRITICAL" | tee -a "$PERF_LOG"
echo "Status: $STATUS" | tee -a "$PERF_LOG"
echo "Report: $PERF_REPORT" | tee -a "$PERF_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2  # Critical issues
elif (( ISSUES > 0 )); then
  exit 1  # Warning issues
else
  exit 0  # Clean
fi
