#!/bin/bash
# Hunter Thinker 2.0 - Master Coordinator & Communication System
# Orchestrates all hunters with upstream-curious analysis and synthesis
# Provides intelligent communication between hunters and human developers

set -euo pipefail

THINKER_VERSION="2.0"
MASTER_REPORT="__reports/hunt/master.json"
THINKER_REPORT="__reports/hunt/thinker_analysis.json"
TOTAL_CRITICAL=0
TOTAL_WARNING=0
TOTAL_PASSED=0
FAILED_HUNTERS=()
WARNING_HUNTERS=()
PASSED_HUNTERS=()

echo "🧠 HUNTER THINKER 2.0 - MASTER COORDINATOR"
echo "=========================================="
echo "Methodology: Upstream-Curious Pattern Analysis"
echo "Mission: Eliminate problem classes, not just instances"
echo "Version: $THINKER_VERSION"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize Thinker analysis report
cat > "$THINKER_REPORT" << 'EOF'
{
  "thinker": {
    "version": "2.0",
    "methodology": "upstream_curious",
    "mission": "class_elimination_over_instance_fixing",
    "timestamp": "",
    "analysis_scope": "complete_system"
  },
  "hunter_coordination": {
    "total_hunters": 0,
    "hunters_run": [],
    "critical_failures": [],
    "warning_issues": [],
    "passed_hunters": []
  },
  "upstream_synthesis": {
    "problem_classes_identified": [],
    "architectural_patterns": {},
    "system_health_score": 0,
    "elimination_opportunities": []
  },
  "intelligent_recommendations": {
    "immediate_critical": [],
    "systematic_improvements": [],
    "preventive_measures": [],
    "policy_updates": []
  },
  "communication": {
    "executive_summary": "",
    "developer_actions": [],
    "next_hunter_priorities": []
  }
}
EOF

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TIMESTAMP" '.thinker.timestamp = $ts' "$THINKER_REPORT" > "${THINKER_REPORT}.tmp" && mv "${THINKER_REPORT}.tmp" "$THINKER_REPORT"

echo "🔍 ORCHESTRATING HUNTER SYSTEM ANALYSIS..."
echo ""

# Define hunter modules with their priorities and relationships
declare -A HUNTERS=(
    ["environment_security"]="critical:security:client_env_exposure"
    ["accessibility"]="critical:ux:a11y_violations"
    ["runtime_ssr"]="critical:build:ssr_failures"
    ["security"]="high:security:general_vulnerabilities"
    ["component_size"]="high:architecture:component_bloat"
    ["image_optimization"]="high:performance:asset_optimization"
    ["performance"]="medium:performance:bundle_optimization"
    ["code_quality"]="medium:maintainability:code_smells"
    ["build_dependencies"]="medium:build:dependency_health"
    ["workspace_health"]="low:organization:workspace_hygiene"
    ["pattern_analysis"]="analysis:architecture:pattern_detection"
)

HUNTER_RESULTS=()
ANALYSIS_DATA=()

# Run each hunter and collect results
for hunter in "${!HUNTERS[@]}"; do
    hunter_info=${HUNTERS[$hunter]}
    priority=$(echo "$hunter_info" | cut -d: -f1)
    category=$(echo "$hunter_info" | cut -d: -f2)
    focus=$(echo "$hunter_info" | cut -d: -f3)
    
    hunter_script="hunters/${hunter}.sh"
    
    if [[ -f "$hunter_script" ]]; then
        echo "🔍 Running $hunter hunter ($priority priority)..."
        
        # Run hunter and capture exit code
        set +e
        bash "$hunter_script" > /tmp/hunter_${hunter}.log 2>&1
        exit_code=$?
        set -e
        
        # Analyze results
        case $exit_code in
            0)
                echo "✅ $hunter: passed"
                TOTAL_PASSED=$((TOTAL_PASSED + 1))
                PASSED_HUNTERS+=("$hunter")
                ;;
            1)
                echo "⚠️  $hunter: issues found"
                TOTAL_WARNING=$((TOTAL_WARNING + 1))
                WARNING_HUNTERS+=("$hunter")
                ;;
            2)
                echo "❌ $hunter: critical issues"
                TOTAL_CRITICAL=$((TOTAL_CRITICAL + 1))
                FAILED_HUNTERS+=("$hunter")
                ;;
            *)
                echo "❓ $hunter: unexpected exit code $exit_code"
                TOTAL_WARNING=$((TOTAL_WARNING + 1))
                WARNING_HUNTERS+=("$hunter")
                ;;
        esac
        
        # Collect hunter data for synthesis
        HUNTER_RESULTS+=("$hunter:$exit_code:$priority:$category:$focus")
        
        # Read hunter report if exists for deeper analysis
        hunter_report="__reports/hunt/${hunter}.json"
        if [[ -f "$hunter_report" ]]; then
            ANALYSIS_DATA+=("$hunter_report")
        fi
        
    else
        echo "⚠️  Hunter script not found: $hunter_script"
        WARNING_HUNTERS+=("$hunter")
        TOTAL_WARNING=$((TOTAL_WARNING + 1))
    fi
done

echo ""
echo "🧠 PERFORMING UPSTREAM-CURIOUS SYNTHESIS..."
echo ""

# Analyze patterns across hunter findings
PROBLEM_CLASSES=()
ARCHITECTURAL_INSIGHTS=()

# Security class analysis
if [[ " ${FAILED_HUNTERS[@]} " =~ " environment_security " ]] || [[ " ${FAILED_HUNTERS[@]} " =~ " security " ]]; then
    PROBLEM_CLASSES+=("security_boundary_violations")
    ARCHITECTURAL_INSIGHTS+=("Client/server boundary enforcement missing")
fi

# Component architecture analysis
if [[ " ${FAILED_HUNTERS[@]} " =~ " component_size " ]] || [[ " ${WARNING_HUNTERS[@]} " =~ " component_size " ]]; then
    PROBLEM_CLASSES+=("component_bloat_patterns")
    ARCHITECTURAL_INSIGHTS+=("Component decomposition patterns needed")
fi

# Performance class analysis  
if [[ " ${WARNING_HUNTERS[@]} " =~ " performance " ]] || [[ " ${WARNING_HUNTERS[@]} " =~ " image_optimization " ]]; then
    PROBLEM_CLASSES+=("performance_degradation_class")
    ARCHITECTURAL_INSIGHTS+=("Asset optimization pipeline required")
fi

# Accessibility class analysis
if [[ " ${FAILED_HUNTERS[@]} " =~ " accessibility " ]]; then
    PROBLEM_CLASSES+=("accessibility_violation_class")
    ARCHITECTURAL_INSIGHTS+=("A11Y enforcement in development workflow missing")
fi

# Calculate system health score (0-100)
TOTAL_HUNTERS=${#HUNTERS[@]}
HEALTH_SCORE=$(( (TOTAL_PASSED * 100) / TOTAL_HUNTERS ))

# Generate intelligent recommendations based on patterns
CRITICAL_RECOMMENDATIONS=()
SYSTEMATIC_RECOMMENDATIONS=()
PREVENTIVE_RECOMMENDATIONS=()

# Critical issues require immediate upstream fixes
if [[ $TOTAL_CRITICAL -gt 0 ]]; then
    for hunter in "${FAILED_HUNTERS[@]}"; do
        case "$hunter" in
            "environment_security")
                CRITICAL_RECOMMENDATIONS+=("Create server-side environment service with client boundary validation")
                CRITICAL_RECOMMENDATIONS+=("Implement TypeScript guards for environment variable access")
                ;;
            "accessibility")
                CRITICAL_RECOMMENDATIONS+=("Enforce alt text requirements through TypeScript interfaces")
                CRITICAL_RECOMMENDATIONS+=("Add accessibility validation to component development workflow")
                ;;
            "runtime_ssr")
                CRITICAL_RECOMMENDATIONS+=("Fix SSR configuration and adapter alignment issues")
                CRITICAL_RECOMMENDATIONS+=("Implement SSR validation hunter for continuous monitoring")
                ;;
        esac
    done
fi

# Systematic improvements for warning-level issues
for hunter in "${WARNING_HUNTERS[@]}"; do
    case "$hunter" in
        "component_size")
            SYSTEMATIC_RECOMMENDATIONS+=("Implement component decomposition patterns: Container→Content→Actions")
            SYSTEMATIC_RECOMMENDATIONS+=("Create component size limits in development tooling")
            ;;
        "performance")
            SYSTEMATIC_RECOMMENDATIONS+=("Establish asset optimization pipeline with WebP conversion")
            SYSTEMATIC_RECOMMENDATIONS+=("Implement bundle analysis and code splitting strategies")
            ;;
        "code_quality")
            SYSTEMATIC_RECOMMENDATIONS+=("Eliminate magic numbers through centralized constants system")
            SYSTEMATIC_RECOMMENDATIONS+=("Reduce 'any' type usage with proper TypeScript interfaces")
            ;;
    esac
done

# Preventive measures to avoid future problem classes
PREVENTIVE_RECOMMENDATIONS+=(
    "Integrate hunter system with CI/CD for continuous quality enforcement"
    "Establish policy-driven development with automated hunter gates"
    "Create developer education on upstream-curious problem solving"
    "Implement pattern detection and architectural guidance systems"
)

# Create executive summary for human communication
EXECUTIVE_SUMMARY=""
if [[ $TOTAL_CRITICAL -gt 0 ]]; then
    EXECUTIVE_SUMMARY="🚨 CRITICAL: $TOTAL_CRITICAL hunters failed with critical issues requiring immediate upstream-curious solutions. "
fi
if [[ $TOTAL_WARNING -gt 0 ]]; then
    EXECUTIVE_SUMMARY+="⚠️ $TOTAL_WARNING hunters found systematic issues for gradual improvement. "
fi
if [[ $TOTAL_PASSED -gt 0 ]]; then
    EXECUTIVE_SUMMARY+="✅ $TOTAL_PASSED hunters passed, indicating healthy architecture patterns. "
fi

EXECUTIVE_SUMMARY+="System Health: $HEALTH_SCORE%. "

if [[ ${#PROBLEM_CLASSES[@]} -gt 0 ]]; then
    EXECUTIVE_SUMMARY+="Problem classes identified: $(IFS=', '; echo "${PROBLEM_CLASSES[*]}"). "
fi

EXECUTIVE_SUMMARY+="Focus on class elimination over instance fixing for systematic improvement."

# Developer action priorities
DEVELOPER_ACTIONS=()
if [[ $TOTAL_CRITICAL -gt 0 ]]; then
    DEVELOPER_ACTIONS+=("URGENT: Address critical security/accessibility issues in failed hunters: $(IFS=', '; echo "${FAILED_HUNTERS[*]}")")
fi
if [[ $TOTAL_WARNING -gt 0 ]]; then
    DEVELOPER_ACTIONS+=("Systematic: Improve warning-level issues through pattern-based solutions")
fi
if [[ $HEALTH_SCORE -lt 70 ]]; then
    DEVELOPER_ACTIONS+=("Strategic: System health at $HEALTH_SCORE% requires architectural attention")
fi

# Next hunter priorities based on analysis
NEXT_HUNTER_PRIORITIES=()
if [[ " ${PROBLEM_CLASSES[@]} " =~ "security_boundary_violations" ]]; then
    NEXT_HUNTER_PRIORITIES+=("Enhance environment_security hunter with runtime boundary checks")
fi
if [[ " ${PROBLEM_CLASSES[@]} " =~ "component_bloat_patterns" ]]; then
    NEXT_HUNTER_PRIORITIES+=("Create component_decomposition hunter for automated refactoring guidance")
fi
if [[ " ${PROBLEM_CLASSES[@]} " =~ "performance_degradation_class" ]]; then
    NEXT_HUNTER_PRIORITIES+=("Implement performance_budget hunter with automated optimization")
fi

# Update Thinker analysis report with all findings
HUNTERS_RUN_JSON=$(printf '%s\n' "${!HUNTERS[@]}" | jq -R . | jq -s .)
CRITICAL_FAILURES_JSON=$(printf '%s\n' "${FAILED_HUNTERS[@]}" | jq -R . | jq -s .)
WARNING_ISSUES_JSON=$(printf '%s\n' "${WARNING_HUNTERS[@]}" | jq -R . | jq -s .)
PASSED_HUNTERS_JSON=$(printf '%s\n' "${PASSED_HUNTERS[@]}" | jq -R . | jq -s .)
PROBLEM_CLASSES_JSON=$(printf '%s\n' "${PROBLEM_CLASSES[@]}" | jq -R . | jq -s .)
CRITICAL_RECS_JSON=$(printf '%s\n' "${CRITICAL_RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
SYSTEMATIC_RECS_JSON=$(printf '%s\n' "${SYSTEMATIC_RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
PREVENTIVE_RECS_JSON=$(printf '%s\n' "${PREVENTIVE_RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
DEVELOPER_ACTIONS_JSON=$(printf '%s\n' "${DEVELOPER_ACTIONS[@]}" | jq -R . | jq -s .)
HUNTER_PRIORITIES_JSON=$(printf '%s\n' "${NEXT_HUNTER_PRIORITIES[@]}" | jq -R . | jq -s .)

jq --argjson total "$TOTAL_HUNTERS" \
   --argjson hunters_run "$HUNTERS_RUN_JSON" \
   --argjson critical_failures "$CRITICAL_FAILURES_JSON" \
   --argjson warning_issues "$WARNING_ISSUES_JSON" \
   --argjson passed_hunters "$PASSED_HUNTERS_JSON" \
   --argjson problem_classes "$PROBLEM_CLASSES_JSON" \
   --argjson health_score "$HEALTH_SCORE" \
   --argjson critical_recs "$CRITICAL_RECS_JSON" \
   --argjson systematic_recs "$SYSTEMATIC_RECS_JSON" \
   --argjson preventive_recs "$PREVENTIVE_RECS_JSON" \
   --arg executive_summary "$EXECUTIVE_SUMMARY" \
   --argjson developer_actions "$DEVELOPER_ACTIONS_JSON" \
   --argjson hunter_priorities "$HUNTER_PRIORITIES_JSON" \
   '.hunter_coordination.total_hunters = $total |
    .hunter_coordination.hunters_run = $hunters_run |
    .hunter_coordination.critical_failures = $critical_failures |
    .hunter_coordination.warning_issues = $warning_issues |
    .hunter_coordination.passed_hunters = $passed_hunters |
    .upstream_synthesis.problem_classes_identified = $problem_classes |
    .upstream_synthesis.system_health_score = $health_score |
    .intelligent_recommendations.immediate_critical = $critical_recs |
    .intelligent_recommendations.systematic_improvements = $systematic_recs |
    .intelligent_recommendations.preventive_measures = $preventive_recs |
    .communication.executive_summary = $executive_summary |
    .communication.developer_actions = $developer_actions |
    .communication.next_hunter_priorities = $hunter_priorities' \
   "$THINKER_REPORT" > "${THINKER_REPORT}.tmp" && mv "${THINKER_REPORT}.tmp" "$THINKER_REPORT"

# Generate master report summary
cat > "$MASTER_REPORT" << EOF
{
  "hunter_system": {
    "version": "2.0_with_thinker",
    "timestamp": "$TIMESTAMP",
    "methodology": "upstream_curious_class_elimination"
  },
  "summary": {
    "total_hunters": $TOTAL_HUNTERS,
    "critical_issues": $TOTAL_CRITICAL,
    "warning_issues": $TOTAL_WARNING,
    "passed_hunters": $TOTAL_PASSED,
    "system_health_score": $HEALTH_SCORE
  },
  "status": "$(if [[ $TOTAL_CRITICAL -gt 0 ]]; then echo "critical"; elif [[ $TOTAL_WARNING -gt 0 ]]; then echo "warn"; else echo "pass"; fi)",
  "problem_classes": $(printf '%s\n' "${PROBLEM_CLASSES[@]}" | jq -R . | jq -s .),
  "thinker_analysis": "$THINKER_REPORT",
  "individual_reports": {
$(for hunter in "${!HUNTERS[@]}"; do
    if [[ -f "__reports/hunt/${hunter}.json" ]]; then
        echo "    \"$hunter\": \"__reports/hunt/${hunter}.json\","
    fi
done | sed '$ s/,$//')
  }
}
EOF

echo ""
echo "🧠 HUNTER THINKER 2.0 ANALYSIS COMPLETE"
echo "======================================="
echo ""
echo "📊 SYSTEM OVERVIEW:"
echo "  Total Hunters: $TOTAL_HUNTERS"
echo "  Critical Issues: $TOTAL_CRITICAL"
echo "  Warning Issues: $TOTAL_WARNING"  
echo "  Passed: $TOTAL_PASSED"
echo "  System Health: $HEALTH_SCORE%"
echo ""

if [[ ${#PROBLEM_CLASSES[@]} -gt 0 ]]; then
    echo "🎯 PROBLEM CLASSES IDENTIFIED:"
    for class in "${PROBLEM_CLASSES[@]}"; do
        echo "  • $class"
    done
    echo ""
fi

if [[ ${#CRITICAL_RECOMMENDATIONS[@]} -gt 0 ]]; then
    echo "🚨 IMMEDIATE CRITICAL ACTIONS:"
    for rec in "${CRITICAL_RECOMMENDATIONS[@]}"; do
        echo "  • $rec"
    done
    echo ""
fi

if [[ ${#SYSTEMATIC_RECOMMENDATIONS[@]} -gt 0 ]]; then
    echo "📈 SYSTEMATIC IMPROVEMENTS:"
    for rec in "${SYSTEMATIC_RECOMMENDATIONS[@]:0:3}"; do
        echo "  • $rec"
    done
    if [[ ${#SYSTEMATIC_RECOMMENDATIONS[@]} -gt 3 ]]; then
        echo "  • ... and $((${#SYSTEMATIC_RECOMMENDATIONS[@]} - 3)) more (see full report)"
    fi
    echo ""
fi

echo "💡 UPSTREAM-CURIOUS INSIGHT:"
echo "$EXECUTIVE_SUMMARY"
echo ""

echo "📋 REPORTS GENERATED:"
echo "  Master Report: $MASTER_REPORT"
echo "  Thinker Analysis: $THINKER_REPORT"
echo "  Individual Hunter Reports: __reports/hunt/<hunter>.json"
echo ""

# Determine exit code based on most severe issues
if [[ $TOTAL_CRITICAL -gt 0 ]]; then
    echo "❌ Hunter Thinker 2.0: CRITICAL issues require immediate action"
    EXIT_CODE=2
elif [[ $TOTAL_WARNING -gt 0 ]]; then
    echo "⚠️  Hunter Thinker 2.0: Issues found, systematic improvement recommended"
    EXIT_CODE=1
else
    echo "✅ Hunter Thinker 2.0: All systems healthy"
    EXIT_CODE=0
fi

echo ""
echo "🎯 Next: Review $THINKER_REPORT for detailed upstream-curious analysis"

exit $EXIT_CODE
