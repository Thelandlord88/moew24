#!/bin/bash
# geo-data.sh - Geographic Data File Manager
# Manages all geographic, adjacency, cluster, and spatial data files

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
    echo -e "${GREEN}[GEO-DATA]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[GEO-DATA]${NC} $1"
}

error() {
    echo -e "${RED}[GEO-DATA]${NC} $1"
}

info() {
    echo -e "${BLUE}[GEO-DATA]${NC} $1"
}

# Define all geographic data files
GEO_DATA_FILES=(
    # Primary data files
    "what we've done/src/data/adjacency.json"
    "what we've done/src/data/areas.clusters.json"
    "what we've done/src/data/areas.hierarchical.clusters.json"
    "what we've done/src/data/suburbs.coords.json"
    "what we've done/src/data/suburbs.index.json"
    "what we've done/src/data/suburbs.aliases.json"
    "what we've done/src/data/lgas.groups.json"
    "what we've done/src/data/geo.integrity.json"
    "what we've done/src/data/geo.integrity.local.json"
    
    # Map data
    "what we've done/map data/suburbs_enriched.geojson"
    "what we've done/Suburb Data True/suburbs_enriched.geojson"
    
    # Legacy cluster scripts data
    "cluster scritps/adjacency.json"
    "cluster scritps/areas.extended.clusters.json"
    "cluster scritps/reconcile-cluster.spec/adjacency.reconciled.json"
    
    # Archive data
    "what we've done/src/data/__backup_20250914_065639/adjacency.json"
    "what we've done/src/data/__backup_20250914_065639/suburbs.coords.json"
    
    # Patient data (medical system)
    "geo_medical_system/patients/data/adjacency.json"
    "geo_medical_system/patients/data/areas.clusters.json"
    "geo_medical_system/patients/data/service_coverage.json"
    "geo_medical_system/patients/data/suburbs_enriched.geojson"
)

# Geo schemas and configuration
GEO_SCHEMA_FILES=(
    "what we've done/schemas/adj.config.schema.json"
    "what we've done/schemas/adjacency.build.schema.json"
    "what we've done/schemas/suburbs.meta.schema.json"
    "geo_medical_system/patients/schemas/adjacency.schema.json"
    "geo_medical_system/patients/schemas/clusters.schema.json"
    "geo_medical_system/patients/schemas/coverage.schema.json"
    "what we've done/geo.config.json"
    "what we've done/geo.policy.json"
    "what we've done/geo.config.schema.json"
)

# Geo processing scripts
GEO_SCRIPT_FILES=(
    "what we've done/scripts/geo/build-adjacency.mjs"
    "what we've done/scripts/geo/validate-adjacency.mjs"
    "what we've done/scripts/geo/metrics.mjs"
    "what we've done/scripts/geo/doctor.mjs"
    "what we've done/scripts/geo/diff.mjs"
    "what we've done/scripts/geo/gate.mjs"
    "what we've done/scripts/geo/bridge.mjs"
    "what we've done/scripts/geo/churn.mjs"
    "what we've done/scripts/geo/hash-verify.mjs"
    "what we've done/scripts/geo/history-archive.mjs"
    "what we've done/scripts/geo/ingest-import.mjs"
    "what we've done/scripts/geo/overlay-merge.mjs"
    "what we've done/scripts/geo/pr-summary.mjs"
    "what we've done/scripts/geo/report-index.mjs"
    "what we've done/scripts/geo/report-md.mjs"
    "what we've done/scripts/geo/strategy-coverage.mjs"
)

# Improvement files 2 geo utilities
IMPROVEMENT_GEO_FILES=(
    "improvement files 2/utilities/geo-handlers/geoHandler.ts"
    "improvement files 2/utilities/geo-handlers/repSuburb.improved.ts"
    "improvement files 2/utilities/geo-handlers/repSuburb.ts"
    "improvement files 2/utilities/geo-handlers/links.index.ts"
    "improvement files 2/utilities/geo-handlers/math.js"
    "improvement files 2/utilities/geo-handlers/links.nearby.ts"
    "improvement files 2/utilities/geo-handlers/resolveDisplay.ts"
    "improvement files 2/utilities/geo-handlers/nearbyCovered.ts"
    "improvement files 2/utilities/geo-handlers/nearbyCovered.single.ts"
    "improvement files 2/utilities/geo-handlers/chooseSuburbForPost.sync.ts"
    "improvement files 2/utilities/geo-handlers/repSuburb.sync.ts"
    "improvement files 2/utilities/geo-handlers/internalLinksAdapter.ts"
    "improvement files 2/utilities/geo-handlers/geoCompat.ts"
    "improvement files 2/utilities/geo-handlers/links.clusterAliases.ts"
    "improvement files 2/utilities/geo-handlers/geo.index.ts"
)

show_help() {
    cat << EOF
🌍 GEOGRAPHIC DATA FILE MANAGER

USAGE:
    ./geo-data.sh [COMMAND] [OPTIONS]

COMMANDS:
    list                List all geographic data files
    validate           Validate all geographic data files
    analyze            Analyze geographic data integrity
    sync               Sync data between different locations
    backup             Backup all geographic data
    restore            Restore geographic data from backup
    optimize           Optimize geographic data files
    report             Generate geographic data report
    clean              Clean temporary geographic files
    migrate            Migrate data between formats

OPTIONS:
    --dry-run         Show what would be done without executing
    --verbose         Show detailed output
    --force           Force operations without confirmation
    --backup-dir      Specify backup directory (default: __backups/geo)
    --format          Specify data format (json|geojson|csv)

EXAMPLES:
    ./geo-data.sh list --verbose
    ./geo-data.sh validate
    ./geo-data.sh analyze --format json
    ./geo-data.sh sync --dry-run
    ./geo-data.sh backup --backup-dir /custom/backup
    ./geo-data.sh optimize --force

MANAGED FILES:
    - Adjacency data (suburb connections)
    - Cluster definitions (geographic groupings)
    - Coordinate data (lat/lng for suburbs)
    - Service coverage areas
    - Geographic schemas and validation
    - Processing scripts and utilities

EOF
}

list_files() {
    local verbose=$1
    
    log "🗺️ Geographic Data File Inventory"
    echo
    
    info "🏘️ CORE DATA FILES:"
    for file in "${GEO_DATA_FILES[@]}"; do
        if [[ "$file" == *".json" || "$file" == *".geojson" ]]; then
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                if [[ "$verbose" == "true" ]]; then
                    local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    local records=""
                    if command -v jq >/dev/null 2>&1; then
                        if [[ "$file" == *"adjacency"* ]]; then
                            records=" ($(jq -r 'keys | length' "$PROJECT_ROOT/$file" 2>/dev/null || echo "?") suburbs)"
                        elif [[ "$file" == *"cluster"* ]]; then
                            records=" ($(jq -r 'keys | length' "$PROJECT_ROOT/$file" 2>/dev/null || echo "?") clusters)"
                        fi
                    fi
                    echo "  ✅ $file ($size bytes$records)"
                else
                    echo "  ✅ $file"
                fi
            else
                echo "  ❌ $file (missing)"
            fi
        fi
    done
    
    echo
    info "📋 SCHEMA FILES:"
    for file in "${GEO_SCHEMA_FILES[@]}"; do
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
    
    echo
    info "⚙️ PROCESSING SCRIPTS:"
    for file in "${GEO_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "  ✅ $file ($lines lines)"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    echo
    info "🔧 UTILITY HANDLERS:"
    for file in "${IMPROVEMENT_GEO_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "  ✅ $file ($lines lines)"
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
    local invalid=0
    local total=0
    
    log "🔍 Validating Geographic Data Files..."
    
    # Validate JSON files
    for file in "${GEO_DATA_FILES[@]}" "${GEO_SCHEMA_FILES[@]}"; do
        if [[ "$file" == *".json" ]]; then
            total=$((total + 1))
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                if command -v jq >/dev/null 2>&1; then
                    if jq empty "$PROJECT_ROOT/$file" >/dev/null 2>&1; then
                        if [[ "$verbose" == "true" ]]; then
                            echo "  ✅ $file (valid JSON)"
                        fi
                    else
                        echo "  ❌ $file (invalid JSON)"
                        invalid=$((invalid + 1))
                    fi
                else
                    if python3 -m json.tool "$PROJECT_ROOT/$file" > /dev/null 2>&1; then
                        if [[ "$verbose" == "true" ]]; then
                            echo "  ✅ $file (valid JSON)"
                        fi
                    else
                        echo "  ❌ $file (invalid JSON)"
                        invalid=$((invalid + 1))
                    fi
                fi
            else
                echo "  ❌ Missing: $file"
                missing=$((missing + 1))
            fi
        fi
    done
    
    echo
    if [[ $missing -eq 0 && $invalid -eq 0 ]]; then
        log "✅ All $total geographic data files validated successfully"
    else
        if [[ $missing -gt 0 ]]; then
            error "❌ $missing files are missing"
        fi
        if [[ $invalid -gt 0 ]]; then
            error "❌ $invalid files have invalid JSON"
        fi
        return 1
    fi
}

analyze_data() {
    local format=$1
    
    log "📊 Analyzing Geographic Data Integrity..."
    
    # Find the main adjacency file
    local adjacency_file=""
    local main_adjacency="what we've done/src/data/adjacency.json"
    local patient_adjacency="geo_medical_system/patients/data/adjacency.json"
    
    if [[ -f "$PROJECT_ROOT/$main_adjacency" ]]; then
        adjacency_file="$main_adjacency"
    elif [[ -f "$PROJECT_ROOT/$patient_adjacency" ]]; then
        adjacency_file="$patient_adjacency"
    else
        error "No adjacency.json file found!"
        return 1
    fi
    
    info "📍 Analyzing: $adjacency_file"
    
    if command -v jq >/dev/null 2>&1; then
        local suburbs_count=$(jq -r 'keys | length' "$PROJECT_ROOT/$adjacency_file")
        local total_connections=0
        
        # Calculate total connections
        while IFS= read -r count; do
            total_connections=$((total_connections + count))
        done < <(jq -r '.[] | if type == "array" then length else (.adjacent_suburbs // [] | length) end' "$PROJECT_ROOT/$adjacency_file")
        
        local avg_connections=$((total_connections / suburbs_count))
        
        echo "  🏘️ Total suburbs: $suburbs_count"
        echo "  🔗 Total connections: $total_connections"
        echo "  📊 Average connections per suburb: $avg_connections"
        
        # Find top connected suburbs
        echo "  🔝 Top connected suburbs:"
        jq -r 'to_entries | map({key: .key, count: (if .value | type == "array" then .value | length else .value.adjacent_suburbs // [] | length end)}) | sort_by(.count) | reverse | .[0:5] | .[] | "    \(.key): \(.count) connections"' "$PROJECT_ROOT/$adjacency_file"
        
        # Find isolated suburbs
        local isolated=$(jq -r 'to_entries | map(select(if .value | type == "array" then .value | length == 0 else .value.adjacent_suburbs // [] | length == 0 end)) | length' "$PROJECT_ROOT/$adjacency_file")
        echo "  🏝️ Isolated suburbs (no connections): $isolated"
        
    else
        warn "jq not available - limited analysis"
        echo "  📄 File exists and appears to be valid JSON"
    fi
    
    # Check cluster data if available
    local cluster_file="what we've done/src/data/areas.clusters.json"
    if [[ -f "$PROJECT_ROOT/$cluster_file" ]]; then
        info "📍 Analyzing: $cluster_file"
        if command -v jq >/dev/null 2>&1; then
            local clusters_count=$(jq -r 'keys | length' "$PROJECT_ROOT/$cluster_file")
            echo "  🏘️ Total clusters: $clusters_count"
            
            echo "  📋 Clusters:"
            jq -r 'to_entries | .[] | "    \(.key): \(if .value | type == "array" then .value | length else "unknown" end) suburbs"' "$PROJECT_ROOT/$cluster_file"
        fi
    fi
}

sync_data() {
    local dry_run=$1
    
    log "🔄 Syncing Geographic Data Between Locations..."
    
    # Define sync mappings (source -> destination)
    declare -A sync_map=(
        ["what we've done/src/data/adjacency.json"]="geo_medical_system/patients/data/adjacency.json"
        ["what we've done/src/data/areas.clusters.json"]="geo_medical_system/patients/data/areas.clusters.json"
        ["what we've done/map data/suburbs_enriched.geojson"]="geo_medical_system/patients/data/suburbs_enriched.geojson"
    )
    
    local synced=0
    for source in "${!sync_map[@]}"; do
        local dest="${sync_map[$source]}"
        
        if [[ -f "$PROJECT_ROOT/$source" ]]; then
            if [[ ! -f "$PROJECT_ROOT/$dest" ]] || [[ "$PROJECT_ROOT/$source" -nt "$PROJECT_ROOT/$dest" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo "  [DRY-RUN] Would sync: $source -> $dest"
                else
                    mkdir -p "$(dirname "$PROJECT_ROOT/$dest")"
                    cp "$PROJECT_ROOT/$source" "$PROJECT_ROOT/$dest"
                    echo "  ✅ Synced: $source -> $dest"
                    synced=$((synced + 1))
                fi
            else
                echo "  ⏭️ Skip: $dest is up to date"
            fi
        else
            warn "Source missing: $source"
        fi
    done
    
    if [[ "$dry_run" != "true" ]]; then
        log "✅ Synced $synced geographic data files"
    fi
}

backup_data() {
    local backup_dir=$1
    local force=$2
    
    if [[ -z "$backup_dir" ]]; then
        backup_dir="$PROJECT_ROOT/__backups/geo/$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "💾 Backing up geographic data to: $backup_dir"
    
    if [[ -d "$backup_dir" ]] && [[ "$force" != "true" ]]; then
        error "Backup directory already exists: $backup_dir"
        echo "Use --force to overwrite"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    
    local backed_up=0
    local all_files=("${GEO_DATA_FILES[@]}" "${GEO_SCHEMA_FILES[@]}" "${GEO_SCRIPT_FILES[@]}")
    
    for file in "${all_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local dest_dir="$backup_dir/$(dirname "$file")"
            mkdir -p "$dest_dir"
            cp "$PROJECT_ROOT/$file" "$backup_dir/$file"
            backed_up=$((backed_up + 1))
            echo "  📄 $file"
        fi
    done
    
    # Create backup manifest with analysis
    local manifest="$backup_dir/BACKUP_MANIFEST.json"
    cat > "$manifest" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "$PROJECT_ROOT",
  "backup_type": "geographic_data",
  "files_backed_up": $backed_up,
  "total_files": ${#all_files[@]},
  "categories": {
    "data_files": ${#GEO_DATA_FILES[@]},
    "schema_files": ${#GEO_SCHEMA_FILES[@]},
    "script_files": ${#GEO_SCRIPT_FILES[@]}
  }
}
EOF
    
    # Add data analysis to manifest if possible
    if command -v jq >/dev/null 2>&1; then
        local main_adj="$backup_dir/what we've done/src/data/adjacency.json"
        if [[ -f "$main_adj" ]]; then
            local suburbs=$(jq -r 'keys | length' "$main_adj")
            local temp_manifest=$(mktemp)
            jq --argjson suburbs "$suburbs" '.analysis = {suburbs_count: $suburbs}' "$manifest" > "$temp_manifest"
            mv "$temp_manifest" "$manifest"
        fi
    fi
    
    log "✅ Backed up $backed_up geographic files to $backup_dir"
}

optimize_data() {
    local force=$1
    
    log "⚡ Optimizing Geographic Data Files..."
    
    if [[ "$force" != "true" ]]; then
        warn "This will modify data files. Use --force to proceed."
        return 1
    fi
    
    # Optimize JSON files - minify and validate
    local optimized=0
    for file in "${GEO_DATA_FILES[@]}" "${GEO_SCHEMA_FILES[@]}"; do
        if [[ "$file" == *".json" ]] && [[ -f "$PROJECT_ROOT/$file" ]]; then
            if command -v jq >/dev/null 2>&1; then
                local temp_file=$(mktemp)
                if jq -c . "$PROJECT_ROOT/$file" > "$temp_file" 2>/dev/null; then
                    local original_size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file")
                    local new_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file")
                    local savings=$((original_size - new_size))
                    
                    if [[ $savings -gt 0 ]]; then
                        mv "$temp_file" "$PROJECT_ROOT/$file"
                        echo "  ✅ $file (saved $savings bytes)"
                        optimized=$((optimized + 1))
                    else
                        rm "$temp_file"
                        echo "  ⏭️ $file (already optimized)"
                    fi
                else
                    rm "$temp_file"
                    warn "Failed to optimize $file"
                fi
            fi
        fi
    done
    
    log "✅ Optimized $optimized geographic data files"
}

generate_report() {
    local report_file="$PROJECT_ROOT/__reports/geo-data-report.md"
    
    log "📊 Generating Geographic Data Report..."
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# 🌍 Geographic Data System Report

**Generated**: $(date)  
**Report Type**: Data Inventory and Analysis

## 📋 Data File Overview

### Core Data Files
EOF
    
    for file in "${GEO_DATA_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            echo "- ✅ \`$file\` ($size bytes)" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

### Schema Files
EOF
    
    for file in "${GEO_SCHEMA_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            echo "- ✅ \`$file\` ($size bytes)" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    # Add data analysis if jq is available
    local main_adjacency="what we've done/src/data/adjacency.json"
    if command -v jq >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/$main_adjacency" ]]; then
        local suburbs=$(jq -r 'keys | length' "$PROJECT_ROOT/$main_adjacency")
        local connections=$(jq -r '[.[] | if type == "array" then length else (.adjacent_suburbs // [] | length) end] | add' "$PROJECT_ROOT/$main_adjacency")
        
        cat >> "$report_file" << EOF

## 📊 Data Analysis

### Adjacency Network
- **Total Suburbs**: $suburbs
- **Total Connections**: $connections
- **Average Connections**: $((connections / suburbs))

### Top Connected Suburbs
EOF
        
        jq -r 'to_entries | map({key: .key, count: (if .value | type == "array" then .value | length else .value.adjacent_suburbs // [] | length end)}) | sort_by(.count) | reverse | .[0:5] | .[] | "- **\(.key)**: \(.count) connections"' "$PROJECT_ROOT/$main_adjacency" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 🎯 Quick Commands

\`\`\`bash
# Validate all geographic data
./geo-data.sh validate

# Analyze data integrity
./geo-data.sh analyze

# Sync data between locations
./geo-data.sh sync

# Backup geographic data
./geo-data.sh backup

# Generate this report
./geo-data.sh report
\`\`\`

## 📊 System Statistics

- **Data Files**: ${#GEO_DATA_FILES[@]}
- **Schema Files**: ${#GEO_SCHEMA_FILES[@]}
- **Processing Scripts**: ${#GEO_SCRIPT_FILES[@]}
- **Utility Handlers**: ${#IMPROVEMENT_GEO_FILES[@]}

---
*Generated by geo-data.sh*
EOF
    
    log "✅ Report generated: $report_file"
}

clean_files() {
    local force=$1
    
    log "🧹 Cleaning Geographic Data Temporary Files..."
    
    local temp_patterns=(
        "**/geo-*.tmp"
        "**/adjacency.*.bak"
        "**/clusters.*.bak"
        "**/.geo-cache"
        "**/geo-*.log"
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
        log "✅ Cleaned $cleaned temporary geographic files"
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
FORMAT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        list|validate|analyze|sync|backup|restore|optimize|report|clean|migrate)
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

# Execute command
case "$COMMAND" in
    list)
        list_files "$VERBOSE"
        ;;
    validate)
        validate_files "$VERBOSE"
        ;;
    analyze)
        analyze_data "$FORMAT"
        ;;
    sync)
        sync_data "$DRY_RUN"
        ;;
    backup)
        backup_data "$BACKUP_DIR" "$FORCE"
        ;;
    optimize)
        optimize_data "$FORCE"
        ;;
    report)
        generate_report
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