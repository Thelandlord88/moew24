#!/bin/bash
# doctor-system.sh - Medical System File Manager
# Manages all doctor, patient, and medical system files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[DOCTOR-SYSTEM]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[DOCTOR-SYSTEM]${NC} $1"
}

error() {
    echo -e "${RED}[DOCTOR-SYSTEM]${NC} $1"
}

info() {
    echo -e "${BLUE}[DOCTOR-SYSTEM]${NC} $1"
}

# Define all doctor/medical system files
DOCTOR_FILES=(
    # Main medical system directory
    "geo_medical_system/doctor/doctor.working.mjs"
    "geo_medical_system/doctor/doctor.enhanced.mjs"
    "geo_medical_system/doctor/doctor.medical.mjs"
    "geo_medical_system/doctor/doctor-cli.mjs"
    "geo_medical_system/doctor/simple-test.mjs"
    "geo_medical_system/doctor/daedalus-builder.mjs"
    "geo_medical_system/doctor/daedalus-showcase.mjs"
    
    # Medical library modules
    "geo_medical_system/doctor/lib/medical-core.mjs"
    "geo_medical_system/doctor/lib/report-generator.mjs"
    "geo_medical_system/doctor/lib/validation-engine.mjs"
    
    # Legacy doctor scripts
    "geo_medical_system/doctor/scripts/doctor.improved.mjs"
    
    # Patient data
    "geo_medical_system/patients/data/adjacency.json"
    "geo_medical_system/patients/data/areas.clusters.json"
    "geo_medical_system/patients/data/service_coverage.json"
    "geo_medical_system/patients/data/suburbs_enriched.geojson"
    
    # Patient schemas
    "geo_medical_system/patients/schemas/adjacency.schema.json"
    "geo_medical_system/patients/schemas/clusters.schema.json"
    "geo_medical_system/patients/schemas/coverage.schema.json"
    
    # Documentation
    "geo_medical_system/README.md"
    "geo_medical_system/IMPLEMENTATION_COMPLETE.md"
    "geo_medical_system/DAEDALUS_BLUEPRINT.md"
    "geo_medical_system/DAEDALUS_FINAL_REPORT.md"
    
    # Reports and showcase
    "geo_medical_system/__showcase/service-showcase.astro"
    "geo_medical_system/__showcase/COMPONENT_INVENTORY.md"
    "geo_medical_system/__showcase/daedalus-confidence-report.json"
    "geo_medical_system/doctor/reports/README.md"
)

# Legacy cluster scripts (medical related)
LEGACY_DOCTOR_FILES=(
    "cluster scritps/cluster script .txt"
    "cluster scritps/adjacency.json"
    "cluster scritps/areas.extended.clusters.json"
    "cluster scritps/reconcile-cluster.spec/adjacency.reconciled.json"
)

show_help() {
    cat << EOF
🏥 DOCTOR SYSTEM FILE MANAGER

USAGE:
    ./doctor-system.sh [COMMAND] [OPTIONS]

COMMANDS:
    list                List all medical system files
    validate           Validate all medical system files exist
    backup             Backup all medical system files
    restore            Restore medical system files from backup
    organize           Organize files into proper structure
    test               Run medical system tests
    report             Generate medical system report
    clean              Clean temporary medical files
    archive            Archive old medical system versions

OPTIONS:
    --dry-run         Show what would be done without executing
    --verbose         Show detailed output
    --force           Force operations without confirmation
    --backup-dir      Specify backup directory (default: __backups/medical)

EXAMPLES:
    ./doctor-system.sh list
    ./doctor-system.sh validate --verbose
    ./doctor-system.sh backup --backup-dir /custom/backup
    ./doctor-system.sh test --dry-run
    ./doctor-system.sh organize --force

MANAGED FILES:
    - Doctor variants (working, enhanced, medical, CLI)
    - Medical core libraries (validation, reporting, analysis)
    - Patient data (adjacency, clusters, coverage, geographic)
    - Schemas and documentation
    - Legacy cluster scripts
    - Test files and reports

EOF
}

list_files() {
    local verbose=$1
    
    log "📋 Medical System File Inventory"
    echo
    
    info "🩺 DOCTOR EXECUTABLES:"
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/doctor/"*.mjs ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                if [[ "$verbose" == "true" ]]; then
                    local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    echo "  ✅ $file ($lines lines, $size bytes)"
                else
                    echo "  ✅ $file"
                fi
            else
                echo "  ❌ $file (missing)"
            fi
        fi
    done
    
    echo
    info "📚 MEDICAL LIBRARIES:"
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/lib/"* ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                if [[ "$verbose" == "true" ]]; then
                    local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    echo "  ✅ $file ($lines lines, $size bytes)"
                else
                    echo "  ✅ $file"
                fi
            else
                echo "  ❌ $file (missing)"
            fi
        fi
    done
    
    echo
    info "🏥 PATIENT DATA:"
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/patients/"* || "$file" == *".json" || "$file" == *".geojson" ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                if [[ "$verbose" == "true" ]]; then
                    local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    echo "  ✅ $file ($size bytes)"
                else
                    echo "  ✅ $file"
                fi
            else
                echo "  ❌ $file (missing)"
            fi
        fi
    done
    
    echo
    info "🏛️ LEGACY CLUSTER SCRIPTS:"
    for file in "${LEGACY_DOCTOR_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "  ✅ $file ($size bytes)"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
}

validate_files() {
    local verbose=$1
    local missing=0
    local total=0
    
    log "🔍 Validating Medical System Files..."
    
    for file in "${DOCTOR_FILES[@]}" "${LEGACY_DOCTOR_FILES[@]}"; do
        total=$((total + 1))
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ Missing: $file"
            missing=$((missing + 1))
        fi
    done
    
    echo
    if [[ $missing -eq 0 ]]; then
        log "✅ All $total medical system files validated successfully"
    else
        error "❌ $missing out of $total files are missing"
        return 1
    fi
}

backup_files() {
    local backup_dir=$1
    local force=$2
    
    if [[ -z "$backup_dir" ]]; then
        backup_dir="$PROJECT_ROOT/__backups/medical/$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "💾 Backing up medical system to: $backup_dir"
    
    if [[ -d "$backup_dir" ]] && [[ "$force" != "true" ]]; then
        error "Backup directory already exists: $backup_dir"
        echo "Use --force to overwrite"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    
    local backed_up=0
    for file in "${DOCTOR_FILES[@]}" "${LEGACY_DOCTOR_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local dest_dir="$backup_dir/$(dirname "$file")"
            mkdir -p "$dest_dir"
            cp "$PROJECT_ROOT/$file" "$backup_dir/$file"
            backed_up=$((backed_up + 1))
            echo "  📄 $file"
        fi
    done
    
    # Create backup manifest
    cat > "$backup_dir/BACKUP_MANIFEST.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "$PROJECT_ROOT",
  "backup_type": "medical_system",
  "files_backed_up": $backed_up,
  "total_files": $((${#DOCTOR_FILES[@]} + ${#LEGACY_DOCTOR_FILES[@]}))
}
EOF
    
    log "✅ Backed up $backed_up files to $backup_dir"
}

test_medical_system() {
    local dry_run=$1
    
    log "🧪 Testing Medical System..."
    
    # Test 1: Simple doctor test
    info "Testing simple doctor connectivity..."
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY-RUN] Would run: node geo_medical_system/doctor/simple-test.mjs patients/data"
    else
        cd "$PROJECT_ROOT/geo_medical_system/doctor"
        if node simple-test.mjs ../patients/data 2>/dev/null; then
            echo "  ✅ Simple doctor test passed"
        else
            echo "  ❌ Simple doctor test failed"
            return 1
        fi
    fi
    
    # Test 2: Medical core validation
    info "Testing medical core libraries..."
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY-RUN] Would validate medical core libraries"
    else
        if [[ -f "$PROJECT_ROOT/geo_medical_system/doctor/lib/medical-core.mjs" ]]; then
            echo "  ✅ Medical core library exists"
        else
            echo "  ❌ Medical core library missing"
            return 1
        fi
    fi
    
    # Test 3: Patient data integrity
    info "Testing patient data integrity..."
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY-RUN] Would validate patient data files"
    else
        local patient_files=("adjacency.json" "areas.clusters.json" "service_coverage.json")
        for file in "${patient_files[@]}"; do
            if [[ -f "$PROJECT_ROOT/geo_medical_system/patients/data/$file" ]]; then
                if python3 -m json.tool "$PROJECT_ROOT/geo_medical_system/patients/data/$file" > /dev/null 2>&1; then
                    echo "  ✅ $file is valid JSON"
                else
                    echo "  ❌ $file has invalid JSON"
                    return 1
                fi
            else
                echo "  ❌ $file is missing"
                return 1
            fi
        done
    fi
    
    log "✅ All medical system tests passed"
}

generate_report() {
    local report_file="$PROJECT_ROOT/__reports/medical-system-report.md"
    
    log "📊 Generating Medical System Report..."
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# 🏥 Medical System Report

**Generated**: $(date)  
**Report Type**: File Inventory and System Status

## 📋 System Overview

### Doctor Executables
EOF
    
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/doctor/"*.mjs ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "- ✅ \`$file\` ($lines lines)" >> "$report_file"
            else
                echo "- ❌ \`$file\` (missing)" >> "$report_file"
            fi
        fi
    done
    
    cat >> "$report_file" << EOF

### Medical Libraries
EOF
    
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/lib/"* ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "- ✅ \`$file\` ($lines lines)" >> "$report_file"
            else
                echo "- ❌ \`$file\` (missing)" >> "$report_file"
            fi
        fi
    done
    
    cat >> "$report_file" << EOF

### Patient Data Files
EOF
    
    for file in "${DOCTOR_FILES[@]}"; do
        if [[ "$file" == *"/patients/"* ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "- ✅ \`$file\` ($size bytes)" >> "$report_file"
            else
                echo "- ❌ \`$file\` (missing)" >> "$report_file"
            fi
        fi
    done
    
    cat >> "$report_file" << EOF

## 🎯 Quick Start Commands

\`\`\`bash
# Test the medical system
./doctor-system.sh test

# Run simple connectivity test
cd geo_medical_system/doctor && node simple-test.mjs ../patients/data

# Generate comprehensive analysis
cd geo_medical_system/doctor && node doctor.working.mjs --verbose

# Use Daedalus builder
cd geo_medical_system && node daedalus-builder.mjs --help
\`\`\`

## 📊 System Statistics

- **Total Doctor Files**: ${#DOCTOR_FILES[@]}
- **Legacy Files**: ${#LEGACY_DOCTOR_FILES[@]}
- **Report Generated**: $(date)

---
*Generated by doctor-system.sh*
EOF
    
    log "✅ Report generated: $report_file"
}

organize_files() {
    local force=$1
    
    log "🗂️ Organizing Medical System Files..."
    
    # Ensure proper directory structure
    local dirs=(
        "geo_medical_system/doctor/lib"
        "geo_medical_system/doctor/scripts"
        "geo_medical_system/doctor/reports"
        "geo_medical_system/patients/data"
        "geo_medical_system/patients/schemas"
        "geo_medical_system/__showcase"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
            mkdir -p "$PROJECT_ROOT/$dir"
            echo "  📁 Created directory: $dir"
        fi
    done
    
    log "✅ Medical system file organization complete"
}

clean_files() {
    local force=$1
    
    log "🧹 Cleaning Medical System Temporary Files..."
    
    local temp_patterns=(
        "geo_medical_system/**/*.tmp"
        "geo_medical_system/**/*.log"
        "geo_medical_system/**/*~"
        "geo_medical_system/**/.DS_Store"
        "geo_medical_system/**/node_modules"
    )
    
    local cleaned=0
    for pattern in "${temp_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if [[ "$force" == "true" ]]; then
                rm -rf "$file"
                echo "  🗑️ Removed: $file"
                cleaned=$((cleaned + 1))
            else
                echo "  📄 Would remove: $file"
            fi
        done < <(find "$PROJECT_ROOT" -path "*$pattern" -print0 2>/dev/null || true)
    done
    
    if [[ "$force" == "true" ]]; then
        log "✅ Cleaned $cleaned temporary files"
    else
        log "ℹ️ Use --force to actually remove files"
    fi
}

# Main command parsing
COMMAND=""
DRY_RUN=false
VERBOSE=false
FORCE=false
BACKUP_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        list|validate|backup|restore|organize|test|report|clean|archive)
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
        --backup-dir)
            BACKUP_DIR="$2"
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

# Execute command
case "$COMMAND" in
    list)
        list_files "$VERBOSE"
        ;;
    validate)
        validate_files "$VERBOSE"
        ;;
    backup)
        backup_files "$BACKUP_DIR" "$FORCE"
        ;;
    test)
        test_medical_system "$DRY_RUN"
        ;;
    report)
        generate_report
        ;;
    organize)
        organize_files "$FORCE"
        ;;
    clean)
        clean_files "$FORCE"
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