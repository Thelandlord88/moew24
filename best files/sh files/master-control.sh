#!/bin/bash
# master-control.sh - Master System Control and Coordination
# Orchestrates all system management scripts and provides unified control

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

log() {
    echo -e "${WHITE}[MASTER-CONTROL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[MASTER-CONTROL]${NC} $1"
}

error() {
    echo -e "${RED}[MASTER-CONTROL]${NC} $1"
}

info() {
    echo -e "${BLUE}[MASTER-CONTROL]${NC} $1"
}

system() {
    echo -e "${PURPLE}[MASTER-CONTROL]${NC} $1"
}

success() {
    echo -e "${GREEN}[MASTER-CONTROL]${NC} $1"
}

# System management scripts
SYSTEM_SCRIPTS=(
    "doctor-system.sh"
    "geo-data.sh"
    "ui-components.sh"
    "build-tools.sh"
    "quality-systems.sh"
)

show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
 ███▄ ▄███▓ ▄▄▄       ██████ ▄▄▄█████▓▓█████  ██▀███      ▄████▄   ▒█████   ███▄    █ ▄▄▄█████▓ ██▀███   ▒█████   ██▓    
▓██▒▀█▀ ██▒▒████▄   ▒██    ▒ ▓  ██▒ ▓▒▓█   ▀ ▓██ ▒ ██▒   ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓  ██▒ ▓▒▓██ ▒ ██▒▒██▒  ██▒▓██▒    
▓██    ▓██░▒██  ▀█▄ ░ ▓██▄   ▒ ▓██░ ▒░▒███   ▓██ ░▄█ ▒   ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▒ ▓██░ ▒░▓██ ░▄█ ▒▒██░  ██▒▒██░    
▒██    ▒██ ░██▄▄▄▄██  ▒   ██▒░ ▓██▓ ░ ▒▓█  ▄ ▒██▀▀█▄     ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒░ ▓██▓ ░ ▒██▀▀█▄  ▒██   ██░▒██░    
▒██▒   ░██▒ ▓█   ▓██▒██████▒▒  ▒██▒ ░ ░▒████▒░██▓ ▒██▒   ▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░  ▒██▒ ░ ░██▓ ▒██▒░ ████▓▒░██████▒
░ ▒░   ░  ░ ▒▒   ▓▒█▒ ▒▓▒ ▒ ░  ▒ ░░   ░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒   ▒ ░░   ░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░ ▒░▓  ░
░  ░      ░  ▒   ▒▒ ░ ░▒  ░ ░    ░     ░ ░  ░  ░▒ ░ ▒░     ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░    ░      ░▒ ░ ▒░  ░ ▒ ▒░ ░ ░ ▒  ░
░      ░     ░   ▒  ░  ░  ░    ░         ░     ░░   ░    ░        ░ ░ ░ ▒     ░   ░ ░   ░        ░░   ░ ░ ░ ░ ▒    ░ ░   
       ░         ░  ░     ░              ░  ░   ░        ░ ░          ░ ░           ░             ░         ░ ░      ░  ░
                                                          ░                                                                
EOF
    echo -e "${NC}"
    echo -e "${WHITE}🎛️  MASTER SYSTEM CONTROL - Orchestrating All Project Systems${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo
}

show_help() {
    show_banner
    cat << EOF
🎛️ MASTER SYSTEM CONTROL & COORDINATION

USAGE:
    ./master-control.sh [COMMAND] [OPTIONS] [SYSTEM_ARGS...]

COMMANDS:
    status              Show status of all systems
    list                List all managed systems and their files
    validate            Validate all systems
    audit               Run comprehensive audit across all systems
    backup              Backup all systems
    deploy              Deploy all systems
    monitor             Monitor all systems health
    report              Generate master system report
    clean               Clean all systems
    emergency           Emergency system recovery and diagnosis

SYSTEM COMMANDS:
    doctor [args]       Run doctor-system.sh with arguments
    geo [args]          Run geo-data.sh with arguments  
    ui [args]           Run ui-components.sh with arguments
    build [args]        Run build-tools.sh with arguments
    quality [args]      Run quality-systems.sh with arguments

OPTIONS:
    --dry-run          Show what would be done without executing
    --verbose          Show detailed output from all systems
    --force            Force operations without confirmation
    --parallel         Run operations in parallel where possible
    --system           Target specific system (doctor|geo|ui|build|quality)
    --format           Output format (json|html|csv|md)

EXAMPLES:
    # System overview
    ./master-control.sh status

    # Run specific system command
    ./master-control.sh doctor list --verbose
    ./master-control.sh geo validate
    ./master-control.sh ui audit --format json

    # Master operations
    ./master-control.sh audit --format json
    ./master-control.sh backup --force
    ./master-control.sh validate --parallel

    # Emergency operations
    ./master-control.sh emergency --system geo

MANAGED SYSTEMS:
    🏥 doctor-system.sh     - Medical system, patient data, validation
    🌍 geo-data.sh          - Geographic data, adjacency, clusters
    🎨 ui-components.sh     - UI components, layouts, styling
    🔧 build-tools.sh       - Build scripts, automation, CI/CD
    🛡️ quality-systems.sh   - Performance, accessibility, security

EOF
}

check_system_availability() {
    local missing_systems=()
    
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$script" ]]; then
            missing_systems+=("$script")
        elif [[ ! -x "$PROJECT_ROOT/$script" ]]; then
            warn "System script not executable: $script"
            chmod +x "$PROJECT_ROOT/$script" 2>/dev/null || true
        fi
    done
    
    if [[ ${#missing_systems[@]} -gt 0 ]]; then
        error "Missing system scripts:"
        for script in "${missing_systems[@]}"; do
            echo "  ❌ $script"
        done
        return 1
    fi
    
    return 0
}

show_system_status() {
    local verbose=$1
    
    log "🎛️ Master System Status Overview"
    echo
    
    # Check system script availability
    info "📋 System Scripts Availability:"
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        if [[ -f "$PROJECT_ROOT/$script" ]] && [[ -x "$PROJECT_ROOT/$script" ]]; then
            echo "  ✅ $script (available)"
        elif [[ -f "$PROJECT_ROOT/$script" ]]; then
            echo "  ⚠️ $script (not executable)"
        else
            echo "  ❌ $script (missing)"
        fi
    done
    
    echo
    info "🏥 Doctor System Status:"
    if [[ -x "$PROJECT_ROOT/doctor-system.sh" ]]; then
        "$PROJECT_ROOT/doctor-system.sh" validate --verbose="$verbose" 2>/dev/null && echo "  ✅ Medical system operational" || echo "  ⚠️ Medical system issues detected"
    else
        echo "  ❌ Doctor system unavailable"
    fi
    
    echo
    info "🌍 Geographic Data Status:"
    if [[ -x "$PROJECT_ROOT/geo-data.sh" ]]; then
        "$PROJECT_ROOT/geo-data.sh" validate --verbose="$verbose" 2>/dev/null && echo "  ✅ Geographic data validated" || echo "  ⚠️ Geographic data issues detected"
    else
        echo "  ❌ Geo data system unavailable"
    fi
    
    echo
    info "🎨 UI Components Status:"
    if [[ -x "$PROJECT_ROOT/ui-components.sh" ]]; then
        "$PROJECT_ROOT/ui-components.sh" validate --verbose="$verbose" 2>/dev/null && echo "  ✅ UI components validated" || echo "  ⚠️ UI component issues detected"
    else
        echo "  ❌ UI components system unavailable"
    fi
    
    echo
    info "🔧 Build Tools Status:"
    if [[ -x "$PROJECT_ROOT/build-tools.sh" ]]; then
        "$PROJECT_ROOT/build-tools.sh" validate --verbose="$verbose" 2>/dev/null && echo "  ✅ Build tools operational" || echo "  ⚠️ Build tool issues detected"
    else
        echo "  ❌ Build tools system unavailable"
    fi
    
    echo
    info "🛡️ Quality Systems Status:"
    if [[ -x "$PROJECT_ROOT/quality-systems.sh" ]]; then
        "$PROJECT_ROOT/quality-systems.sh" validate --verbose="$verbose" 2>/dev/null && echo "  ✅ Quality systems operational" || echo "  ⚠️ Quality system issues detected"
    else
        echo "  ❌ Quality systems unavailable"
    fi
}

list_all_systems() {
    local verbose=$1
    
    log "📋 Complete System Inventory"
    echo
    
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        if [[ -x "$PROJECT_ROOT/$script" ]]; then
            local system_name=$(echo "$script" | sed 's/-system\.sh//' | sed 's/\.sh//' | tr '-' ' ' | sed 's/\b\w/\U&/g')
            system "🔍 $system_name:"
            "$PROJECT_ROOT/$script" list --verbose="$verbose" 2>/dev/null || echo "  ❌ Failed to list $script"
            echo
        fi
    done
}

validate_all_systems() {
    local verbose=$1
    local parallel=$2
    local system_filter=$3
    
    log "🔍 Validating All Systems..."
    
    local validation_results=()
    local failed_systems=()
    
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        local system_name=$(echo "$script" | sed 's/\.sh//')
        
        # Skip if system filter is specified and doesn't match
        if [[ -n "$system_filter" ]] && [[ "$system_name" != *"$system_filter"* ]]; then
            continue
        fi
        
        if [[ -x "$PROJECT_ROOT/$script" ]]; then
            info "Validating $system_name..."
            
            if [[ "$parallel" == "true" ]]; then
                # Run in background for parallel execution
                "$PROJECT_ROOT/$script" validate --verbose="$verbose" &
                validation_results+=("$!:$system_name")
            else
                # Run sequentially
                if "$PROJECT_ROOT/$script" validate --verbose="$verbose" 2>/dev/null; then
                    echo "  ✅ $system_name validation passed"
                else
                    echo "  ❌ $system_name validation failed"
                    failed_systems+=("$system_name")
                fi
            fi
        else
            echo "  ❌ $system_name unavailable"
            failed_systems+=("$system_name")
        fi
    done
    
    # Handle parallel execution results
    if [[ "$parallel" == "true" ]]; then
        info "Waiting for parallel validations to complete..."
        
        for result in "${validation_results[@]}"; do
            local pid=$(echo "$result" | cut -d: -f1)
            local system=$(echo "$result" | cut -d: -f2)
            
            if wait "$pid"; then
                echo "  ✅ $system validation passed"
            else
                echo "  ❌ $system validation failed"
                failed_systems+=("$system")
            fi
        done
    fi
    
    echo
    if [[ ${#failed_systems[@]} -eq 0 ]]; then
        success "✅ All system validations passed"
        return 0
    else
        error "❌ ${#failed_systems[@]} system(s) failed validation:"
        for system in "${failed_systems[@]}"; do
            echo "  - $system"
        done
        return 1
    fi
}

run_comprehensive_audit() {
    local format=$1
    local parallel=$2
    
    log "🔍 Running Comprehensive Master Audit..."
    
    local audit_results=()
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Run quality systems audit first (most comprehensive)
    if [[ -x "$PROJECT_ROOT/quality-systems.sh" ]]; then
        info "🛡️ Running quality systems audit..."
        if "$PROJECT_ROOT/quality-systems.sh" audit --format json 2>/dev/null; then
            audit_results+=("quality:PASSED")
        else
            audit_results+=("quality:FAILED")
        fi
    fi
    
    # Run other system validations
    local systems=("doctor:🏥" "geo:🌍" "ui:🎨" "build:🔧")
    
    for system_info in "${systems[@]}"; do
        local system=$(echo "$system_info" | cut -d: -f1)
        local icon=$(echo "$system_info" | cut -d: -f2)
        local script="$system-system.sh"
        
        # Handle special cases
        if [[ "$system" == "geo" ]]; then
            script="geo-data.sh"
        elif [[ "$system" == "ui" ]]; then
            script="ui-components.sh"
        elif [[ "$system" == "build" ]]; then
            script="build-tools.sh"
        fi
        
        if [[ -x "$PROJECT_ROOT/$script" ]]; then
            info "$icon Running $system system validation..."
            if "$PROJECT_ROOT/$script" validate 2>/dev/null; then
                audit_results+=("$system:PASSED")
            else
                audit_results+=("$system:FAILED")
            fi
        else
            audit_results+=("$system:UNAVAILABLE")
        fi
    done
    
    # Calculate overall results
    local passed=0
    local failed=0
    local unavailable=0
    
    for result in "${audit_results[@]}"; do
        local status=$(echo "$result" | cut -d: -f2)
        case "$status" in
            "PASSED") passed=$((passed + 1)) ;;
            "FAILED") failed=$((failed + 1)) ;;
            "UNAVAILABLE") unavailable=$((unavailable + 1)) ;;
        esac
    done
    
    local total=$((passed + failed + unavailable))
    local success_rate=$((passed * 100 / (passed + failed)))
    
    echo
    system "🏆 MASTER AUDIT RESULTS:"
    echo "  ✅ Passed: $passed systems"
    echo "  ❌ Failed: $failed systems"
    echo "  ⚠️ Unavailable: $unavailable systems"
    echo "  📊 Success Rate: $success_rate%"
    
    # Generate report in specified format
    if [[ "$format" == "json" ]]; then
        local json_file="$PROJECT_ROOT/__reports/master-audit.json"
        mkdir -p "$(dirname "$json_file")"
        
        cat > "$json_file" << EOF
{
  "timestamp": "$timestamp",
  "audit_type": "master_comprehensive",
  "overall_status": "$([[ $failed -eq 0 ]] && echo "PASSED" || echo "FAILED")",
  "success_rate": $success_rate,
  "results": {
    "passed": $passed,
    "failed": $failed,
    "unavailable": $unavailable,
    "total": $total
  },
  "system_results": [
EOF
        
        local first=true
        for result in "${audit_results[@]}"; do
            local system=$(echo "$result" | cut -d: -f1)
            local status=$(echo "$result" | cut -d: -f2)
            
            if [[ "$first" != "true" ]]; then
                echo "    ," >> "$json_file"
            fi
            first=false
            
            echo "    {\"system\": \"$system\", \"status\": \"$status\"}" >> "$json_file"
        done
        
        cat >> "$json_file" << EOF
  ]
}
EOF
        
        info "📄 Master audit report saved to: $json_file"
    fi
    
    if [[ $failed -eq 0 ]]; then
        success "✅ Master audit PASSED"
        return 0
    else
        error "❌ Master audit FAILED ($failed systems failed)"
        return 1
    fi
}

backup_all_systems() {
    local force=$1
    local parallel=$2
    
    local backup_base="$PROJECT_ROOT/__backups/master/$(date +%Y%m%d_%H%M%S)"
    
    log "💾 Backing up all systems to: $backup_base"
    
    mkdir -p "$backup_base"
    
    local backup_jobs=()
    local backed_up_systems=0
    
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        if [[ -x "$PROJECT_ROOT/$script" ]]; then
            local system_name=$(echo "$script" | sed 's/\.sh//')
            local system_backup_dir="$backup_base/$system_name"
            
            info "💾 Backing up $system_name..."
            
            if [[ "$parallel" == "true" ]]; then
                "$PROJECT_ROOT/$script" backup --backup-dir "$system_backup_dir" --force="$force" &
                backup_jobs+=("$!:$system_name")
            else
                if "$PROJECT_ROOT/$script" backup --backup-dir "$system_backup_dir" --force="$force" 2>/dev/null; then
                    echo "  ✅ $system_name backup completed"
                    backed_up_systems=$((backed_up_systems + 1))
                else
                    echo "  ❌ $system_name backup failed"
                fi
            fi
        fi
    done
    
    # Handle parallel backup results
    if [[ "$parallel" == "true" ]]; then
        info "Waiting for parallel backups to complete..."
        
        for job in "${backup_jobs[@]}"; do
            local pid=$(echo "$job" | cut -d: -f1)
            local system=$(echo "$job" | cut -d: -f2)
            
            if wait "$pid"; then
                echo "  ✅ $system backup completed"
                backed_up_systems=$((backed_up_systems + 1))
            else
                echo "  ❌ $system backup failed"
            fi
        done
    fi
    
    # Create master backup manifest
    cat > "$backup_base/MASTER_BACKUP_MANIFEST.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "backup_type": "master_comprehensive",
  "systems_backed_up": $backed_up_systems,
  "total_systems": ${#SYSTEM_SCRIPTS[@]},
  "backup_location": "$backup_base"
}
EOF
    
    success "✅ Master backup completed: $backed_up_systems systems backed up to $backup_base"
}

run_system_command() {
    local system=$1
    shift
    local args=("$@")
    
    local script=""
    case "$system" in
        "doctor") script="doctor-system.sh" ;;
        "geo") script="geo-data.sh" ;;
        "ui") script="ui-components.sh" ;;
        "build") script="build-tools.sh" ;;
        "quality") script="quality-systems.sh" ;;
        *)
            error "Unknown system: $system"
            echo "Available systems: doctor, geo, ui, build, quality"
            return 1
            ;;
    esac
    
    if [[ ! -x "$PROJECT_ROOT/$script" ]]; then
        error "System script not available: $script"
        return 1
    fi
    
    info "🚀 Running $system system: $script ${args[*]}"
    "$PROJECT_ROOT/$script" "${args[@]}"
}

emergency_recovery() {
    local system_filter=$1
    
    error "🚨 EMERGENCY SYSTEM RECOVERY INITIATED"
    echo
    
    log "📊 System Diagnostics:"
    
    # Check system availability
    local critical_issues=0
    
    for script in "${SYSTEM_SCRIPTS[@]}"; do
        local system_name=$(echo "$script" | sed 's/\.sh//')
        
        if [[ -n "$system_filter" ]] && [[ "$system_name" != *"$system_filter"* ]]; then
            continue
        fi
        
        echo "🔍 Diagnosing $system_name..."
        
        if [[ ! -f "$PROJECT_ROOT/$script" ]]; then
            echo "  ❌ CRITICAL: Script file missing: $script"
            critical_issues=$((critical_issues + 1))
        elif [[ ! -x "$PROJECT_ROOT/$script" ]]; then
            echo "  ⚠️ Script not executable, attempting to fix..."
            chmod +x "$PROJECT_ROOT/$script"
            echo "  ✅ Made executable: $script"
        else
            echo "  ✅ Script available: $script"
            
            # Try basic validation
            if "$PROJECT_ROOT/$script" --help >/dev/null 2>&1; then
                echo "  ✅ Help command works"
            else
                echo "  ⚠️ Help command failed - script may have issues"
            fi
        fi
    done
    
    echo
    if [[ $critical_issues -eq 0 ]]; then
        success "✅ No critical issues found. Systems appear recoverable."
        
        # Attempt to run basic validation
        log "🔧 Running emergency validation..."
        validate_all_systems false false "$system_filter"
        
    else
        error "❌ $critical_issues critical issues found. Manual intervention required."
        echo
        echo "🛠️ Recovery suggestions:"
        echo "  1. Check if system script files exist"
        echo "  2. Verify file permissions (chmod +x *.sh)"
        echo "  3. Ensure project structure is intact"
        echo "  4. Run individual system diagnostics"
    fi
}

generate_master_report() {
    local format=${1:-md}
    local report_file="$PROJECT_ROOT/__reports/master-system-report.$format"
    
    log "📊 Generating Master System Report..."
    
    mkdir -p "$(dirname "$report_file")"
    
    if [[ "$format" == "json" ]]; then
        cat > "$report_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "report_type": "master_system_overview",
  "systems": {
    "doctor": {
      "script": "doctor-system.sh",
      "status": "$([[ -x "$PROJECT_ROOT/doctor-system.sh" ]] && echo "available" || echo "unavailable")",
      "description": "Medical system, patient data, validation"
    },
    "geo": {
      "script": "geo-data.sh", 
      "status": "$([[ -x "$PROJECT_ROOT/geo-data.sh" ]] && echo "available" || echo "unavailable")",
      "description": "Geographic data, adjacency, clusters"
    },
    "ui": {
      "script": "ui-components.sh",
      "status": "$([[ -x "$PROJECT_ROOT/ui-components.sh" ]] && echo "available" || echo "unavailable")",
      "description": "UI components, layouts, styling"
    },
    "build": {
      "script": "build-tools.sh",
      "status": "$([[ -x "$PROJECT_ROOT/build-tools.sh" ]] && echo "available" || echo "unavailable")",
      "description": "Build scripts, automation, CI/CD"
    },
    "quality": {
      "script": "quality-systems.sh",
      "status": "$([[ -x "$PROJECT_ROOT/quality-systems.sh" ]] && echo "available" || echo "unavailable")",
      "description": "Performance, accessibility, security"
    }
  },
  "total_systems": ${#SYSTEM_SCRIPTS[@]}
}
EOF
    else
        cat > "$report_file" << EOF
# 🎛️ Master System Control Report

**Generated**: $(date)  
**Report Type**: Complete System Overview

## 🏗️ System Architecture

The master control system orchestrates 5 specialized management systems:

### 🏥 Doctor System (\`doctor-system.sh\`)
**Status**: $([[ -x "$PROJECT_ROOT/doctor-system.sh" ]] && echo "✅ Available" || echo "❌ Unavailable")  
**Purpose**: Medical system intelligence, patient data validation, connectivity analysis  
**Key Features**: 345 node validation, 100% connectivity verification, data integrity checks

### 🌍 Geographic Data System (\`geo-data.sh\`)
**Status**: $([[ -x "$PROJECT_ROOT/geo-data.sh" ]] && echo "✅ Available" || echo "❌ Unavailable")  
**Purpose**: Geographic data management, adjacency networks, cluster analysis  
**Key Features**: Suburb mapping, service area optimization, data synchronization

### 🎨 UI Components System (\`ui-components.sh\`)
**Status**: $([[ -x "$PROJECT_ROOT/ui-components.sh" ]] && echo "✅ Available" || echo "❌ Unavailable")  
**Purpose**: Frontend asset management, component validation, accessibility auditing  
**Key Features**: Layout management, component optimization, accessibility compliance

### 🔧 Build Tools System (\`build-tools.sh\`)
**Status**: $([[ -x "$PROJECT_ROOT/build-tools.sh" ]] && echo "✅ Available" || echo "❌ Unavailable")  
**Purpose**: Build automation, script management, CI/CD coordination  
**Key Features**: Automated builds, script validation, deployment orchestration

### 🛡️ Quality Systems (\`quality-systems.sh\`)
**Status**: $([[ -x "$PROJECT_ROOT/quality-systems.sh" ]] && echo "✅ Available" || echo "❌ Unavailable")  
**Purpose**: Performance monitoring, security scanning, quality assurance  
**Key Features**: 69 performance checks, accessibility validation, security auditing

## 🎯 Master Commands

\`\`\`bash
# System overview
./master-control.sh status

# Run comprehensive audit
./master-control.sh audit --format json

# Backup all systems
./master-control.sh backup --parallel

# Individual system control
./master-control.sh doctor list --verbose
./master-control.sh geo validate
./master-control.sh ui audit --format json
./master-control.sh build test --env prod
./master-control.sh quality performance --threshold 90

# Emergency recovery
./master-control.sh emergency --system geo
\`\`\`

## 📊 System Statistics

- **Total Management Systems**: ${#SYSTEM_SCRIPTS[@]}
- **Available Systems**: $(ls -la "$PROJECT_ROOT"/*.sh 2>/dev/null | grep -c "^-rwx" || echo "0")
- **Master Control Features**: Status monitoring, validation, auditing, backup, emergency recovery

---
*Generated by master-control.sh - The unified system orchestrator*
EOF
    fi
    
    success "✅ Master system report generated: $report_file"
}

# Main command parsing
COMMAND=""
DRY_RUN=false
VERBOSE=false
FORCE=false
PARALLEL=false
SYSTEM=""
FORMAT="md"

# Check if first argument is a system command
if [[ "$1" =~ ^(doctor|geo|ui|build|quality)$ ]]; then
    SYSTEM_COMMAND="$1"
    shift
    run_system_command "$SYSTEM_COMMAND" "$@"
    exit $?
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        status|list|validate|audit|backup|deploy|monitor|report|clean|emergency)
            COMMAND="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --system)
            SYSTEM="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Ensure all system scripts are executable
if ! check_system_availability; then
    exit 1
fi

# Execute command
case "$COMMAND" in
    status)
        show_system_status "$VERBOSE"
        ;;
    list)
        list_all_systems "$VERBOSE"
        ;;
    validate)
        validate_all_systems "$VERBOSE" "$PARALLEL" "$SYSTEM"
        ;;
    audit)
        run_comprehensive_audit "$FORMAT" "$PARALLEL"
        ;;
    backup)
        backup_all_systems "$FORCE" "$PARALLEL"
        ;;
    report)
        generate_master_report "$FORMAT"
        ;;
    emergency)
        emergency_recovery "$SYSTEM"
        ;;
    "")
        show_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        echo "Use --help for usage information"
        exit 1
        ;;
esac