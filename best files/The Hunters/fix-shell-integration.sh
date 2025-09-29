#!/bin/bash
# Hunter/NEXUS Shell Integration Fix
# Addresses VS Code shell integration issues affecting Hunter system

set -euo pipefail

# Color codes (compatible with various terminal environments)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0)
else
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' NC=''
fi

echo "${CYAN}🔧 HUNTER/NEXUS SHELL INTEGRATION FIX${NC}"
echo "======================================"

# Fix 1: Simplify shell environment for Hunter scripts
fix_shell_environment() {
    echo "${PURPLE}🔧 Fixing Shell Environment${NC}"
    
    # Create a simplified shell environment file for hunters
    cat > .hunter-env.sh <<'EOF'
#!/bin/bash
# Simplified shell environment for Hunter scripts
# Fixes VS Code shell integration issues

# Disable problematic bash features
set +H  # Disable history expansion
unset HISTFILE  # Disable history file

# Simplify PATH and clean environment
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fix terminal settings for better script compatibility
export TERM="${TERM:-xterm}"
export SHELL="/bin/bash"

# Disable complex prompt for scripts
export PS1='$ '

# Function to source this in hunter scripts
setup_hunter_env() {
    # Disable job control in non-interactive shells
    set +m
    
    # Ensure clean working directory
    cd "${BASH_SOURCE%/*}/.." 2>/dev/null || cd "$(dirname "$0")/.." || true
    
    # Set consistent locale
    export LC_ALL=C
    export LANG=C
}

# Export the function
export -f setup_hunter_env
EOF
    
    chmod +x .hunter-env.sh
    echo "  ✅ Created .hunter-env.sh"
}

# Fix 2: Update hunter scripts to use clean shell environment
fix_hunter_scripts() {
    echo "${PURPLE}🔧 Updating Hunter Scripts${NC}"
    
    # Find all hunter scripts that need shell integration fixes
    local scripts_fixed=0
    
    for hunter_script in hunters/*.sh; do
        if [[ -f "$hunter_script" && "$(basename "$hunter_script")" != "_common.sh" ]]; then
            # Check if script already has shell integration fix
            if ! grep -q "setup_hunter_env" "$hunter_script" 2>/dev/null; then
                # Backup original
                cp "$hunter_script" "${hunter_script}.backup"
                
                # Insert shell environment setup after shebang
                {
                    head -n 1 "$hunter_script"  # Keep shebang
                    echo "# Shell integration fix - source clean environment"
                    echo "source \"\$(dirname \"\$0\")/../.hunter-env.sh\" && setup_hunter_env 2>/dev/null || true"
                    tail -n +2 "$hunter_script"  # Rest of the file
                } > "${hunter_script}.tmp" && mv "${hunter_script}.tmp" "$hunter_script"
                
                ((scripts_fixed++))
                echo "  ✅ Fixed $(basename "$hunter_script")"
            fi
        fi
    done
    
    echo "  📊 Fixed $scripts_fixed hunter scripts"
}

# Fix 3: Create shell-integration-aware wrapper scripts
create_wrapper_scripts() {
    echo "${PURPLE}🔧 Creating Wrapper Scripts${NC}"
    
    # Create a robust hunt wrapper
    cat > hunt-shell-safe.sh <<'EOF'
#!/bin/bash
# Shell-integration-safe hunter wrapper
# Usage: ./hunt-shell-safe.sh [module] [args...]

# Clean environment setup
export BASH_COMPAT=4.4
set +H
unset HISTFILE
export PS1='$ '

# Ensure we're in the right directory
cd "$(dirname "$0")" || exit 1

# Source clean environment
source .hunter-env.sh && setup_hunter_env

# Run hunter with clean environment
MODULE="${1:-security}"
shift || true

echo "🔍 Running hunter module: $MODULE"
echo "Arguments: $*"

# Execute hunter in clean subshell
(
    export REPORT_DIR="__reports/hunt"
    export TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
    mkdir -p "$REPORT_DIR"
    
    if [[ -f "hunters/${MODULE}.sh" ]]; then
        bash "hunters/${MODULE}.sh" "$@"
    else
        echo "❌ Hunter module not found: $MODULE"
        echo "Available modules:"
        ls -1 hunters/*.sh | sed 's|hunters/||g' | sed 's|\.sh$||g' | grep -v '^_' || true
        exit 1
    fi
)
EOF
    
    chmod +x hunt-shell-safe.sh
    echo "  ✅ Created hunt-shell-safe.sh"
    
    # Create NEXUS-aware wrapper
    cat > nexus-shell-safe.sh <<'EOF'
#!/bin/bash
# Shell-integration-safe NEXUS wrapper

# Clean environment setup
export BASH_COMPAT=4.4
set +H
unset HISTFILE
export PS1='$ '

cd "$(dirname "$0")" || exit 1
source .hunter-env.sh && setup_hunter_env

# Test NEXUS integration
echo "🧠 Testing NEXUS Integration (shell-safe mode)"

# Use timeout to prevent hanging
timeout 10s node -e "
console.log('Testing NEXUS bridge...');
import('./nexus/nexus-bridge.mjs')
  .then(() => console.log('✅ NEXUS bridge functional'))
  .catch(err => {
    console.log('❌ NEXUS bridge error:', err.message);
    process.exit(1);
  });
" 2>/dev/null || echo "⚠️  NEXUS bridge test timed out or failed"

# Test consciousness bridge
timeout 10s node -e "
console.log('Testing consciousness bridge...');
import('./hunters/consciousness-bridge.mjs')
  .then(() => console.log('✅ Consciousness bridge functional'))
  .catch(err => {
    console.log('❌ Consciousness bridge error:', err.message);
    process.exit(1);
  });
" 2>/dev/null || echo "⚠️  Consciousness bridge test timed out or failed"
EOF
    
    chmod +x nexus-shell-safe.sh
    echo "  ✅ Created nexus-shell-safe.sh"
}

# Fix 4: Enhanced diagnostic script that handles shell issues
create_enhanced_diagnostic() {
    echo "${PURPLE}🔧 Creating Enhanced Diagnostic${NC}"
    
    cat > system-diagnostic-shell-safe.sh <<'EOF'
#!/bin/bash
# Shell-integration-safe system diagnostic
# Comprehensive Hunter/NEXUS system analysis

# Clean shell environment
export BASH_COMPAT=4.4
set +H
unset HISTFILE
export PS1='$ '
set -euo pipefail

cd "$(dirname "$0")" || exit 1

# Colors (terminal-safe)
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'

echo -e "${CYAN}🔍 HUNTER/NEXUS SYSTEM DIAGNOSTIC (Shell-Safe)${NC}"
echo "================================================="
echo "Timestamp: $(date)"
echo ""

REPORT_DIR="__reports/system_health"
mkdir -p "$REPORT_DIR"
REPORT="${REPORT_DIR}/diagnostic_$(date +%Y%m%d_%H%M%S).txt"

exec > >(tee "$REPORT") 2>&1

# Test 1: Hunter Module Inventory
echo -e "${PURPLE}📊 Hunter Module Inventory${NC}"
echo "=========================="

hunter_count=0
functional_count=0
broken_count=0

for hunter in hunters/*.sh; do
    if [[ -f "$hunter" ]]; then
        module_name=$(basename "$hunter" .sh)
        
        # Skip common utilities
        if [[ "$module_name" == "_common" ]]; then
            continue
        fi
        
        ((hunter_count++))
        
        # Test syntax
        if bash -n "$hunter" 2>/dev/null; then
            ((functional_count++))
            echo -e "  ✅ ${GREEN}$module_name${NC}: syntax OK"
        else
            ((broken_count++))
            echo -e "  ❌ ${RED}$module_name${NC}: syntax error"
        fi
    fi
done

echo ""
echo -e "📊 Hunter Summary:"
echo -e "  Total: $hunter_count"
echo -e "  Functional: ${GREEN}$functional_count${NC}"
echo -e "  Broken: ${RED}$broken_count${NC}"
echo ""

# Test 2: NEXUS Integration
echo -e "${PURPLE}🧠 NEXUS Integration Test${NC}"
echo "========================"

# Test NEXUS files exist
nexus_files=$(find nexus -name "*.mjs" 2>/dev/null | wc -l)
echo -e "  📁 NEXUS files found: $nexus_files"

# Test Node.js availability
if command -v node >/dev/null 2>&1; then
    echo -e "  ✅ ${GREEN}Node.js available${NC}: $(node --version)"
    
    # Test NEXUS bridge (with timeout)
    echo -e "  🔍 Testing NEXUS bridge..."
    if timeout 5s node -e "import('./nexus/nexus-bridge.mjs').then(() => console.log('NEXUS-OK'))" 2>/dev/null | grep -q "NEXUS-OK"; then
        echo -e "    ✅ ${GREEN}NEXUS bridge functional${NC}"
    else
        echo -e "    ⚠️  ${YELLOW}NEXUS bridge test failed/timeout${NC}"
    fi
    
    # Test consciousness bridge
    echo -e "  🔍 Testing consciousness bridge..."
    if timeout 5s node -e "import('./hunters/consciousness-bridge.mjs').then(() => console.log('CONSCIOUSNESS-OK'))" 2>/dev/null | grep -q "CONSCIOUSNESS-OK"; then
        echo -e "    ✅ ${GREEN}Consciousness bridge functional${NC}"
    else
        echo -e "    ⚠️  ${YELLOW}Consciousness bridge test failed/timeout${NC}"
    fi
else
    echo -e "  ❌ ${RED}Node.js not available${NC}"
fi
echo ""

# Test 3: System Coverage Analysis
echo -e "${PURPLE}📈 System Coverage Analysis${NC}"
echo "==========================="

declare -A coverage_areas=(
    ["Security"]="security environment_security"
    ["Performance"]="performance perf_budget asset_weight"
    ["Quality"]="code_quality ts_health type_safety"
    ["Architecture"]="css_architecture component_size"
    ["Content"]="content_integrity geo_consistency"
    ["Dependencies"]="build_dependencies package_script_validation"
)

for area in "${!coverage_areas[@]}"; do
    echo -e "  ${BLUE}$area Coverage:${NC}"
    modules="${coverage_areas[$area]}"
    covered=0
    total=0
    
    for module in $modules; do
        ((total++))
        if [[ -f "hunters/${module}.sh" ]]; then
            ((covered++))
            echo -e "    ✅ $module"
        else
            echo -e "    ❌ $module (missing)"
        fi
    done
    
    coverage_percent=$((covered * 100 / total))
    echo -e "    Coverage: ${coverage_percent}% ($covered/$total)"
    echo ""
done

# Test 4: Shell Integration Status
echo -e "${PURPLE}🐚 Shell Integration Status${NC}"
echo "=========================="
echo -e "  Shell: $SHELL"
echo -e "  Terminal: $TERM"
echo -e "  VS Code: ${TERM_PROGRAM:-not detected}"
echo -e "  History expansion: $(set +o | grep history || echo 'disabled')"
echo ""

# Recommendations
echo -e "${PURPLE}💡 Recommendations${NC}"
echo "================="
echo -e "  1. ${CYAN}Use hunt-shell-safe.sh for reliable hunter execution${NC}"
echo -e "  2. ${CYAN}Use nexus-shell-safe.sh for NEXUS testing${NC}"
echo -e "  3. ${CYAN}Check individual hunter logs in __reports/hunt/${NC}"
echo -e "  4. ${CYAN}Run 'source .hunter-env.sh && setup_hunter_env' before manual hunter execution${NC}"
echo ""

echo -e "${GREEN}✅ Diagnostic Complete${NC}"
echo -e "Report saved to: ${BLUE}$REPORT${NC}"
EOF
    
    chmod +x system-diagnostic-shell-safe.sh
    echo "  ✅ Created system-diagnostic-shell-safe.sh"
}

# Main execution
main() {
    echo "Starting shell integration fixes..."
    echo ""
    
    fix_shell_environment
    echo ""
    
    fix_hunter_scripts
    echo ""
    
    create_wrapper_scripts
    echo ""
    
    create_enhanced_diagnostic
    echo ""
    
    echo "${GREEN}🎉 Shell Integration Fix Complete!${NC}"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "  1. Run: ${CYAN}./system-diagnostic-shell-safe.sh${NC} for full system check"
    echo "  2. Use: ${CYAN}./hunt-shell-safe.sh [module]${NC} for reliable hunter execution"
    echo "  3. Use: ${CYAN}./nexus-shell-safe.sh${NC} for NEXUS integration testing"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi