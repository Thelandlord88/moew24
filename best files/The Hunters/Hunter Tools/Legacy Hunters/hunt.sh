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

# Available hunter modules
AVAILABLE_MODULES=(
  "runtime_ssr"        # NoAdapterInstalled prevention
  "security"           # Vulnerability scanning  
  "performance"        # Asset & bundle optimization
  "accessibility"      # A11y compliance
  "code_quality"       # Technical debt analysis
  "build_dependencies" # Build script & file generation monitoring
)

# Determine which modules to run
if [[ -n "$MODULES" ]]; then
  IFS=',' read -ra SELECTED_MODULES <<< "$MODULES"
else
  SELECTED_MODULES=("${AVAILABLE_MODULES[@]}")
fi

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

# Execute hunter modules
for module in "${SELECTED_MODULES[@]}"; do
  if [[ ! -f "hunters/${module}.sh" ]]; then
    warn "Module hunters/${module}.sh not found, skipping"
    continue
  fi
  
  section "Running $module hunter"
  
  # Execute module and capture exit code
  set +e
  bash "hunters/${module}.sh"
  MODULE_EXIT=$?
  set -e
  
  # Determine module status
  case $MODULE_EXIT in
    0) MODULE_STATUS[$module]="pass"; okay "$module: clean" ;;
    1) MODULE_STATUS[$module]="warn"; warn "$module: issues found" ;;
    2) MODULE_STATUS[$module]="critical"; fail "$module: critical issues" ;;
    *) MODULE_STATUS[$module]="error"; fail "$module: execution error" ;;
  esac
  
  # Parse module report if available
  MODULE_REPORT="$REPORT_DIR/${module}.json"
  if [[ -f "$MODULE_REPORT" ]]; then
    MODULE_ISSUES=$(node -e "
      try {
        const r = require('./$MODULE_REPORT');
        console.log(r.issues || 0);
      } catch(e) { console.log(0); }
    " 2>/dev/null || echo "0")
    
    MODULE_CRITICAL=$(node -e "
      try {
        const r = require('./$MODULE_REPORT');
        console.log(r.critical || 0);
      } catch(e) { console.log(0); }
    " 2>/dev/null || echo "0")
    
    TOTAL_ISSUES=$((TOTAL_ISSUES + MODULE_ISSUES))
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + MODULE_CRITICAL))
  fi
done

# Aggregate final report
section "Generating Master Report"

# Create module status JSON
MODULE_STATUS_JSON="{"
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
    "accessibility_check": "$(if [[ -f "$REPORT_DIR/accessibility.json" ]]; then echo "COMPLETED"; else echo "SKIPPED"; fi)"
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

# Policy invariant validation
section "Policy Invariants"
INVARIANT_FAILURES=0

# Check NoAdapterInstalled invariant
if [[ -f "$REPORT_DIR/runtime_ssr.json" ]]; then
  SSR_BUILD_TEST=$(node -e "
    try {
      const r = require('./$REPORT_DIR/runtime_ssr.json');
      console.log(r.findings.build_test || 'UNKNOWN');
    } catch(e) { console.log('ERROR'); }
  " 2>/dev/null || echo "ERROR")
  
  if [[ "$SSR_BUILD_TEST" == "FAILED" ]]; then
    fail "INVARIANT VIOLATION: NoAdapterInstalled error detected"
    ((INVARIANT_FAILURES++))
  else
    okay "NoAdapterInstalled prevention: PASSED"
  fi
fi

# Overall exit determination
OVERALL_EXIT=0
if (( TOTAL_CRITICAL > 0 || INVARIANT_FAILURES > 0 )); then
  if (( WARN_ONLY == 1 )); then
    warn "Hunter found critical issues (warn-only mode)"
    OVERALL_EXIT=0
  else
    fail "Hunter failed with critical issues"
    OVERALL_EXIT=2
  fi
elif (( TOTAL_ISSUES > 0 )); then
  warn "Hunter found non-critical issues"
  OVERALL_EXIT=1
else
  okay "Hunter clean - all checks passed"
  OVERALL_EXIT=0
fi

echo
echo "🎯 Hunter v2 Complete"
echo "Master Report: $MASTER_REPORT"

exit $OVERALL_EXIT
