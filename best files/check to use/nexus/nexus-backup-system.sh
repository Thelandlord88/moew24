#!/bin/bash
# NEXUS Component Backup & Optimization Safety System
# Creates backups before NEXUS optimization work

BACKUP_DIR="/workspaces/Augest26testerr/nexus-backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

backup_component() {
    local component_path="$1"
    local component_name=$(basename "$component_path")
    local backup_name="${component_name%.astro}_backup_${TIMESTAMP}.astro"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    if [ ! -f "$component_path" ]; then
        echo -e "${RED}❌ Component not found: $component_path${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📂 Creating safety backup...${NC}"
    cp "$component_path" "$backup_path"
    
    echo -e "${GREEN}✅ Backup created: $backup_name${NC}"
    echo -e "${BLUE}   Original: $component_path${NC}"
    echo -e "${BLUE}   Backup: $backup_path${NC}"
    
    return 0
}

restore_component() {
    local backup_path="$1"
    local original_path="$2"
    
    if [ ! -f "$backup_path" ]; then
        echo -e "${RED}❌ Backup not found: $backup_path${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔄 Restoring from backup...${NC}"
    cp "$backup_path" "$original_path"
    
    echo -e "${GREEN}✅ Component restored from backup${NC}"
    return 0
}

list_backups() {
    echo -e "${CYAN}📋 Available NEXUS Backups:${NC}"
    ls -la "$BACKUP_DIR" | grep "\.astro$" || echo -e "${YELLOW}No backups found${NC}"
}

# Main script logic
case "$1" in
    "backup")
        if [ -z "$2" ]; then
            echo "Usage: $0 backup <component_path>"
            exit 1
        fi
        backup_component "$2"
        ;;
    "restore")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 restore <backup_path> <original_path>"
            exit 1
        fi
        restore_component "$2" "$3"
        ;;
    "list")
        list_backups
        ;;
    *)
        echo -e "${PURPLE}🛡️ NEXUS Component Safety System${NC}"
        echo "================================"
        echo ""
        echo "Usage:"
        echo "  $0 backup <component_path>     - Create safety backup"
        echo "  $0 restore <backup> <original> - Restore from backup"
        echo "  $0 list                        - List available backups"
        ;;
esac
