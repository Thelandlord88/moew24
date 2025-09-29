#!/bin/bash
# Environment Security Hunter
# Detects client-side environment variable exposure (CRITICAL SECURITY ISSUE)
# Part of Hunter Thinker 2.0 System - Upstream-Curious Security Enforcement

set -euo pipefail

# Optional shared helpers
if [[ -f "hunters/_common.sh" ]]; then source hunters/_common.sh || true; fi

HUNTER_NAME="environment_security"
REPORT_FILE="__reports/hunt/${HUNTER_NAME}.json"
CRITICAL_ISSUES=0
WARNING_ISSUES=0

echo "🔒 ENVIRONMENT SECURITY HUNTER"
echo "============================="
echo "Upstream Focus: Eliminate environment variable exposure class"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize report structure
cat > "$REPORT_FILE" << 'EOF'
{
  "hunter": "environment_security",
  "version": "2.0",
  "methodology": "upstream_curious",
  "timestamp": "",
  "critical_issues": 0,
  "warning_issues": 0,
  "status": "unknown",
  "findings": {
    "client_env_exposure": [],
    "server_boundary_violations": [],
    "hardcoded_secrets": [],
    "env_validation_missing": []
  },
  "upstream_analysis": {
    "box": "",
    "closet": "",
    "policy": ""
  },
  "recommendations": []
}
EOF

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TIMESTAMP" '.timestamp = $ts' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo "🔍 Scanning for client-side process.env usage..."

# Scan for client-side environment variable usage
CLIENT_ENV_FILES=()
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        file=$(echo "$line" | cut -d: -f1)
        line_num=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)
        
        # Skip server-side files
        if [[ "$file" == *"/server/"* ]] || [[ "$file" == *".server."* ]] || [[ "$file" == *"astro.config"* ]]; then
            continue
        fi
        
        CLIENT_ENV_FILES+=("$file:$line_num:$content")
        echo "❌ CRITICAL: Client-side env access in $file:$line_num"
        echo "   → $content"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    fi
done < <(grep -r "process\.env" src/ --include="*.ts" --include="*.js" --include="*.astro" -n 2>/dev/null || true)

echo ""
echo "🔍 Scanning for hardcoded secrets patterns..."

# Check for potential hardcoded secrets
SECRET_PATTERNS=(
    "api[_-]?key"
    "secret[_-]?key"
    "password"
    "token"
    "auth[_-]?token"
    "bearer"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            content=$(echo "$line" | cut -d: -f3-)
            
            echo "⚠️  Potential secret in $file:$line_num"
            echo "   → $content"
            WARNING_ISSUES=$((WARNING_ISSUES + 1))
        fi
    done < <(grep -ri "$pattern.*[=:].*['\"][^'\"]*['\"]" src/ --include="*.ts" --include="*.js" --include="*.astro" -n 2>/dev/null | head -5 || true)
done

echo ""
echo "🔍 Checking for environment validation..."

# Check if there's proper environment validation
ENV_VALIDATION_EXISTS=false
if [[ -f "src/lib/env.ts" ]] || [[ -f "src/lib/env.server.ts" ]] || [[ -f "src/utils/env.ts" ]]; then
    ENV_VALIDATION_EXISTS=true
    echo "✅ Environment validation file found"
else
    echo "⚠️  No environment validation file found"
    WARNING_ISSUES=$((WARNING_ISSUES + 1))
fi

# Update report with findings + unified keys (non-destructive if _common.sh absent)
jq --argjson critical "$CRITICAL_ISSUES" --argjson warning "$WARNING_ISSUES" \
    '.critical_issues = $critical | .warning_issues = $warning | .issues_total = ($critical + $warning) | .schema_version = 1' \
    "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Determine status
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    STATUS="critical"
    EXIT_CODE=2
elif [[ $WARNING_ISSUES -gt 0 ]]; then
    STATUS="warn"
    EXIT_CODE=1
else
    STATUS="pass"
    EXIT_CODE=0
fi

# Update upstream analysis
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    UPSTREAM_BOX="Environment variables exposed in client-side code"
    UPSTREAM_CLOSET="Missing client/server boundary enforcement architecture"
    UPSTREAM_POLICY="Implement server-side env service + hunter validation gate"
else
    UPSTREAM_BOX="Environment security practices"
    UPSTREAM_CLOSET="Proper separation of client/server environment access"
    UPSTREAM_POLICY="Maintain environment security through automated validation"
fi

jq --arg status "$STATUS" \
   --arg box "$UPSTREAM_BOX" \
   --arg closet "$UPSTREAM_CLOSET" \
   --arg policy "$UPSTREAM_POLICY" \
   '.status = $status | 
    .upstream_analysis.box = $box | 
    .upstream_analysis.closet = $closet | 
    .upstream_analysis.policy = $policy' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Add recommendations
RECOMMENDATIONS=()
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Create src/lib/env.server.ts for server-side environment access only"
        "Implement client/server boundary validation with runtime checks"
        "Use Astro.locals or build-time environment injection for client needs"
        "Add TypeScript interfaces to enforce environment variable types"
    )
fi

if [[ $WARNING_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Implement environment variable validation schema"
        "Add development vs production environment checks"
        "Create environment variable documentation"
    )
fi

# Convert recommendations array to JSON and update report
RECOMMENDATIONS_JSON=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
jq --argjson recs "$RECOMMENDATIONS_JSON" '.recommendations = $recs' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo ""
echo "Environment Security Analysis Summary:"
echo "===================================="
echo "Issues: $(($CRITICAL_ISSUES + $WARNING_ISSUES))"
echo "Critical: $CRITICAL_ISSUES"
echo "Warning: $WARNING_ISSUES"
echo "Status: $STATUS"
echo "Report: $REPORT_FILE"

if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    echo ""
    echo "💡 UPSTREAM-CURIOUS SOLUTION:"
    echo "Class Problem: Client-side environment variable access"
    echo "Upstream Fix: Server-side environment service with boundary validation"
    echo ""
    echo "Example Implementation:"
    echo "// src/lib/env.server.ts"
    echo "export const getServerEnv = () => {"
    echo "  if (typeof window !== 'undefined') {"
    echo "    throw new Error('Server env accessed on client');"
    echo "  }"
    echo "  return { siteUrl: process.env.SITE_URL };"
    echo "};"
    echo ""
fi

if [[ $EXIT_CODE -eq 2 ]]; then
    echo "❌ environment_security: critical issues"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠ environment_security: issues found"
else
    echo "✅ environment_security: passed"
fi

exit $EXIT_CODE
