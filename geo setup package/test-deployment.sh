#!/bin/bash

# 🧪 **TEST DEPLOYMENT SCRIPT**
# Quick validation of the geo system deployment package

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Geo System Deployment Script${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check if deployment script exists
if [ ! -f "deploy-geo-system.sh" ]; then
    echo -e "${YELLOW}❌ deploy-geo-system.sh not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Deployment script found${NC}"

# Check if script is executable
if [ ! -x "deploy-geo-system.sh" ]; then
    echo -e "${YELLOW}⚠️  Making script executable...${NC}"
    chmod +x deploy-geo-system.sh
fi

echo -e "${GREEN}✅ Script is executable${NC}"

# Validate script syntax
if bash -n deploy-geo-system.sh; then
    echo -e "${GREEN}✅ Script syntax is valid${NC}"
else
    echo -e "${YELLOW}❌ Script has syntax errors${NC}"
    exit 1
fi

# Check script size and content
SCRIPT_SIZE=$(wc -l < deploy-geo-system.sh)
echo -e "${BLUE}📊 Script statistics:${NC}"
echo -e "${BLUE}   Lines of code: ${SCRIPT_SIZE}${NC}"
echo -e "${BLUE}   Functions: $(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' deploy-geo-system.sh)${NC}"
echo -e "${BLUE}   Print statements: $(grep -c 'print_' deploy-geo-system.sh)${NC}"

# Check for key components
echo ""
echo -e "${BLUE}🔍 Checking script components:${NC}"

COMPONENTS=(
    "print_header"
    "check_prerequisites" 
    "setup_project_structure"
    "install_dependencies"
    "create_geo_configuration"
    "create_schemas"
    "create_seo_components"
    "build_and_test"
)

for component in "${COMPONENTS[@]}"; do
    if grep -q "$component" deploy-geo-system.sh; then
        echo -e "${GREEN}   ✅ $component${NC}"
    else
        echo -e "${YELLOW}   ❌ $component missing${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Deployment script validation completed!${NC}"
echo ""
echo -e "${BLUE}📋 To run the deployment:${NC}"
echo -e "${BLUE}   ./deploy-geo-system.sh${NC}"
echo ""