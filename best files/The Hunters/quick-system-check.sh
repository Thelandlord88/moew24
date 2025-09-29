#!/bin/bash
# Quick Hunter/NEXUS System Check
# Shell-integration-safe diagnostic

set -euo pipefail
cd "$(dirname "$0")" || exit 1

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'

echo -e "${CYAN}🔍 HUNTER/NEXUS QUICK SYSTEM CHECK${NC}"
echo "================================="
echo "Timestamp: $(date)"
echo ""

# Test 1: Count Hunter Modules
echo -e "${PURPLE}📊 Hunter Module Status${NC}"
hunter_count=$(find hunters -name "*.sh" -not -name "_*.sh" | wc -l)
echo -e "  Total hunter modules: ${GREEN}$hunter_count${NC}"

# List first 10 hunters
echo -e "  Available hunters:"
ls -1 hunters/*.sh | head -10 | sed 's|hunters/||g' | sed 's|\.sh$||g' | while read hunter; do
    echo -e "    ✅ $hunter"
done

echo ""

# Test 2: NEXUS Integration
echo -e "${PURPLE}🧠 NEXUS Integration${NC}"

nexus_files=$(find nexus -name "*.mjs" 2>/dev/null | wc -l)
echo -e "  NEXUS files: ${GREEN}$nexus_files${NC}"

if command -v node >/dev/null 2>&1; then
    echo -e "  Node.js: ${GREEN}✅ Available${NC} ($(node --version))"
    
    # Quick NEXUS test with timeout
    echo -e "  Testing NEXUS bridge..."
    if timeout 3s node -e "
        import('./nexus/nexus-bridge.mjs')
        .then(() => console.log('✅ NEXUS bridge OK'))
        .catch(e => console.log('❌ NEXUS error:', e.message))
    " 2>/dev/null; then
        echo -e "  ${GREEN}NEXUS bridge test completed${NC}"
    else
        echo -e "  ${YELLOW}NEXUS bridge test timed out${NC}"
    fi
else
    echo -e "  Node.js: ${RED}❌ Not available${NC}"
fi

echo ""

# Test 3: Shell Environment
echo -e "${PURPLE}🐚 Shell Environment${NC}"
echo -e "  Shell: $SHELL"
echo -e "  Terminal: $TERM"
echo -e "  VS Code: ${TERM_PROGRAM:-not detected}"

if [[ -f ".hunter-env.sh" ]]; then
    echo -e "  Hunter environment: ${GREEN}✅ Available${NC}"
else
    echo -e "  Hunter environment: ${RED}❌ Missing${NC}"
fi

echo ""

# Test 4: Coverage Check
echo -e "${PURPLE}📈 Key Coverage Areas${NC}"

key_modules=("security" "performance" "code_quality" "accessibility" "build_dependencies")
for module in "${key_modules[@]}"; do
    if [[ -f "hunters/${module}.sh" ]]; then
        echo -e "  ✅ ${GREEN}$module${NC}"
    else
        echo -e "  ❌ ${RED}$module${NC} (missing)"
    fi
done

echo ""

# Test 5: Identify Missing Hunters
echo -e "${PURPLE}💡 Recommended New Hunters${NC}"
missing_hunters=(
    "lighthouse_audit:Automated Lighthouse performance audits"
    "dependency_scan:NPM vulnerability scanning" 
    "cors_validation:CORS policy validation"
    "ssl_check:SSL certificate validation"
    "bundle_analysis:JavaScript bundle analysis"
    "seo_validation:SEO meta tags and structure"
)

for missing in "${missing_hunters[@]}"; do
    hunter_name="${missing%%:*}"
    description="${missing#*:}"
    echo -e "  💡 ${CYAN}${hunter_name}${NC}: $description"
done

echo ""
echo -e "${GREEN}✅ Quick System Check Complete${NC}"

# Create summary report
REPORT_DIR="__reports/system_health"
mkdir -p "$REPORT_DIR"
REPORT="${REPORT_DIR}/quick_check_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "HUNTER/NEXUS System Summary - $(date)"
    echo "======================================"
    echo "Hunter modules: $hunter_count"
    echo "NEXUS files: $nexus_files" 
    echo "Node.js: $(command -v node >/dev/null && echo "Available" || echo "Missing")"
    echo "Shell environment: $(test -f .hunter-env.sh && echo "Ready" || echo "Missing")"
    echo ""
    echo "Key modules status:"
    for module in "${key_modules[@]}"; do
        status=$(test -f "hunters/${module}.sh" && echo "✅" || echo "❌")
        echo "  $status $module"
    done
} > "$REPORT"

echo -e "${BLUE}Report saved to: $REPORT${NC}"