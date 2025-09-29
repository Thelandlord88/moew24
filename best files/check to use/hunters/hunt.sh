#!/usr/bin/env bash
# hunt.sh — Modular Hunter Orchestrator (Upstream-Curious Architecture)
#
# PURPOSE: Orchestrate specialized hunter modules for comprehensive codebase analysis
# ARCHITECTURE: Class-eliminating detection with proof invariants
#
# Box: Fragmented detection capabilities
# Closet: Unified hunter orchestration with modular detectors
# Policy: Each issue class has dedicated hunter + proof invariant

set -Eeuo pipefail
set +H  # Disable history expansion to prevent bash: !: event not found errors

# Global configuration
ROOT="."
WARN_ONLY=0
MAX_RESULTS=50
MODULES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-.}"; shift 2;;
    --warn-only) WARN_ONLY=1; shift;;
    --max-results) MAX_RESULTS="${2:-50}"; shift 2;;
    --modules) MODULES="$2"; shift 2;;
    --help) echo "Usage: $0 [--root PATH] [--warn-only] [--max-results N] [--modules list]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

# Normalize ROOT
ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

# Colors
if [[ -t 1 ]]; then
  BOLD='\e[1m'; RED='\e[31m'; YEL='\e[33m'; GRN='\e[32m'; CYA='\e[36m'; RST='\e[0m'
else
  BOLD=''; RED=''; YEL=''; GRN=''; CYA=''; RST=''
fi

section() { printf "\n${BOLD}== %s ==${RST}\n" "$1"; }
okay() { printf "${GRN}✓ %s${RST}\n" "$*"; }
warn() { printf "${YEL}⚠ %s${RST}\n" "$*"; }
fail() { printf "${RED}✗ %s${RST}\n" "$*"; }

# Environment setup
export TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
export REPORT_DIR="__reports/hunt"
mkdir -p "$REPORT_DIR"

# Define available hunter modules with priorities and categories
ALL_MODULES=(
  "environment_security"  # CRITICAL: Client-side env exposure
  "build_ssg_guard"       # CRITICAL: Early SSG classification & NoAdapterInstalled fast-fail
  "accessibility"         # CRITICAL: A11Y compliance
  "runtime_ssr"          # CRITICAL: SSR runtime failures
  "astro_server_surface" # CRITICAL: Server endpoint presence in static mode
  "server_surface_scan"  # CRITICAL: Hidden server surface (middleware/.server/onRequest) guard
  "security"             # HIGH: Security vulnerabilities
  "component_size"       # HIGH: Component architecture
  "image_optimization"   # HIGH: Asset optimization
  "css_architecture"     # HIGH: CSS architecture / baseline
  "type_safety"          # HIGH: TypeScript quality
  "ts_health"            # HIGH: Composite TS health
  "asset_weight"         # HIGH: Asset weight budget
  "ts_diagnostics"       # HIGH: Full TS compiler diagnostics
  "magic_numbers"        # MEDIUM: Constants management
  "performance"          # MEDIUM: Performance issues
  "code_quality"         # MEDIUM: Code quality metrics
  "build_dependencies"   # MEDIUM: Build/dependency issues
  "workspace_health"     # LOW: Workspace organization
  "repo_inventory_v2"    # ANALYSIS: Advanced repository inventory with import graphs
  "package_script_validation" # POLICY: Package.json script validation 
  "cleanup_reference_rot"     # POLICY: Cleanup reference validation
  "pattern_analysis"     # ANALYSIS: Pattern detection
  "schema_validator"     # ANALYSIS: Report schema enforcement (runs last)
  "generated_artifacts"  # ANALYSIS: Generated file integrity
  "health_index"         # ANALYSIS: Aggregate health score
)

# Hunter priority mapping for intelligent execution
declare -A HUNTER_PRIORITIES=(
  ["environment_security"]="critical"
  ["build_ssg_guard"]="critical"
  ["accessibility"]="critical"
  ["runtime_ssr"]="critical"
  ["astro_server_surface"]="critical"
  ["security"]="high"
  ["component_size"]="high"
  ["image_optimization"]="high"
  ["type_safety"]="high"
  ["ts_health"]="high"
  ["asset_weight"]="high"
  ["ts_diagnostics"]="high"
  ["magic_numbers"]="medium"
  ["performance"]="medium"
  ["code_quality"]="medium"
  ["build_dependencies"]="medium"
  ["workspace_health"]="low"
  ["pattern_analysis"]="analysis"
  ["schema_validator"]="analysis"
  ["generated_artifacts"]="analysis"
  ["health_index"]="analysis"
)

# Select modules to run
if [[ -n "$MODULES" ]]; then
  IFS=',' read -ra SELECTED_MODULES <<< "$MODULES"
else
  SELECTED_MODULES=("${ALL_MODULES[@]}")
fi

section "Hunter Thinker 2.0 Configuration"
okay "Root: $ROOT"
okay "Modules: ${SELECTED_MODULES[*]}"
okay "Report Directory: $REPORT_DIR"
okay "Upstream-Curious Methodology: Class elimination over instance fixing"

# Ensure report directory exists
mkdir -p "$REPORT_DIR"

# Initialize tracking
declare -A MODULE_STATUS
TOTAL_ISSUES=0
TOTAL_CRITICAL=0
CRITICAL_HUNTERS=()
WARNING_HUNTERS=()
PASSED_HUNTERS=()

section "Hunter v2 - Modular Architecture"
okay "timestamp: $TIMESTAMP"
okay "report_dir: $REPORT_DIR"
okay "modules: ${SELECTED_MODULES[*]}"

# Dependency validation
command -v rg >/dev/null 2>&1 || { fail "ripgrep (rg) required"; exit 2; }
command -v node >/dev/null 2>&1 || { fail "node required"; exit 2; }

# Initialize master report
MASTER_REPORT="$REPORT_DIR/master.json"
cat > "$MASTER_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "hunter_version": "2.0",
  "architecture": "modular",
  "modules_run": [],
  "summary": {
    "total_issues": 0,
    "total_critical": 0,
    "module_status": {}
  },
  "reports": {}
}
EOF

declare -i TOTAL_ISSUES=0
declare -i TOTAL_CRITICAL=0
declare -A MODULE_STATUS

# Execute hunter modules with priority-based coordination
section "Executing Hunter Modules (Priority-Based)"

# Sort modules by priority for intelligent execution order
PRIORITY_ORDER=("critical" "high" "medium" "low" "analysis")
ORDERED_MODULES=()

for priority in "${PRIORITY_ORDER[@]}"; do
  for module in "${SELECTED_MODULES[@]}"; do
    if [[ "${HUNTER_PRIORITIES[$module]:-medium}" == "$priority" ]]; then
      ORDERED_MODULES+=("$module")
    fi
  done
done

for module in "${ORDERED_MODULES[@]}"; do
  if [[ ! -f "hunters/${module}.sh" ]]; then
    warn "Module hunters/${module}.sh not found, skipping"
    continue
  fi
  
  module_priority="${HUNTER_PRIORITIES[$module]:-medium}"
  section "Running $module hunter ($module_priority priority)"
  
  # Execute module and capture exit code
  set +e
  bash "hunters/${module}.sh"
  MODULE_EXIT=$?
  set -e
  
  # Categorize results for Thinker analysis
  case $MODULE_EXIT in
    0) 
      MODULE_STATUS[$module]="pass"
      PASSED_HUNTERS+=("$module")
      okay "$module: passed"
      ;;
    1) 
      MODULE_STATUS[$module]="warn"
      WARNING_HUNTERS+=("$module")
      warn "$module: issues found"
      ;;
    2) 
      MODULE_STATUS[$module]="critical"
      CRITICAL_HUNTERS+=("$module")
      fail "$module: critical issues"
      ;;
    *) 
      MODULE_STATUS[$module]="error"
      WARNING_HUNTERS+=("$module")
      fail "$module: execution error"
      ;;
  esac
  
  # Parse module report for detailed metrics
  MODULE_REPORT="$REPORT_DIR/${module}.json"
  if [[ -f "$MODULE_REPORT" ]]; then
    # Extract issues counts using jq if available, fallback to node
    if command -v jq >/dev/null 2>&1; then
      MODULE_ISSUES=$(jq -r '.warning_issues // .issues // 0' "$MODULE_REPORT" 2>/dev/null || echo "0")
      MODULE_CRITICAL=$(jq -r '.critical_issues // .critical // 0' "$MODULE_REPORT" 2>/dev/null || echo "0")
    else
      MODULE_ISSUES=$(node -e "
        try {
          const r = require('./$MODULE_REPORT');
          console.log(r.warning_issues || r.issues || 0);
        } catch(e) { console.log(0); }
      " 2>/dev/null || echo "0")
      
      MODULE_CRITICAL=$(node -e "
        try {
          const r = require('./$MODULE_REPORT');
          console.log(r.critical_issues || r.critical || 0);
        } catch(e) { console.log(0); }
      " 2>/dev/null || echo "0")
    fi
    
    TOTAL_ISSUES=$((TOTAL_ISSUES + MODULE_ISSUES))
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + MODULE_CRITICAL))
  fi
done

# Execute Hunter Thinker 2.0 for synthesis and coordination
section "Hunter Thinker 2.0 Analysis & Synthesis"
if [[ -f "hunters/thinker.sh" ]]; then
  okay "Running Hunter Thinker for upstream-curious analysis..."
  
  # Set environment variables for Thinker context
  export HUNTER_CRITICAL_COUNT=${#CRITICAL_HUNTERS[@]}
  export HUNTER_WARNING_COUNT=${#WARNING_HUNTERS[@]}
  export HUNTER_PASSED_COUNT=${#PASSED_HUNTERS[@]}
  export HUNTER_CRITICAL_LIST="${CRITICAL_HUNTERS[*]}"
  export HUNTER_WARNING_LIST="${WARNING_HUNTERS[*]}"
  export HUNTER_PASSED_LIST="${PASSED_HUNTERS[*]}"
  
  set +e
  bash "hunters/thinker.sh"
  THINKER_EXIT=$?
  set -e
  
  case $THINKER_EXIT in
    0) okay "Thinker analysis: system healthy" ;;
    1) warn "Thinker analysis: systematic improvements needed" ;;
    2) fail "Thinker analysis: critical class problems identified" ;;
    *) warn "Thinker analysis: execution issues" ;;
  esac
  
  # Use Thinker's final assessment for overall exit code
  if [[ $THINKER_EXIT -gt 1 ]]; then
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + 1))
  fi
else
  warn "Hunter Thinker not found, using basic aggregation"
fi

# Aggregate final report with Thinker integration
section "Generating Master Report"

# Create comprehensive module status JSON
MODULE_STATUS_JSON="{"
first=true
for module in "${!MODULE_STATUS[@]}"; do
  if [[ "$first" == "true" ]]; then
    first=false
  else
    MODULE_STATUS_JSON+=","
  fi
  MODULE_STATUS_JSON+="\"$module\":\"${MODULE_STATUS[$module]}\""
done
MODULE_STATUS_JSON+="}"

# Create master report with Thinker integration
MASTER_REPORT="$REPORT_DIR/master.json"
cat > "$MASTER_REPORT" << EOF
{
  "hunter_system": {
    "version": "2.0_with_thinker",
    "timestamp": "$TIMESTAMP",
    "methodology": "upstream_curious_class_elimination",
    "execution_order": "priority_based"
  },
  "execution_summary": {
    "total_modules": ${#SELECTED_MODULES[@]},
    "critical_hunters": ${#CRITICAL_HUNTERS[@]},
    "warning_hunters": ${#WARNING_HUNTERS[@]},
    "passed_hunters": ${#PASSED_HUNTERS[@]},
    "total_issues": $TOTAL_ISSUES,
    "total_critical": $TOTAL_CRITICAL
  },
  "hunter_categories": {
    "critical_failures": [$(printf '"%s",' "${CRITICAL_HUNTERS[@]}" | sed 's/,$//')]${CRITICAL_HUNTERS:+],}${CRITICAL_HUNTERS:-]},
    "warning_issues": [$(printf '"%s",' "${WARNING_HUNTERS[@]}" | sed 's/,$//')]${WARNING_HUNTERS:+],}${WARNING_HUNTERS:-]},
    "passed_hunters": [$(printf '"%s",' "${PASSED_HUNTERS[@]}" | sed 's/,$//')]${PASSED_HUNTERS:+]${PASSED_HUNTERS:+}}${PASSED_HUNTERS:-]}
  },
  "module_status": $MODULE_STATUS_JSON,
  "reports": {
    "thinker_analysis": "$REPORT_DIR/thinker_analysis.json",
    "individual_hunters": {$(
for module in "${SELECTED_MODULES[@]}"; do
  if [[ -f "$REPORT_DIR/${module}.json" ]]; then
    echo "      \"$module\": \"$REPORT_DIR/${module}.json\","
  fi
done | sed 's/,$//'
)}
  },
  "upstream_curious_insights": {
    "problem_classes_detected": $(if [[ ${#CRITICAL_HUNTERS[@]} -gt 0 ]]; then echo "true"; else echo "false"; fi),
    "systematic_issues": $(if [[ ${#WARNING_HUNTERS[@]} -gt 0 ]]; then echo "true"; else echo "false"; fi),
    "health_score": $((${#PASSED_HUNTERS[@]} * 100 / ${#SELECTED_MODULES[@]}))
  }
}
EOF

okay "Master report generated: $MASTER_REPORT"

# Display individual reports
for module in "${SELECTED_MODULES[@]}"; do
  report_file="$REPORT_DIR/${module}.json"
  if [[ -f "$report_file" ]]; then
    okay "  $report_file"
  fi
done

# Display Thinker analysis if available
if [[ -f "$REPORT_DIR/thinker_analysis.json" ]]; then
  okay "  $REPORT_DIR/thinker_analysis.json (Upstream-Curious Analysis)"
fi
for module in "${SELECTED_MODULES[@]}"; do
  if [[ -n "${MODULE_STATUS[$module]:-}" ]]; then
    MODULE_STATUS_JSON="${MODULE_STATUS_JSON}\"$module\":\"${MODULE_STATUS[$module]}\","
  fi
done
MODULE_STATUS_JSON="${MODULE_STATUS_JSON%,}}"

# Update master report
cat > "$MASTER_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "hunter_version": "2.0",
  "architecture": "modular",
  "modules_run": [$(printf '"%s",' "${SELECTED_MODULES[@]}" | sed 's/,$//')],
  "summary": {
    "total_issues": $TOTAL_ISSUES,
    "total_critical": $TOTAL_CRITICAL,
    "module_status": $MODULE_STATUS_JSON
  },
  "policy_invariants": {
    "no_adapter_installed": "$(if [[ -f "$REPORT_DIR/runtime_ssr.json" ]]; then node -e "console.log(require('./$REPORT_DIR/runtime_ssr.json').findings.build_test || 'UNKNOWN')"; else echo "NOT_TESTED"; fi)",
    "security_scan": "$(if [[ -f "$REPORT_DIR/security.json" ]]; then echo "COMPLETED"; else echo "SKIPPED"; fi)",
  "accessibility_check": "$(if [[ -f "$REPORT_DIR/accessibility.json" ]]; then echo "COMPLETED"; else echo "SKIPPED"; fi)",
  "workspace_health": "$(if [[ -f "$REPORT_DIR/workspace_health.json" ]]; then echo "COMPLETED"; else echo "SKIPPED"; fi)"
  }
}
EOF

# Executive summary
section "Executive Summary"
printf "${BOLD}Total Issues:${RST} %d\n" "$TOTAL_ISSUES"
printf "${BOLD}Critical Issues:${RST} %d\n" "$TOTAL_CRITICAL"
printf "${BOLD}Modules Run:${RST} %s\n" "${#SELECTED_MODULES[@]}"

echo
echo "Module Status:"
for module in "${SELECTED_MODULES[@]}"; do
  status="${MODULE_STATUS[$module]:-unknown}"
  case "$status" in
    pass) printf "  ${GRN}✓${RST} %s: clean\n" "$module" ;;
    warn) printf "  ${YEL}⚠${RST} %s: issues\n" "$module" ;;
    critical) printf "  ${RED}✗${RST} %s: critical\n" "$module" ;;
    *) printf "  ${RED}?${RST} %s: %s\n" "$module" "$status" ;;
  esac
done

echo
echo "Reports Generated:"
for module in "${SELECTED_MODULES[@]}"; do
  report_file="$REPORT_DIR/${module}.json"
  if [[ -f "$report_file" ]]; then
    okay "  $report_file"
  fi
done
okay "  $MASTER_REPORT"

# Policy invariant validation with upstream-curious analysis
section "Policy Invariants & Class Prevention"
INVARIANT_FAILURES=0

# Environment Security Invariant
if [[ -f "$REPORT_DIR/environment_security.json" ]]; then
  ENV_CRITICAL=$(jq -r '.critical_issues // 0' "$REPORT_DIR/environment_security.json" 2>/dev/null || echo "0")
  if [[ "$ENV_CRITICAL" -gt 0 ]]; then
    fail "INVARIANT VIOLATION: Client-side environment variable exposure detected"
    ((INVARIANT_FAILURES++))
  else
    okay "Environment security boundary: ENFORCED"
  fi
fi

# Component Size Invariant
if [[ -f "$REPORT_DIR/component_size.json" ]]; then
  COMPONENT_CRITICAL=$(jq -r '.critical_issues // 0' "$REPORT_DIR/component_size.json" 2>/dev/null || echo "0")
  if [[ "$COMPONENT_CRITICAL" -gt 0 ]]; then
    fail "INVARIANT VIOLATION: Severely oversized components detected"
    ((INVARIANT_FAILURES++))
  else
    okay "Component size discipline: MAINTAINED"
  fi
fi

# Type Safety Invariant  
if [[ -f "$REPORT_DIR/type_safety.json" ]]; then
  TYPE_CRITICAL=$(jq -r '.critical_issues // 0' "$REPORT_DIR/type_safety.json" 2>/dev/null || echo "0")
  if [[ "$TYPE_CRITICAL" -gt 0 ]]; then
    fail "INVARIANT VIOLATION: Severe type safety degradation detected"
    ((INVARIANT_FAILURES++))
  else
    okay "Type safety standards: UPHELD"
  fi
fi

# Accessibility Invariant
if [[ -f "$REPORT_DIR/accessibility.json" ]]; then
  A11Y_CRITICAL=$(jq -r '.critical_issues // 0' "$REPORT_DIR/accessibility.json" 2>/dev/null || echo "0")
  if [[ "$A11Y_CRITICAL" -gt 0 ]]; then
    fail "INVARIANT VIOLATION: Critical accessibility barriers detected"
    ((INVARIANT_FAILURES++))
  else
    okay "Accessibility compliance: VERIFIED"
  fi
fi

# Legacy SSR Invariant (NoAdapterInstalled)
if [[ -f "$REPORT_DIR/runtime_ssr.json" ]]; then
  SSR_BUILD_TEST=$(jq -r '.findings.build_test // "UNKNOWN"' "$REPORT_DIR/runtime_ssr.json" 2>/dev/null || echo "UNKNOWN")
  if [[ "$SSR_BUILD_TEST" == "FAILED" ]]; then
    fail "INVARIANT VIOLATION: NoAdapterInstalled error detected"
    ((INVARIANT_FAILURES++))
  else
    okay "SSR runtime stability: CONFIRMED"
  fi
fi

# Calculate system health score
SYSTEM_HEALTH=$(( (${#PASSED_HUNTERS[@]} * 100) / ${#SELECTED_MODULES[@]} ))

section "Hunter Thinker 2.0 Final Assessment"
if [[ -f "$REPORT_DIR/thinker_analysis.json" ]]; then
  THINKER_SUMMARY=$(jq -r '.communication.executive_summary // "Thinker analysis complete"' "$REPORT_DIR/thinker_analysis.json" 2>/dev/null || echo "Thinker analysis complete")
  okay "Thinker Insight: $THINKER_SUMMARY"
  
  PROBLEM_CLASSES=$(jq -r '.upstream_synthesis.problem_classes_identified | length' "$REPORT_DIR/thinker_analysis.json" 2>/dev/null || echo "0")
  if [[ "$PROBLEM_CLASSES" -gt 0 ]]; then
    warn "Problem classes identified: $PROBLEM_CLASSES (requires upstream-curious solutions)"
  else
    okay "No systematic problem classes detected"
  fi
fi

# Overall exit determination with upstream-curious priority
OVERALL_EXIT=0
if (( TOTAL_CRITICAL > 0 || INVARIANT_FAILURES > 0 )); then
  if (( WARN_ONLY == 1 )); then
    warn "Hunter found critical issues (warn-only mode)"
    OVERALL_EXIT=0
  else
    fail "Hunter failed with critical issues requiring upstream-curious solutions"
    OVERALL_EXIT=2
  fi
elif (( TOTAL_ISSUES > 0 )); then
  warn "Hunter found systematic issues for gradual improvement"
  OVERALL_EXIT=1
else
  okay "Hunter clean - all class prevention invariants maintained"
  OVERALL_EXIT=0
fi

echo
echo "🧠 Hunter Thinker 2.0 Complete"
echo "System Health Score: $SYSTEM_HEALTH%"
echo "Critical Hunters: ${#CRITICAL_HUNTERS[@]} | Warning: ${#WARNING_HUNTERS[@]} | Passed: ${#PASSED_HUNTERS[@]}"
echo "Master Report: $MASTER_REPORT"
if [[ -f "$REPORT_DIR/thinker_analysis.json" ]]; then
  echo "Thinker Analysis: $REPORT_DIR/thinker_analysis.json"
fi
echo ""
echo "🎯 Next: Review Thinker analysis for upstream-curious problem solving"

exit $OVERALL_EXIT
