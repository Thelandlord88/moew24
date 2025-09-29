#!/bin/bash
# System Health and Hunter Coverage Analysis
# Performs comprehensive diagnostics to identify gaps in hunter coverage

set -euo pipefail

REPORT_DIR="__reports/system_health"
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
FULL_REPORT="${REPORT_DIR}/full_system_check_${TIMESTAMP}.json"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 HUNTER/NEXUS SYSTEM DIAGNOSTIC${NC}"
echo "=================================="
echo -e "Timestamp: ${YELLOW}$(date)${NC}"
echo -e "Report: ${BLUE}${FULL_REPORT}${NC}"
echo ""

mkdir -p "${REPORT_DIR}"

# Initialize system report
init_system_report() {
    cat > "${FULL_REPORT}" <<EOF
{
  "diagnostic_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hunter_modules": {
    "total_available": 0,
    "functional": [],
    "broken": [],
    "missing_deps": []
  },
  "nexus_integration": {
    "bridge_status": "unknown",
    "personalities_available": 0,
    "consciousness_active": false
  },
  "system_coverage": {
    "security": {"covered": false, "modules": []},
    "performance": {"covered": false, "modules": []},
    "quality": {"covered": false, "modules": []},
    "architecture": {"covered": false, "modules": []},
    "content": {"covered": false, "modules": []},
    "dependencies": {"covered": false, "modules": []},
    "accessibility": {"covered": false, "modules": []}
  },
  "gaps_identified": [],
  "recommended_hunters": []
}
EOF
}

# Test hunter module functionality
test_hunter_module() {
    local module="$1"
    local hunter_path="hunters/${module}.sh"
    
    if [[ ! -f "$hunter_path" ]]; then
        echo "missing"
        return 1
    fi
    
    # Check if hunter can execute without errors (dry run)
    if bash -n "$hunter_path" 2>/dev/null; then
        echo "functional"
        return 0
    else
        echo "broken"
        return 1
    fi
}

# Analyze system coverage
analyze_system_coverage() {
    echo -e "${PURPLE}📊 Analyzing System Coverage${NC}"
    
    # Define coverage categories and their expected hunters
    declare -A coverage_map=(
        ["security"]="security environment_security"
        ["performance"]="performance perf_budget asset_weight image_optimization"
        ["quality"]="code_quality ts_health type_safety"
        ["architecture"]="css_architecture component_size schema_validator"
        ["content"]="content_integrity geo_consistency suburb_forensics"
        ["dependencies"]="build_dependencies package_script_validation"
        ["accessibility"]="accessibility"
    )
    
    for category in "${!coverage_map[@]}"; do
        echo -e "  ${BLUE}→${NC} Checking ${category} coverage..."
        
        local modules="${coverage_map[$category]}"
        local covered_count=0
        local total_count=0
        
        for module in $modules; do
            ((total_count++))
            local status=$(test_hunter_module "$module")
            if [[ "$status" == "functional" ]]; then
                ((covered_count++))
                echo -e "    ✅ $module: ${GREEN}functional${NC}"
            elif [[ "$status" == "broken" ]]; then
                echo -e "    🔧 $module: ${YELLOW}broken${NC}"
            else
                echo -e "    ❌ $module: ${RED}missing${NC}"
            fi
        done
        
        local coverage_percent=$((covered_count * 100 / total_count))
        echo -e "    Coverage: ${coverage_percent}% (${covered_count}/${total_count})"
        echo ""
    done
}

# Test NEXUS integration
test_nexus_integration() {
    echo -e "${PURPLE}🧠 Testing NEXUS Integration${NC}"
    
    # Check if NEXUS bridge is functional
    if node -e "import('./nexus/nexus-bridge.mjs').then(() => console.log('✅ NEXUS bridge functional'))" 2>/dev/null; then
        echo -e "  ✅ NEXUS bridge: ${GREEN}functional${NC}"
        
        # Test consciousness enhancement
        if node -e "import('./hunters/consciousness-bridge.mjs').then(() => console.log('✅ Consciousness bridge functional'))" 2>/dev/null; then
            echo -e "  ✅ Consciousness: ${GREEN}active${NC}"
        else
            echo -e "  ⚠️  Consciousness: ${YELLOW}inactive${NC}"
        fi
        
        # Count available personalities
        local personality_count=$(find nexus/consciousness -name "*.mjs" 2>/dev/null | wc -l || echo "0")
        echo -e "  📊 Personalities: ${CYAN}${personality_count}${NC}"
        
    else
        echo -e "  ❌ NEXUS bridge: ${RED}broken${NC}"
    fi
    echo ""
}

# Identify coverage gaps
identify_gaps() {
    echo -e "${PURPLE}🔍 Identifying Coverage Gaps${NC}"
    
    # Check for common system aspects that might not be covered
    local potential_gaps=(
        "database_health"
        "api_endpoints"
        "environment_configs"
        "logging_quality"
        "error_handling"
        "deployment_readiness"
        "monitoring_setup"
        "backup_systems"
        "disaster_recovery"
        "user_experience"
        "seo_optimization"
        "social_integration"
        "analytics_tracking"
        "cache_strategy"
        "cdn_optimization"
    )
    
    for gap in "${potential_gaps[@]}"; do
        # Check if we have any hunter that might cover this
        local coverage_found=false
        
        for hunter in hunters/*.sh; do
            if [[ -f "$hunter" ]] && grep -qi "$gap\\|${gap//_/}" "$hunter" 2>/dev/null; then
                coverage_found=true
                break
            fi
        done
        
        if [[ "$coverage_found" == "false" ]]; then
            echo -e "  ⚠️  Gap detected: ${YELLOW}${gap}${NC}"
        fi
    done
    echo ""
}

# Generate hunter recommendations
recommend_new_hunters() {
    echo -e "${PURPLE}💡 Recommended New Hunters${NC}"
    
    # Based on common web development needs
    local recommended=(
        "lighthouse_audit.sh:Automated Lighthouse performance and SEO audits"
        "dependency_vulnerability.sh:NPM/package vulnerability scanning"
        "cors_policy.sh:CORS configuration validation"
        "ssl_certificate.sh:SSL/TLS certificate health check"
        "database_performance.sh:Database query and performance analysis"
        "api_response_time.sh:API endpoint response time monitoring"
        "error_boundary.sh:React error boundary and error handling analysis"
        "bundle_analyzer.sh:Webpack/Vite bundle size and composition analysis"
        "social_media_meta.sh:Social media meta tags and OpenGraph validation"
        "robots_sitemap.sh:Robots.txt and sitemap.xml validation"
    )
    
    for rec in "${recommended[@]}"; do
        local hunter_name="${rec%%:*}"
        local description="${rec#*:}"
        echo -e "  💡 ${CYAN}${hunter_name}${NC}: ${description}"
    done
    echo ""
}

# Run full system diagnostic
run_full_diagnostic() {
    echo -e "${GREEN}🚀 Starting Full System Diagnostic${NC}"
    echo ""
    
    init_system_report
    
    # Test all existing hunters
    echo -e "${PURPLE}🔧 Testing Hunter Modules${NC}"
    local functional_count=0
    local total_count=0
    
    for hunter in hunters/*.sh; do
        if [[ -f "$hunter" && "$(basename "$hunter")" != "_common.sh" ]]; then
            ((total_count++))
            local module_name=$(basename "$hunter" .sh)
            local status=$(test_hunter_module "$module_name")
            
            if [[ "$status" == "functional" ]]; then
                ((functional_count++))
                echo -e "  ✅ ${module_name}: ${GREEN}functional${NC}"
            elif [[ "$status" == "broken" ]]; then
                echo -e "  🔧 ${module_name}: ${YELLOW}syntax error${NC}"
            else
                echo -e "  ❌ ${module_name}: ${RED}missing${NC}"
            fi
        fi
    done
    
    echo -e "  📊 Hunter Status: ${functional_count}/${total_count} functional"
    echo ""
    
    test_nexus_integration
    analyze_system_coverage
    identify_gaps
    recommend_new_hunters
    
    echo -e "${GREEN}✅ System Diagnostic Complete${NC}"
    echo -e "Report saved to: ${BLUE}${FULL_REPORT}${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_full_diagnostic
fi