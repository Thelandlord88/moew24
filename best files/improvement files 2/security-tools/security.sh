#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/security.sh — Security Vulnerability Detection
#
# PURPOSE: Detect security vulnerabilities before they reach production
# ELIMINATION TARGET: Entire class of security holes (secrets, XSS, eval, mixed content)
#
# Box: Security vulnerabilities in codebase
# Closet: Source code security patterns
# Policy: Block dangerous patterns, enforce security practices

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
SEC_REPORT="$REPORT_DIR/security.json"
SEC_LOG="$REPORT_DIR/security.log"

echo "🔒 Security Vulnerability Scan" > "$SEC_LOG"
echo "==============================" >> "$SEC_LOG"

ISSUES=0
CRITICAL=0

# 1) Hardcoded secrets detection
echo "Scanning for hardcoded secrets..." | tee -a "$SEC_LOG"
SECRETS=$(rg -i "api[_-]?key|secret|token|password|stripe[_-]?key|aws[_-]?access|bearer" \
  --type js --type ts --type json \
  -g '!package-lock.json' -g '!node_modules' | head -10 || true)

if [[ -n "$SECRETS" ]]; then
  SECRET_COUNT=$(echo "$SECRETS" | wc -l)
  fail "Found $SECRET_COUNT potential hardcoded secret(s):"
  echo "$SECRETS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$SEC_LOG"
  done
  ((CRITICAL++))
else
  okay "No obvious hardcoded secrets found"
fi

# 2) Dangerous code execution patterns
echo "Checking for dangerous code execution..." | tee -a "$SEC_LOG"
DANGEROUS_CODE=$(rg -n "eval\s*\(|new\s+Function\s*\(|setTimeout\s*\([^,]*['\"][^'\"]*['\"]" \
  src/ --type js --type ts || true)

if [[ -n "$DANGEROUS_CODE" ]]; then
  DANGER_COUNT=$(echo "$DANGEROUS_CODE" | wc -l)
  fail "Found $DANGER_COUNT dangerous code execution pattern(s):"
  echo "$DANGEROUS_CODE" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$SEC_LOG"
  done
  ((CRITICAL++))
else
  okay "No dangerous code execution patterns found"
fi

# 3) XSS vulnerability patterns
echo "Scanning for XSS vulnerability patterns..." | tee -a "$SEC_LOG"
XSS_PATTERNS=$(rg -n "innerHTML|outerHTML|insertAdjacentHTML|set:html" \
  src/ --type js --type ts --type astro || true)

if [[ -n "$XSS_PATTERNS" ]]; then
  XSS_COUNT=$(echo "$XSS_PATTERNS" | wc -l)
  warn "Found $XSS_COUNT potential XSS pattern(s):"
  echo "$XSS_PATTERNS" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$SEC_LOG"
  done
  ((ISSUES++))
else
  okay "No obvious XSS patterns found"
fi

# 4) Mixed content detection
echo "Checking for mixed content issues..." | tee -a "$SEC_LOG"
MIXED_CONTENT=$(rg -n "http://(?!localhost|127\.0\.0\.1)" src/ public/ || true)

if [[ -n "$MIXED_CONTENT" ]]; then
  MIXED_COUNT=$(echo "$MIXED_CONTENT" | wc -l)
  warn "Found $MIXED_COUNT mixed content issue(s):"
  echo "$MIXED_CONTENT" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$SEC_LOG"
  done
  ((ISSUES++))
else
  okay "No mixed content issues found"
fi

# 5) Environment variable exposure
echo "Checking for environment variable exposure..." | tee -a "$SEC_LOG"
ENV_EXPOSURE=$(rg -n "process\.env" src/ --type js --type ts | \
  grep -v "NODE_ENV\|development\|production" | head -5 || true)

if [[ -n "$ENV_EXPOSURE" ]]; then
  ENV_COUNT=$(echo "$ENV_EXPOSURE" | wc -l)
  warn "Found $ENV_COUNT potential environment variable exposure(s):"
  echo "$ENV_EXPOSURE" | while IFS= read -r line; do
    echo "  • $line" | tee -a "$SEC_LOG"
  done
  ((ISSUES++))
else
  okay "No concerning environment variable usage found"
fi

# 6) Check for exposed .env files
echo "Checking for exposed .env files..." | tee -a "$SEC_LOG"
if [[ -f .env && ! -f .gitignore ]] || ! grep -q "\.env" .gitignore 2>/dev/null; then
  fail ".env file exists but may not be properly gitignored"
  ((CRITICAL++))
else
  okay ".env file properly handled"
fi

# Update final report
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

# Generate final JSON report
cat > "$SEC_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "security",
  "status": "$STATUS",
  "findings": {
    "secrets": $(echo "$SECRETS" | wc -l),
    "dangerous_code": $(echo "$DANGEROUS_CODE" | wc -l),
    "xss_patterns": $(echo "$XSS_PATTERNS" | wc -l),
    "mixed_content": $(echo "$MIXED_CONTENT" | wc -l),
    "env_exposure": $(echo "$ENV_EXPOSURE" | wc -l)
  },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "recommendations": [
    "Move secrets to environment variables",
    "Sanitize all user input before rendering",
    "Use HTTPS for all external resources",
    "Add Content Security Policy headers",
    "Regular dependency vulnerability scanning"
  ]
}
EOF

# Summary
echo | tee -a "$SEC_LOG"
echo "Security Scan Summary:" | tee -a "$SEC_LOG"
echo "=====================" | tee -a "$SEC_LOG"
echo "Issues: $ISSUES" | tee -a "$SEC_LOG"
echo "Critical: $CRITICAL" | tee -a "$SEC_LOG"
echo "Status: $STATUS" | tee -a "$SEC_LOG"
echo "Report: $SEC_REPORT" | tee -a "$SEC_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2  # Critical issues
elif (( ISSUES > 0 )); then
  exit 1  # Warning issues
else
  exit 0  # Clean
fi
