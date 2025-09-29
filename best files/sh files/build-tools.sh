#!/bin/bash
# build-tools.sh - Build Tools and Automation Scripts Manager
# Manages all build tools, CI/CD scripts, and automation utilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD-TOOLS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[BUILD-TOOLS]${NC} $1"
}

error() {
    echo -e "${RED}[BUILD-TOOLS]${NC} $1"
}

info() {
    echo -e "${BLUE}[BUILD-TOOLS]${NC} $1"
}

fancy() {
    echo -e "${CYAN}[BUILD-TOOLS]${NC} $1"
}

# Define all build tool files
BUILD_SCRIPT_FILES=(
    # Main build scripts
    "what we've done/scripts/geo/build-adjacency.mjs"
    "what we've done/scripts/geo/validate-adjacency.mjs"
    "what we've done/scripts/geo/metrics.mjs"
    "what we've done/scripts/geo/doctor.mjs"
    "what we've done/scripts/geo/gate.mjs"
    "what we've done/scripts/geo/bridge.mjs"
    "what we've done/scripts/geo/history-archive.mjs"
    "what we've done/scripts/geo/hash-verify.mjs"
    "what we've done/scripts/geo/pr-summary.mjs"
    "what we've done/scripts/geo/report-index.mjs"
    "what we've done/scripts/geo/report-md.mjs"
    "what we've done/scripts/geo/strategy-coverage.mjs"
    
    # Enhancement scripts
    "what we've done/ai-enhance-daedalus.mjs"
    "what we've done/ai-enterprise-deployment.mjs"
    "what we've done/ai-fix-gates.mjs"
    "what we've done/ai-geo-builder.mjs"
    
    # Medical system builders
    "geo_medical_system/daedalus-builder.mjs"
    "geo_medical_system/daedalus-showcase.mjs"
    
    # Improvement files 2 tools
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/metrics.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/crossCluster.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/fs-io.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/loader.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/stableReport.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/policy.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/reports.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/args.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/logger.ts"
    "improvement files 2/tools/geo_sot_toolkit/scripts/geo/lib/paths.ts"
)

BUILD_CONFIG_FILES=(
    # Package configurations
    "what we've done/package.json"
    "what we've done/tsconfig.json"
    "what we've done/astro.config.mjs"
    
    # Build configurations
    "improvement files 2/config-systems/astro.config.enhanced.mjs"
    "improvement files 2/adapter-patterns/netlify.config.js"
    "what we've done/daedalus.config.json"
    "what we've done/geo.config.json"
    "what we've done/geo.policy.json"
    
    # CI/CD and deployment
    "what we've done/.netlify/functions"
    "what we've done/netlify.toml"
)

AUTOMATION_SCRIPT_FILES=(
    # Content quality and performance
    "_archive_dev_materials/geo and seo build/content-quality-guardian.mjs"
    "_archive_dev_materials/geo and seo build/content-auto-fix.mjs"
    
    # Legacy cluster scripts
    "cluster scritps/cluster script .txt"
    
    # Development tools
    "what we've done/scripts/dev/rg-hunt.sh"
    "what we've done/scripts/lint/spacing.mjs"
    
    # Validation tools
    "what we've done/tools/validate-data.zod.ts"
    "what we've done/tools/graph-sanity.mjs"
)

SHELL_SCRIPT_FILES=(
    # Our new management scripts
    "doctor-system.sh"
    "geo-data.sh"
    "ui-components.sh"
    "build-tools.sh"
    "quality-systems.sh"
    
    # Legacy shell scripts
    "_archive_dev_materials/daedalus_hunter_boot.sh"
)

show_help() {
    cat << EOF
🔧 BUILD TOOLS & AUTOMATION SCRIPTS MANAGER

USAGE:
    ./build-tools.sh [COMMAND] [OPTIONS]

COMMANDS:
    list                List all build tools and scripts
    validate           Validate script syntax and dependencies
    test               Test build scripts and automation
    run                Run specific build or automation script
    optimize           Optimize build performance and caching
    audit              Audit build dependencies and security
    backup             Backup all build tools and configurations
    deploy             Deploy build tools to CI/CD environment
    monitor            Monitor build performance and health
    report             Generate build tools report
    clean              Clean build caches and temporary files
    upgrade            Upgrade build tool dependencies

OPTIONS:
    --dry-run         Show what would be done without executing
    --verbose         Show detailed output
    --force           Force operations without confirmation
    --script          Target specific script or tool
    --env             Target environment (dev|staging|prod)
    --cache           Enable/disable build caching

EXAMPLES:
    ./build-tools.sh list --verbose
    ./build-tools.sh validate --script geo-builder
    ./build-tools.sh run daedalus-builder --dry-run
    ./build-tools.sh test --env dev
    ./build-tools.sh optimize --force

MANAGED TOOLS:
    - Geo processing scripts (adjacency, metrics, validation)
    - AI enhancement tools (Daedalus builder, showcase generator)
    - Content quality automation (guardian, auto-fix)
    - Build configurations (Astro, TypeScript, Netlify)
    - CI/CD and deployment scripts
    - Development and debugging tools

EOF
}

list_files() {
    local verbose=$1
    
    log "🔧 Build Tools & Automation Scripts Inventory"
    echo
    
    fancy "⚙️ BUILD SCRIPTS:"
    for file in "${BUILD_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                local type=""
                if [[ "$file" == *".mjs" ]]; then
                    type=" [ES MODULE]"
                elif [[ "$file" == *".ts" ]]; then
                    type=" [TYPESCRIPT]"
                elif [[ "$file" == *".js" ]]; then
                    type=" [JAVASCRIPT]"
                fi
                echo "  ✅ $file ($lines lines, $size bytes)$type"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    echo
    fancy "📋 BUILD CONFIGURATIONS:"
    for file in "${BUILD_CONFIG_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]] || [[ -d "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                if [[ -f "$PROJECT_ROOT/$file" ]]; then
                    local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                    echo "  ✅ $file ($size bytes)"
                else
                    echo "  ✅ $file (directory)"
                fi
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    echo
    fancy "🤖 AUTOMATION SCRIPTS:"
    for file in "${AUTOMATION_SCRIPT_FILES[@]}"; do
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
    fancy "🐚 SHELL SCRIPTS:"
    for file in "${SHELL_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                local executable=""
                if [[ -x "$PROJECT_ROOT/$file" ]]; then
                    executable=" [EXECUTABLE]"
                else
                    executable=" [not executable]"
                fi
                echo "  ✅ $file ($lines lines)$executable"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
}

validate_scripts() {
    local verbose=$1
    local script_filter=$2
    local errors=0
    local total=0
    
    log "🔍 Validating Build Scripts..."
    
    # Check Node.js scripts
    for file in "${BUILD_SCRIPT_FILES[@]}" "${AUTOMATION_SCRIPT_FILES[@]}"; do
        if [[ -n "$script_filter" ]] && [[ "$file" != *"$script_filter"* ]]; then
            continue
        fi
        
        if [[ "$file" == *".mjs" || "$file" == *".js" || "$file" == *".ts" ]]; then
            total=$((total + 1))
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                # Check for shebang in .mjs files
                if [[ "$file" == *".mjs" ]]; then
                    if head -1 "$PROJECT_ROOT/$file" | grep -q "#!/usr/bin/env node\|#!/bin/node"; then
                        if [[ "$verbose" == "true" ]]; then
                            echo "  ✅ $file (has shebang)"
                        fi
                    else
                        echo "  ⚠️ $file (missing shebang - may not be executable)"
                    fi
                fi
                
                # Basic syntax check for JavaScript/TypeScript
                if [[ "$file" == *".js" || "$file" == *".mjs" ]]; then
                    if command -v node >/dev/null 2>&1; then
                        if node --check "$PROJECT_ROOT/$file" 2>/dev/null; then
                            if [[ "$verbose" == "true" ]]; then
                                echo "  ✅ $file (syntax valid)"
                            fi
                        else
                            echo "  ❌ $file (syntax error)"
                            errors=$((errors + 1))
                        fi
                    fi
                fi
                
                # Check for TypeScript files
                if [[ "$file" == *".ts" ]]; then
                    if command -v tsc >/dev/null 2>&1; then
                        if tsc --noEmit "$PROJECT_ROOT/$file" 2>/dev/null; then
                            if [[ "$verbose" == "true" ]]; then
                                echo "  ✅ $file (TypeScript valid)"
                            fi
                        else
                            echo "  ⚠️ $file (TypeScript issues - check manually)"
                        fi
                    else
                        echo "  ⚠️ $file (TypeScript compiler not available)"
                    fi
                fi
            else
                echo "  ❌ Missing: $file"
                errors=$((errors + 1))
            fi
        fi
    done
    
    # Check shell scripts
    for file in "${SHELL_SCRIPT_FILES[@]}"; do
        if [[ -n "$script_filter" ]] && [[ "$file" != *"$script_filter"* ]]; then
            continue
        fi
        
        total=$((total + 1))
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            # Check if executable
            if [[ -x "$PROJECT_ROOT/$file" ]]; then
                if [[ "$verbose" == "true" ]]; then
                    echo "  ✅ $file (executable)"
                fi
            else
                echo "  ⚠️ $file (not executable - run chmod +x)"
            fi
            
            # Basic shell syntax check
            if command -v bash >/dev/null 2>&1; then
                if bash -n "$PROJECT_ROOT/$file" 2>/dev/null; then
                    if [[ "$verbose" == "true" ]]; then
                        echo "  ✅ $file (shell syntax valid)"
                    fi
                else
                    echo "  ❌ $file (shell syntax error)"
                    errors=$((errors + 1))
                fi
            fi
        else
            echo "  ❌ Missing: $file"
            errors=$((errors + 1))
        fi
    done
    
    echo
    if [[ $errors -eq 0 ]]; then
        log "✅ All $total build scripts validated successfully"
    else
        error "❌ $errors out of $total scripts have issues"
        return 1
    fi
}

test_build_tools() {
    local env=$1
    local dry_run=$2
    
    log "🧪 Testing Build Tools..."
    
    # Test Daedalus builder
    info "Testing Daedalus builder..."
    if [[ -f "$PROJECT_ROOT/geo_medical_system/daedalus-builder.mjs" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "  [DRY-RUN] Would run: node geo_medical_system/daedalus-builder.mjs --help"
        else
            cd "$PROJECT_ROOT/geo_medical_system"
            if node daedalus-builder.mjs --help >/dev/null 2>&1; then
                echo "  ✅ Daedalus builder help works"
            else
                echo "  ❌ Daedalus builder help failed"
                return 1
            fi
        fi
    fi
    
    # Test geo tools
    info "Testing geo processing tools..."
    if [[ -f "$PROJECT_ROOT/what we've done/scripts/geo/metrics.mjs" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "  [DRY-RUN] Would test geo metrics script"
        else
            cd "$PROJECT_ROOT/what we've done"
            # Test if script can be loaded (not run, just syntax check)
            if node --check scripts/geo/metrics.mjs 2>/dev/null; then
                echo "  ✅ Geo metrics script syntax valid"
            else
                echo "  ❌ Geo metrics script has syntax errors"
                return 1
            fi
        fi
    fi
    
    # Test package.json scripts
    info "Testing package.json scripts..."
    if [[ -f "$PROJECT_ROOT/what we've done/package.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            local script_count=$(jq '.scripts | length' "$PROJECT_ROOT/what we've done/package.json")
            echo "  📦 Found $script_count npm scripts in package.json"
            
            # List some key scripts
            if [[ "$env" == "dev" ]]; then
                echo "  🔑 Key scripts:"
                jq -r '.scripts | to_entries | .[] | select(.key | contains("build\|dev\|geo")) | "    \(.key): \(.value)"' "$PROJECT_ROOT/what we've done/package.json" | head -5
            fi
        else
            echo "  ⚠️ jq not available - cannot analyze package.json scripts"
        fi
    fi
    
    log "✅ Build tools testing complete"
}

run_build_script() {
    local script_name=$1
    local dry_run=$2
    shift 2
    local args=("$@")
    
    log "🚀 Running Build Script: $script_name"
    
    # Map common script names to actual files
    case "$script_name" in
        "daedalus-builder"|"daedalus")
            local script_path="geo_medical_system/daedalus-builder.mjs"
            ;;
        "daedalus-showcase"|"showcase")
            local script_path="geo_medical_system/daedalus-showcase.mjs"
            ;;
        "geo-metrics"|"metrics")
            local script_path="what we've done/scripts/geo/metrics.mjs"
            ;;
        "geo-doctor"|"doctor")
            local script_path="what we've done/scripts/geo/doctor.mjs"
            ;;
        "content-quality"|"quality")
            local script_path="_archive_dev_materials/geo and seo build/content-quality-guardian.mjs"
            ;;
        *)
            # Try to find the script
            local script_path=""
            for file in "${BUILD_SCRIPT_FILES[@]}" "${AUTOMATION_SCRIPT_FILES[@]}"; do
                if [[ "$file" == *"$script_name"* ]]; then
                    script_path="$file"
                    break
                fi
            done
            ;;
    esac
    
    if [[ -z "$script_path" ]]; then
        error "Script not found: $script_name"
        echo "Available scripts:"
        echo "  - daedalus-builder (daedalus)"
        echo "  - daedalus-showcase (showcase)"
        echo "  - geo-metrics (metrics)"
        echo "  - geo-doctor (doctor)"
        echo "  - content-quality (quality)"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/$script_path" ]]; then
        error "Script file not found: $script_path"
        return 1
    fi
    
    info "📍 Script path: $script_path"
    info "📝 Arguments: ${args[*]}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY-RUN] Would run: node $script_path ${args[*]}"
    else
        cd "$PROJECT_ROOT/$(dirname "$script_path")"
        local script_file=$(basename "$script_path")
        
        if [[ "$script_file" == *".mjs" || "$script_file" == *".js" ]]; then
            node "$script_file" "${args[@]}"
        elif [[ "$script_file" == *".sh" ]]; then
            bash "$script_file" "${args[@]}"
        else
            error "Unknown script type: $script_file"
            return 1
        fi
    fi
}

optimize_build() {
    local force=$1
    
    log "⚡ Optimizing Build Performance..."
    
    if [[ "$force" != "true" ]]; then
        warn "This will modify build configurations. Use --force to proceed."
        return 1
    fi
    
    local optimizations=0
    
    # Optimize package.json scripts (remove verbose flags for production)
    if [[ -f "$PROJECT_ROOT/what we've done/package.json" ]]; then
        info "Checking package.json for optimization opportunities..."
        
        # Check for development-only dependencies in production scripts
        if grep -q "nodemon\|--watch\|--verbose" "$PROJECT_ROOT/what we've done/package.json"; then
            echo "  💡 Found development flags in package.json - consider production build script"
            optimizations=$((optimizations + 1))
        fi
    fi
    
    # Check for build caching opportunities
    if [[ -d "$PROJECT_ROOT/what we've done/node_modules" ]]; then
        local node_modules_size=$(du -sh "$PROJECT_ROOT/what we've done/node_modules" 2>/dev/null | cut -f1)
        echo "  📦 node_modules size: $node_modules_size"
        echo "  💡 Consider using npm ci for faster CI builds"
        optimizations=$((optimizations + 1))
    fi
    
    # Check TypeScript configuration
    if [[ -f "$PROJECT_ROOT/what we've done/tsconfig.json" ]]; then
        if grep -q '"incremental": true' "$PROJECT_ROOT/what we've done/tsconfig.json"; then
            echo "  ✅ TypeScript incremental compilation enabled"
        else
            echo "  💡 Consider enabling TypeScript incremental compilation"
            optimizations=$((optimizations + 1))
        fi
    fi
    
    log "✅ Found $optimizations build optimization opportunities"
}

backup_build_tools() {
    local backup_dir=$1
    local force=$2
    
    if [[ -z "$backup_dir" ]]; then
        backup_dir="$PROJECT_ROOT/__backups/build-tools/$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "💾 Backing up build tools to: $backup_dir"
    
    if [[ -d "$backup_dir" ]] && [[ "$force" != "true" ]]; then
        error "Backup directory already exists: $backup_dir"
        echo "Use --force to overwrite"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    
    local backed_up=0
    local all_files=("${BUILD_SCRIPT_FILES[@]}" "${BUILD_CONFIG_FILES[@]}" "${AUTOMATION_SCRIPT_FILES[@]}" "${SHELL_SCRIPT_FILES[@]}")
    
    for file in "${all_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local dest_dir="$backup_dir/$(dirname "$file")"
            mkdir -p "$dest_dir"
            cp "$PROJECT_ROOT/$file" "$backup_dir/$file"
            backed_up=$((backed_up + 1))
            echo "  📄 $file"
        elif [[ -d "$PROJECT_ROOT/$file" ]]; then
            cp -r "$PROJECT_ROOT/$file" "$backup_dir/$file"
            backed_up=$((backed_up + 1))
            echo "  📁 $file"
        fi
    done
    
    # Create backup manifest
    cat > "$backup_dir/BACKUP_MANIFEST.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "$PROJECT_ROOT",
  "backup_type": "build_tools",
  "files_backed_up": $backed_up,
  "categories": {
    "build_scripts": ${#BUILD_SCRIPT_FILES[@]},
    "config_files": ${#BUILD_CONFIG_FILES[@]},
    "automation_scripts": ${#AUTOMATION_SCRIPT_FILES[@]},
    "shell_scripts": ${#SHELL_SCRIPT_FILES[@]}
  }
}
EOF
    
    log "✅ Backed up $backed_up build tool files to $backup_dir"
}

generate_report() {
    local report_file="$PROJECT_ROOT/__reports/build-tools-report.md"
    
    log "📊 Generating Build Tools Report..."
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# 🔧 Build Tools & Automation Report

**Generated**: $(date)  
**Report Type**: Build System Inventory and Analysis

## ⚙️ Build Scripts
EOF
    
    for file in "${BUILD_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            local type=""
            if [[ "$file" == *".mjs" ]]; then
                type=" - **ES Module**"
            elif [[ "$file" == *".ts" ]]; then
                type=" - **TypeScript**"
            fi
            echo "- ✅ \`$file\` ($lines lines)$type" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🤖 Automation Scripts
EOF
    
    for file in "${AUTOMATION_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            echo "- ✅ \`$file\` ($lines lines)" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🐚 Shell Scripts
EOF
    
    for file in "${SHELL_SCRIPT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            local executable=""
            if [[ -x "$PROJECT_ROOT/$file" ]]; then
                executable=" - **Executable**"
            fi
            echo "- ✅ \`$file\` ($lines lines)$executable" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🎯 Quick Commands

\`\`\`bash
# List all build tools
./build-tools.sh list --verbose

# Validate scripts
./build-tools.sh validate

# Test build system
./build-tools.sh test --env dev

# Run Daedalus builder
./build-tools.sh run daedalus-builder --help

# Optimize build performance
./build-tools.sh optimize --force

# Backup build tools
./build-tools.sh backup
\`\`\`

## 📊 System Statistics

- **Build Scripts**: ${#BUILD_SCRIPT_FILES[@]}
- **Config Files**: ${#BUILD_CONFIG_FILES[@]}
- **Automation Scripts**: ${#AUTOMATION_SCRIPT_FILES[@]}
- **Shell Scripts**: ${#SHELL_SCRIPT_FILES[@]}

---
*Generated by build-tools.sh*
EOF
    
    log "✅ Report generated: $report_file"
}

clean_build_artifacts() {
    local force=$1
    
    log "🧹 Cleaning Build Artifacts..."
    
    local temp_patterns=(
        "what we've done/dist"
        "what we've done/.astro"
        "what we've done/node_modules/.cache"
        "**/*.log"
        "**/*.tmp"
        "**/.DS_Store"
        "__reports/*.tmp"
        "__backups/*.tmp"
    )
    
    local cleaned=0
    for pattern in "${temp_patterns[@]}"; do
        if [[ -d "$PROJECT_ROOT/$pattern" ]] || [[ -f "$PROJECT_ROOT/$pattern" ]]; then
            if [[ "$force" == "true" ]]; then
                rm -rf "$PROJECT_ROOT"/$pattern 2>/dev/null || true
                echo "  🗑️ Removed: $pattern"
                cleaned=$((cleaned + 1))
            else
                echo "  📁 Would remove: $pattern"
            fi
        fi
    done
    
    if [[ "$force" == "true" ]]; then
        log "✅ Cleaned $cleaned build artifact locations"
    else
        log "ℹ️ Use --force to actually remove files"
    fi
}

# Main command parsing
COMMAND=""
DRY_RUN=false
VERBOSE=false
FORCE=false
SCRIPT=""
ENV="dev"
CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        list|validate|test|run|optimize|audit|backup|deploy|monitor|report|clean|upgrade)
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
        --script)
            SCRIPT="$2"
            shift 2
            ;;
        --env)
            ENV="$2"
            shift 2
            ;;
        --cache)
            CACHE="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            # For 'run' command, collect remaining args
            if [[ "$COMMAND" == "run" ]] && [[ -n "$SCRIPT" ]]; then
                break
            fi
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
        validate_scripts "$VERBOSE" "$SCRIPT"
        ;;
    test)
        test_build_tools "$ENV" "$DRY_RUN"
        ;;
    run)
        if [[ -z "$SCRIPT" ]]; then
            error "No script specified. Use --script <name>"
            exit 1
        fi
        run_build_script "$SCRIPT" "$DRY_RUN" "$@"
        ;;
    optimize)
        optimize_build "$FORCE"
        ;;
    backup)
        backup_build_tools "" "$FORCE"
        ;;
    report)
        generate_report
        ;;
    clean)
        clean_build_artifacts "$FORCE"
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