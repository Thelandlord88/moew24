#!/bin/bash
# Component Size Hunter
# Enforces component size limits and detects bloat requiring decomposition
# Part of Hunter Thinker 2.0 System - Upstream-Curious Architecture Enforcement

set -euo pipefail
if [[ -f hunters/_common.sh ]]; then source hunters/_common.sh || true; fi

HUNTER_NAME="component_size"
REPORT_FILE="__reports/hunt/${HUNTER_NAME}.json"
MAX_LINES=200
CRITICAL_THRESHOLD=500
OVERRIDES_FILE=".config/component-size-overrides.json"
declare -A OVERRIDE_MAP
if [[ -f $OVERRIDES_FILE ]]; then
    while IFS=$'\t' read -r k v; do [[ -n "$k" ]] && OVERRIDE_MAP["$k"]=$v; done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$OVERRIDES_FILE" 2>/dev/null || echo "")
fi
WARNING_ISSUES=0
CRITICAL_ISSUES=0

echo "📏 COMPONENT SIZE HUNTER"
echo "======================="
echo "Upstream Focus: Eliminate component bloat through decomposition"
echo "Max Lines: $MAX_LINES (Critical: >$CRITICAL_THRESHOLD)"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize report structure
cat > "$REPORT_FILE" <<EOF
{ "module":"component_size","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"running","critical_issues":0,"warning_issues":0,"issues_total":0,"findings":{"oversized_components":[],"critical_components":[],"decomposition_candidates":[],"size_distribution":{}},"upstream_analysis":{"box":"","closet":"","policy":""},"recommendations":[],"policy_invariants":["findings.critical_components|length==0"] }
EOF

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# timestamp already set

echo "🔍 Analyzing component sizes..."

LARGE_COMPONENTS=()
CRITICAL_COMPONENTS=()
TOTAL_COMPONENTS=0
SIZE_STATS=()

# Analyze all Astro components
while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
        SIZE_STATS+=("$lines")
        
        relative_file=${file#./}
        
        EFFECTIVE_CRIT=${OVERRIDE_MAP[$relative_file]:-$CRITICAL_THRESHOLD}
        if [[ $lines -gt $EFFECTIVE_CRIT ]]; then
            echo "🚨 CRITICAL: $relative_file ($lines lines) - Requires immediate decomposition"
            CRITICAL_COMPONENTS+=("$relative_file:$lines")
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
        elif [[ $lines -gt $MAX_LINES ]]; then
            echo "⚠️  WARNING: $relative_file ($lines lines) - Consider decomposition"
            LARGE_COMPONENTS+=("$relative_file:$lines")
            WARNING_ISSUES=$((WARNING_ISSUES + 1))
        fi
    fi
done < <(find src/components -name "*.astro" -print0 2>/dev/null || true)

echo ""
echo "📊 Component Size Distribution:"
if [[ $TOTAL_COMPONENTS -gt 0 ]]; then
    # Calculate statistics
    TOTAL_LINES=$(printf '%s\n' "${SIZE_STATS[@]}" | awk '{sum+=$1} END {print sum}')
    AVG_LINES=$(echo "scale=1; $TOTAL_LINES / $TOTAL_COMPONENTS" | bc 2>/dev/null || echo "0")
    MAX_SIZE=$(printf '%s\n' "${SIZE_STATS[@]}" | sort -n | tail -1)
    MIN_SIZE=$(printf '%s\n' "${SIZE_STATS[@]}" | sort -n | head -1)
    
    echo "   Total Components: $TOTAL_COMPONENTS"
    echo "   Average Size: ${AVG_LINES} lines"
    echo "   Largest: ${MAX_SIZE} lines"
    echo "   Smallest: ${MIN_SIZE} lines"
    echo "   Over $MAX_LINES lines: $(($WARNING_ISSUES + $CRITICAL_ISSUES))"
    echo "   Critical (>$CRITICAL_THRESHOLD): $CRITICAL_ISSUES"
else
    echo "   No components found"
fi

echo ""
echo "🎯 Decomposition Recommendations:"

# Generate specific decomposition strategies
DECOMPOSITION_STRATEGIES=()
for component in "${CRITICAL_COMPONENTS[@]}"; do
    file=$(echo "$component" | cut -d: -f1)
    lines=$(echo "$component" | cut -d: -f2)
    
    case "$file" in
        *"QuoteForm"*)
            echo "   • $file → QuoteFormContainer + QuoteFormSteps + QuoteFormValidation + QuoteFormPricing"
            DECOMPOSITION_STRATEGIES+=("$file:Split into container, steps, validation, and pricing components")
            ;;
        *"Header"*)
            echo "   • $file → Navigation + Logo + UserActions + MobileMenu"
            DECOMPOSITION_STRATEGIES+=("$file:Split into navigation, logo, user actions, and mobile menu")
            ;;
        *"Layout"*)
            echo "   • $file → LayoutContainer + LayoutHeader + LayoutFooter + LayoutSidebar"
            DECOMPOSITION_STRATEGIES+=("$file:Split into container, header, footer, and sidebar components")
            ;;
        *)
            echo "   • $file → Extract reusable sub-components and use composition patterns"
            DECOMPOSITION_STRATEGIES+=("$file:Extract reusable sub-components using composition patterns")
            ;;
    esac
done

for component in "${LARGE_COMPONENTS[@]}"; do
    file=$(echo "$component" | cut -d: -f1)
    lines=$(echo "$component" | cut -d: -f2)
    echo "   • $file → Consider extracting 1-2 sub-components"
    DECOMPOSITION_STRATEGIES+=("$file:Extract 1-2 sub-components to reduce size")
done

# Update report with findings
OVERSIZED_JSON=$(printf '%s\n' "${LARGE_COMPONENTS[@]}" 2>/dev/null | jq -R 'split(":") | {file: .[0], lines: (.[1] | tonumber)}' | jq -s . || echo "[]")
CRITICAL_JSON=$(printf '%s\n' "${CRITICAL_COMPONENTS[@]}" 2>/dev/null | jq -R 'split(":") | {file: .[0], lines: (.[1] | tonumber)}' | jq -s . || echo "[]")

jq --argjson critical "$CRITICAL_ISSUES" --argjson warning "$WARNING_ISSUES" --argjson oversized "$OVERSIZED_JSON" --argjson critical_comps "$CRITICAL_JSON" '.critical_issues=$critical | .warning_issues=$warning | .issues_total=($critical+$warning) | .findings.oversized_components=$oversized | .findings.critical_components=$critical_comps' "$REPORT_FILE" > "$REPORT_FILE.tmp" && mv "$REPORT_FILE.tmp" "$REPORT_FILE"

# Determine status and upstream analysis
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    STATUS="critical"
    EXIT_CODE=2
    UPSTREAM_BOX="Components exceed critical size threshold ($CRITICAL_THRESHOLD+ lines)"
    UPSTREAM_CLOSET="Monolithic component architecture with poor separation of concerns"
    UPSTREAM_POLICY="Enforce component size limits with automated decomposition guidance"
elif [[ $WARNING_ISSUES -gt 0 ]]; then
    STATUS="warn"
    EXIT_CODE=1
    UPSTREAM_BOX="Components exceed recommended size threshold ($MAX_LINES+ lines)"
    UPSTREAM_CLOSET="Component organization lacks decomposition patterns"
    UPSTREAM_POLICY="Implement component size monitoring with decomposition recommendations"
else
    STATUS="pass"
    EXIT_CODE=0
    UPSTREAM_BOX="Component sizes within acceptable limits"
    UPSTREAM_CLOSET="Well-structured component architecture"
    UPSTREAM_POLICY="Maintain component size discipline through continuous monitoring"
fi

# Update upstream analysis
jq --arg status "$STATUS" --arg box "$UPSTREAM_BOX" --arg closet "$UPSTREAM_CLOSET" --arg policy "$UPSTREAM_POLICY" '.status=$status | .upstream_analysis.box=$box | .upstream_analysis.closet=$closet | .upstream_analysis.policy=$policy' "$REPORT_FILE" > "$REPORT_FILE.tmp" && mv "$REPORT_FILE.tmp" "$REPORT_FILE"

# Generate recommendations
RECOMMENDATIONS=()
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Immediately decompose critical components (>$CRITICAL_THRESHOLD lines)"
        "Use composition patterns: Container + Content + Actions"
        "Extract shared logic into utility functions"
        "Implement component size gates in CI/CD pipeline"
    )
fi

if [[ $WARNING_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Consider decomposing large components (>$MAX_LINES lines)"
        "Use slots and props for better component composition"
        "Extract reusable sub-components"
        "Document component architecture patterns"
    )
fi

RECOMMENDATIONS+=(
    "Set component size limits in development guidelines"
    "Use TypeScript interfaces for better component contracts"
    "Implement component composition patterns"
    "Regular architecture reviews for component design"
)

# Convert recommendations to JSON and update report
RECOMMENDATIONS_JSON=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
jq --argjson recs "$RECOMMENDATIONS_JSON" '.recommendations = $recs' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo ""
echo "Component Size Analysis Summary:"
echo "=============================="
echo "Issues: $(($CRITICAL_ISSUES + $WARNING_ISSUES))"
echo "Critical: $CRITICAL_ISSUES"
echo "Warning: $WARNING_ISSUES"
echo "Status: $STATUS"
echo "Report: $REPORT_FILE"

if [[ $CRITICAL_ISSUES -gt 0 ]] || [[ $WARNING_ISSUES -gt 0 ]]; then
    echo ""
    echo "💡 UPSTREAM-CURIOUS DECOMPOSITION STRATEGY:"
    echo "Class Problem: Monolithic components that violate single responsibility"
    echo "Upstream Fix: Component decomposition with composition patterns"
    echo ""
    echo "Composition Pattern Example:"
    echo "<!-- Instead of 874-line QuoteForm.astro -->"
    echo "<QuoteFormContainer>"
    echo "  <QuoteFormSteps />"
    echo "  <QuoteFormValidation />"
    echo "  <QuoteFormPricing />"
    echo "</QuoteFormContainer>"
    echo ""
fi

if [[ $EXIT_CODE -eq 2 ]]; then
    echo "❌ component_size: critical issues"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠ component_size: issues found"
else
    echo "✅ component_size: passed"
fi

exit $EXIT_CODE
