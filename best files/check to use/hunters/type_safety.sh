#!/bin/bash
# Type Safety Hunter
# Detects 'any' type usage and enforces TypeScript quality standards
# Part of Hunter Thinker 2.0 System - Upstream-Curious Type System Architecture

set -euo pipefail
if [[ -f hunters/_common.sh ]]; then source hunters/_common.sh || true; fi

HUNTER_NAME="type_safety"
REPORT_FILE="__reports/hunt/${HUNTER_NAME}.json"
MAX_ANY_TYPES=5
CRITICAL_THRESHOLD=20
WARNING_ISSUES=0
CRITICAL_ISSUES=0

echo "🛡️ TYPE SAFETY HUNTER"
echo "===================="
echo "Upstream Focus: Eliminate type safety degradation through strict TypeScript"
echo "Max 'any' types: $MAX_ANY_TYPES (Critical: >$CRITICAL_THRESHOLD)"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize report structure
cat > "$REPORT_FILE" << 'EOF'
{
    "module": "type_safety",
  "version": "2.0",
  "methodology": "upstream_curious",
  "timestamp": "",
  "critical_issues": 0,
  "warning_issues": 0,
  "status": "unknown",
  "config": {
    "max_any_types": 5,
    "critical_threshold": 20
  },
  "findings": {
    "any_type_usage": [],
    "type_assertion_overuse": [],
    "missing_type_definitions": [],
    "unsafe_patterns": []
  },
  "type_safety_metrics": {
    "total_any_count": 0,
    "files_with_any": 0,
    "type_coverage_estimate": 0
  },
  "upstream_analysis": {
    "box": "",
    "closet": "",
    "policy": ""
  },
    "recommendations": [],
    "policy_invariants": ["type_safety_metrics.total_any_count <= 20"]
}
EOF

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TIMESTAMP" '.timestamp = $ts' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo "🔍 Scanning for 'any' type usage..."

ANY_INSTANCES=()
ANY_PATTERNS=(
    ": any[^A-Za-z]"
    "<any>"
    "any\[\]"
    "as any"
    "any\|"
    "Array<any>"
    "Record<.*any.*>"
)

TOTAL_ANY_COUNT=0
FILES_WITH_ANY=0

# Scan for 'any' type patterns
for pattern in "${ANY_PATTERNS[@]}"; do
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            content=$(echo "$line" | cut -d: -f3-)
            
            # Skip type definition files and known libraries
            if [[ "$file" == *".d.ts" ]] || [[ "$file" == *"node_modules"* ]]; then
                continue
            fi
            
            ANY_INSTANCES+=("$file:$line_num:$content")
            TOTAL_ANY_COUNT=$((TOTAL_ANY_COUNT + 1))
            
            if [[ $TOTAL_ANY_COUNT -le 10 ]]; then
                echo "⚠️  'any' type in $file:$line_num"
                echo "   → $(echo "$content" | xargs)"
            fi
        fi
    done < <(grep -r -E "$pattern" src/ --include="*.ts" --include="*.tsx" -n 2>/dev/null || true)
done

# Count unique files with 'any' usage
if [[ ${#ANY_INSTANCES[@]} -gt 0 ]]; then
    FILES_WITH_ANY=$(printf '%s\n' "${ANY_INSTANCES[@]}" | cut -d: -f1 | sort -u | wc -l)
fi

if [[ $TOTAL_ANY_COUNT -gt 10 ]]; then
    echo "   ... and $((TOTAL_ANY_COUNT - 10)) more 'any' type usages"
fi

echo ""
echo "🔍 Scanning for type assertion overuse..."

TYPE_ASSERTIONS=()
ASSERTION_PATTERNS=(
    "as [A-Z][A-Za-z]*"
    "as unknown"
    "<[A-Z][A-Za-z]*>"
)

TOTAL_ASSERTIONS=0

for pattern in "${ASSERTION_PATTERNS[@]}"; do
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            content=$(echo "$line" | cut -d: -f3-)
            
            TYPE_ASSERTIONS+=("$file:$line_num:$content")
            TOTAL_ASSERTIONS=$((TOTAL_ASSERTIONS + 1))
        fi
    done < <(grep -r -E "$pattern" src/ --include="*.ts" --include="*.tsx" -n 2>/dev/null | head -20 || true)
done

echo "🔍 Checking for missing type definitions..."

# Look for commonly untyped patterns
UNTYPED_PATTERNS=()

# Check for functions without return types
FUNCTIONS_WITHOUT_TYPES=$(grep -r "function.*(" src/ --include="*.ts" --include="*.tsx" | grep -v ": " | wc -l 2>/dev/null || echo "0")
if [[ $FUNCTIONS_WITHOUT_TYPES -gt 0 ]]; then
    echo "⚠️  Found $FUNCTIONS_WITHOUT_TYPES functions without explicit return types"
    UNTYPED_PATTERNS+=("functions_without_return_types:$FUNCTIONS_WITHOUT_TYPES")
fi

# Check for implicit any parameters
IMPLICIT_ANY_PARAMS=$(grep -r "function.*([^)]*[^:][)]" src/ --include="*.ts" --include="*.tsx" | wc -l 2>/dev/null || echo "0")
if [[ $IMPLICIT_ANY_PARAMS -gt 0 ]]; then
    echo "⚠️  Found $IMPLICIT_ANY_PARAMS potential implicit any parameters"
    UNTYPED_PATTERNS+=("implicit_any_parameters:$IMPLICIT_ANY_PARAMS")
fi

echo ""
echo "🔍 Analyzing TypeScript configuration..."

# Check for strict mode configuration
STRICT_MODE_ENABLED=false
if [[ -f "tsconfig.json" ]]; then
    if grep -q '"strict"[[:space:]]*:[[:space:]]*true' tsconfig.json; then
        STRICT_MODE_ENABLED=true
        echo "✅ TypeScript strict mode enabled"
    else
        echo "⚠️  TypeScript strict mode not enabled"
        WARNING_ISSUES=$((WARNING_ISSUES + 1))
    fi
else
    echo "⚠️  No tsconfig.json found"
    WARNING_ISSUES=$((WARNING_ISSUES + 1))
fi

# Determine issue severity
if [[ $TOTAL_ANY_COUNT -gt $CRITICAL_THRESHOLD ]]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    echo "❌ CRITICAL: $TOTAL_ANY_COUNT 'any' types exceed critical threshold ($CRITICAL_THRESHOLD)"
elif [[ $TOTAL_ANY_COUNT -gt $MAX_ANY_TYPES ]]; then
    WARNING_ISSUES=$((WARNING_ISSUES + 1))
    echo "⚠️  WARNING: $TOTAL_ANY_COUNT 'any' types exceed recommended limit ($MAX_ANY_TYPES)"
fi

# Calculate type coverage estimate (rough heuristic)
TOTAL_TS_FILES=$(find src/ -name "*.ts" -o -name "*.tsx" | wc -l)
if [[ $TOTAL_TS_FILES -gt 0 ]]; then
    TYPE_COVERAGE=$(( 100 - ((TOTAL_ANY_COUNT * 100) / (TOTAL_TS_FILES * 10)) ))
    if [[ $TYPE_COVERAGE -lt 0 ]]; then TYPE_COVERAGE=0; fi
    if [[ $TYPE_COVERAGE -gt 100 ]]; then TYPE_COVERAGE=100; fi
else
    TYPE_COVERAGE=0
fi

echo ""
echo "📊 Type Safety Analysis:"
echo "  Total 'any' type usage: $TOTAL_ANY_COUNT"
echo "  Files with 'any' types: $FILES_WITH_ANY"
echo "  Type assertions found: $TOTAL_ASSERTIONS"
echo "  Functions without return types: $FUNCTIONS_WITHOUT_TYPES"
echo "  Estimated type coverage: $TYPE_COVERAGE%"
echo "  Strict mode enabled: $STRICT_MODE_ENABLED"

# Prepare data for JSON report
ANY_INSTANCES_JSON="[]"
if [[ ${#ANY_INSTANCES[@]} -gt 0 ]]; then
    ANY_INSTANCES_JSON=$(printf '%s\n' "${ANY_INSTANCES[@]}" | head -50 | jq -R 'split(":") | {file: .[0], line: (.[1] | tonumber), content: (.[2:] | join(":"))}' | jq -s .)
fi

TYPE_ASSERTIONS_JSON="[]"
if [[ ${#TYPE_ASSERTIONS[@]} -gt 0 ]]; then
    TYPE_ASSERTIONS_JSON=$(printf '%s\n' "${TYPE_ASSERTIONS[@]}" | head -20 | jq -R 'split(":") | {file: .[0], line: (.[1] | tonumber), content: (.[2:] | join(":"))}' | jq -s .)
fi

# Update report with findings
jq --argjson critical "$CRITICAL_ISSUES" \
   --argjson warning "$WARNING_ISSUES" \
   --argjson any_instances "$ANY_INSTANCES_JSON" \
   --argjson type_assertions "$TYPE_ASSERTIONS_JSON" \
   --argjson total_any "$TOTAL_ANY_COUNT" \
   --argjson files_with_any "$FILES_WITH_ANY" \
   --argjson type_coverage "$TYPE_COVERAGE" \
   '.critical_issues = $critical | 
    .warning_issues = $warning | 
    .findings.any_type_usage = $any_instances | 
    .findings.type_assertion_overuse = $type_assertions | 
    .type_safety_metrics.total_any_count = $total_any | 
    .type_safety_metrics.files_with_any = $files_with_any | 
    .type_safety_metrics.type_coverage_estimate = $type_coverage' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Determine status and upstream analysis
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    STATUS="critical"
    EXIT_CODE=2
    UPSTREAM_BOX="Severe type safety degradation ($TOTAL_ANY_COUNT 'any' types) undermining TypeScript benefits"
    UPSTREAM_CLOSET="Missing type safety architecture with proper interfaces and strict enforcement"
    UPSTREAM_POLICY="Implement strict TypeScript configuration with 'any' type elimination strategy"
elif [[ $WARNING_ISSUES -gt 0 ]] || [[ $TOTAL_ANY_COUNT -gt $MAX_ANY_TYPES ]]; then
    STATUS="warn"
    EXIT_CODE=1
    UPSTREAM_BOX="Moderate type safety issues ($TOTAL_ANY_COUNT 'any' types) reducing development confidence"
    UPSTREAM_CLOSET="Type system architecture needs strengthening with better interface definitions"
    UPSTREAM_POLICY="Gradual 'any' type elimination with proper interface replacement strategy"
else
    STATUS="pass"
    EXIT_CODE=0
    UPSTREAM_BOX="Good type safety practices with minimal 'any' usage"
    UPSTREAM_CLOSET="Strong TypeScript architecture with proper type definitions"
    UPSTREAM_POLICY="Maintain type safety discipline through continued monitoring"
fi

# Update upstream analysis
jq --arg status "$STATUS" \
   --arg box "$UPSTREAM_BOX" \
   --arg closet "$UPSTREAM_CLOSET" \
   --arg policy "$UPSTREAM_POLICY" \
   '.status = $status | 
    .upstream_analysis.box = $box | 
    .upstream_analysis.closet = $closet | 
    .upstream_analysis.policy = $policy' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Generate type safety recommendations
RECOMMENDATIONS=()

if [[ $TOTAL_ANY_COUNT -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Replace 'any' types with proper interface definitions"
        "Create type definitions for external libraries using DefinitelyTyped"
        "Use generic types <T> instead of 'any' for reusable components"
        "Implement unknown type for truly dynamic content, then narrow with type guards"
    )
fi

if [[ ! "$STRICT_MODE_ENABLED" == "true" ]]; then
    RECOMMENDATIONS+=(
        "Enable strict mode in tsconfig.json for better type checking"
        "Add noImplicitAny: true to catch implicit any usage"
        "Enable strictNullChecks for better null safety"
    )
fi

if [[ $TOTAL_ANY_COUNT -gt 20 ]]; then
    RECOMMENDATIONS+=(
        "Prioritize 'any' elimination in critical business logic files"
        "Create migration plan: utilities → components → pages"
        "Use TypeScript compiler with --noImplicitAny flag during development"
        "Implement type safety metrics in CI/CD pipeline"
    )
fi

# Universal type safety recommendations
RECOMMENDATIONS+=(
    "Use type assertion sparingly, prefer type guards and narrowing"
    "Define proper return types for all functions, especially async ones"
    "Create domain-specific types for business logic (User, Product, etc.)"
    "Use const assertions for literal types: 'as const'"
    "Implement discriminated unions for state management"
)

# Convert recommendations to JSON and update report
RECOMMENDATIONS_JSON=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
jq --argjson recs "$RECOMMENDATIONS_JSON" '.recommendations = $recs' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Build remediation plan (top offending files)
if [[ ${#ANY_INSTANCES[@]} -gt 0 ]]; then
    PLAN=$(printf '%s\n' "${ANY_INSTANCES[@]}" | cut -d: -f1 | sort | uniq -c | sort -nr | head -15 | awk '{print $2":"$1}')
    PLAN_JSON=$(printf '%s\n' "$PLAN" | jq -R 'split(":") | {file:.[0], anyCount:(.[1]|tonumber)}' | jq -s .)
    jq --argjson plan "$PLAN_JSON" '.findings.remediation_plan=$plan' "$REPORT_FILE" > "$REPORT_FILE.tmp" && mv "$REPORT_FILE.tmp" "$REPORT_FILE"
fi

echo ""
echo "Type Safety Analysis Summary:"
echo "============================"
echo "Issues: $(($CRITICAL_ISSUES + $WARNING_ISSUES))"
echo "Critical: $CRITICAL_ISSUES"
echo "Warning: $WARNING_ISSUES"
echo "Type Coverage: $TYPE_COVERAGE%"
echo "Status: $STATUS"
echo "Report: $REPORT_FILE"

if [[ $TOTAL_ANY_COUNT -gt 0 ]]; then
    echo ""
    echo "💡 UPSTREAM-CURIOUS TYPE SAFETY STRATEGY:"
    echo "Class Problem: 'any' type usage degrades TypeScript benefits and development experience"
    echo "Upstream Fix: Systematic type definition creation with strict enforcement"
    echo ""
    echo "Type Replacement Patterns:"
    echo "• any → proper interface definitions"
    echo "• any[] → Array<SpecificType> or readonly SpecificType[]"
    echo "• Record<string, any> → Record<string, KnownType>"
    echo "• as any → type guards with narrowing"
    echo "• unknown + type guards for truly dynamic content"
    echo ""
    echo "Example Transformation:"
    echo "// Before: const data: any = fetchData();"
    echo "// After: interface ApiResponse { id: number; name: string; }"
    echo "//        const data: ApiResponse = fetchData();"
    echo ""
fi

if [[ $EXIT_CODE -eq 2 ]]; then
    echo "❌ type_safety: critical issues"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠ type_safety: issues found"
else
    echo "✅ type_safety: passed"
fi

exit $EXIT_CODE
