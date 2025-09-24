#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/runtime_ssr.sh — SSR Detection & NoAdapterInstalled Prevention
#
# PURPOSE: Detect runtime SSR triggers that could cause NoAdapterInstalled errors
# ELIMINATION TARGET: Entire class of build-time SSR detection failures
#
# Box: NoAdapterInstalled errors during build
# Closet: Dynamic imports and SSR-triggering patterns
# Policy: Catch SSR triggers before build, force SSG compliance

set -uo pipefail  # Removed -e to handle expected failures gracefully

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
SSR_REPORT="$REPORT_DIR/runtime_ssr.json"
SSR_LOG="$REPORT_DIR/runtime_ssr.log"

echo "🚀 SSR Runtime Detection" > "$SSR_LOG"
echo "========================" >> "$SSR_LOG"

# Initialize report
cat > "$SSR_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "runtime_ssr",
  "status": "running",
  "findings": {
    "dynamic_imports": [],
    "ssr_triggers": [],
    "api_routes": [],
    "adapter_references": []
  },
  "issues": 0,
  "critical": 0
}
EOF

declare -i ISSUES=0
declare -i CRITICAL=0

# 1) Check astro.config.* for SSR vs SSG configuration
echo "Checking astro.config.* configuration..." | tee -a "$SSR_LOG"
if [[ -f astro.config.mjs ]]; then
  if grep -q 'output.*static' astro.config.mjs; then
    okay "astro.config.mjs set to output: 'static' (SSG mode)"
  else
    warn "astro.config.mjs missing output: 'static' declaration"
    ((ISSUES++))
  fi
  
  if grep -q '^[^/]*adapter:' astro.config.mjs; then
    fail "Active adapter found in astro.config.mjs (conflicts with SSG)"
    ((CRITICAL++))
  fi
else
  warn "No astro.config.mjs found"
  ((ISSUES++))
fi

# 2) Detect dangerous dynamic imports (NoAdapterInstalled triggers)
echo "Scanning for dynamic imports that trigger SSR detection..." | tee -a "$SSR_LOG"
DYNAMIC_IMPORTS=$(rg -n "import\s*\(" src/ --type js --type ts | head -20 || true)
if [[ -n "$DYNAMIC_IMPORTS" ]]; then
  DYNAMIC_COUNT=$(echo "$DYNAMIC_IMPORTS" | wc -l)
  warn "Found $DYNAMIC_COUNT dynamic import(s) that may trigger SSR:"
  # Use here-string to avoid subshell issues
  while IFS= read -r line; do
    echo "  • $line" | tee -a "$SSR_LOG"
  done <<< "$DYNAMIC_IMPORTS"
  ((ISSUES++))
else
  okay "No dangerous dynamic imports found"
fi

# 3) Check for import assertions (major SSR trigger)
echo "Checking for import assertions..." | tee -a "$SSR_LOG"
IMPORT_ASSERTIONS=$(rg -n "assert.*type.*json" src/ || true)
if [[ -n "$IMPORT_ASSERTIONS" ]]; then
  ASSERT_COUNT=$(echo "$IMPORT_ASSERTIONS" | wc -l)
  fail "Found $ASSERT_COUNT import assertion(s) - MAJOR SSR trigger:"
  # Use here-string to avoid subshell issues
  while IFS= read -r line; do
    echo "  • $line" | tee -a "$SSR_LOG"
  done <<< "$IMPORT_ASSERTIONS"
  ((CRITICAL++))
else
  okay "No import assertions found"
fi

# 4) API route validation
echo "Validating API routes for SSG compliance..." | tee -a "$SSR_LOG"
API_ROUTES=$(find src/pages -name "*.ts" -o -name "*.js" 2>/dev/null || true)
if [[ -n "$API_ROUTES" ]]; then
  for route in $API_ROUTES; do
    if grep -q "export.*GET\|export.*POST" "$route"; then
      if ! grep -q "prerender.*true" "$route"; then
        warn "API route $route missing 'export const prerender = true'"
        ((ISSUES++))
      else
        okay "API route $route has prerender = true"
      fi
    fi
  done
fi

# 5) Build test (proof invariant)
echo "Running build test to detect NoAdapterInstalled..." | tee -a "$SSR_LOG"
BUILD_TEST=$(timeout 60s npm run build 2>&1 || echo "BUILD_FAILED")
if echo "$BUILD_TEST" | grep -q "NoAdapterInstalled"; then
  fail "BUILD FAILS: NoAdapterInstalled error detected!"
  echo "$BUILD_TEST" | grep -A 5 -B 5 "NoAdapterInstalled" | tee -a "$SSR_LOG"
  ((CRITICAL++))
elif echo "$BUILD_TEST" | grep -q "BUILD_FAILED"; then
  warn "Build failed for other reasons (timeout or other error)"
  ((ISSUES++))
else
  okay "Build test passed - no NoAdapterInstalled error"
fi

# Update final report
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

# Generate final JSON report
cat > "$SSR_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "runtime_ssr",
  "status": "$STATUS",
  "findings": {
    "dynamic_imports": $(echo "$DYNAMIC_IMPORTS" | wc -l),
    "import_assertions": $(echo "$IMPORT_ASSERTIONS" | wc -l),
    "api_routes_checked": $(echo "$API_ROUTES" | wc -w),
    "build_test": "$(if echo "$BUILD_TEST" | grep -q NoAdapterInstalled; then echo "FAILED"; else echo "PASSED"; fi)"
  },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "recommendations": [
    $(if (( CRITICAL > 0 )); then echo '"Replace import assertions with static imports",'; fi)
    $(if echo "$BUILD_TEST" | grep -q NoAdapterInstalled; then echo '"Fix SSR triggers before enabling adapters",'; fi)
    "Ensure all API routes have prerender = true"
  ]
}
EOF

# Summary
echo | tee -a "$SSR_LOG"
echo "SSR Detection Summary:" | tee -a "$SSR_LOG"
echo "=====================" | tee -a "$SSR_LOG"
echo "Issues: $ISSUES" | tee -a "$SSR_LOG"
echo "Critical: $CRITICAL" | tee -a "$SSR_LOG"
echo "Status: $STATUS" | tee -a "$SSR_LOG"
echo "Report: $SSR_REPORT" | tee -a "$SSR_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2  # Critical issues
elif (( ISSUES > 0 )); then
  exit 1  # Warning issues
else
  exit 0  # Clean
fi
