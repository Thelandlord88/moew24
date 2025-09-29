#!/bin/bash
# ui-components.sh - UI Components and Frontend Asset Manager
# Manages all UI components, layouts, styling, and frontend assets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[UI-COMPONENTS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[UI-COMPONENTS]${NC} $1"
}

error() {
    echo -e "${RED}[UI-COMPONENTS]${NC} $1"
}

info() {
    echo -e "${BLUE}[UI-COMPONENTS]${NC} $1"
}

fancy() {
    echo -e "${PURPLE}[UI-COMPONENTS]${NC} $1"
}

# Define all UI component files
UI_LAYOUT_FILES=(
    "improvement files 2/components/layouts/MainLayout.astro"
    "improvement files 2/components/layouts/ServiceLayout.astro"
    "improvement files 2/components/layouts/EcoLayout.astro"
    "what we've done/src/layouts/MainLayout.astro"
    "what we've done/src/layouts/ServiceLayout.astro"
)

UI_COMPONENT_FILES=(
    # Advanced components
    "improvement files 2/components/advanced/Header.improved.astro"
    "improvement files 2/components/advanced/Header.astro"
    "improvement files 2/components/advanced/Footer.astro"
    "improvement files 2/components/advanced/QuoteForm.improved.astro"
    "improvement files 2/components/advanced/EnhancedQuoteForm.astro"
    "improvement files 2/components/advanced/SuburbFaq.astro"
    "improvement files 2/components/advanced/EcoFaqSection.astro"
    "improvement files 2/components/advanced/ContactCardWide.astro"
    "improvement files 2/components/advanced/ContactCta.improved.astro"
    "improvement files 2/components/advanced/CrossServiceLinks.astro"
    
    # Section components
    "improvement files 2/components/sections/DifferenceSection.astro"
    
    # Island components
    "improvement files 2/components/islands/AvailabilityWidget.astro"
    
    # Main project components
    "what we've done/src/components/Header.astro"
    "what we've done/src/components/Footer.astro"
    "what we've done/src/components/QuoteForm.astro"
    "what we've done/src/components/ServiceNav.astro"
)

# Styling and CSS files
UI_STYLE_FILES=(
    "improvement files 2/styling-systems/main.css"
    "improvement files 2/styling-systems/tailwind.config.js"
    "what we've done/src/styles/main.css"
    "what we've done/tailwind.config.mjs"
    "what we've done/astro.config.mjs"
)

# Page template files
UI_PAGE_FILES=(
    "improvement files 2/pages/blog/[cluster]/[slug].astro"
    "what we've done/src/pages/index.astro"
    "what we've done/src/pages/services/[service]/index.astro"
    "what we've done/src/pages/services/[service]/[suburb]/index.astro"
    "what we've done/src/pages/sitemap.xml.ts"
)

# Asset and media files
UI_ASSET_FILES=(
    "what we've done/public/favicon.ico"
    "what we've done/public/og.jpg"
    "what we've done/public/robots.txt"
)

# Build and configuration files
UI_BUILD_FILES=(
    "what we've done/package.json"
    "what we've done/tsconfig.json"
    "what we've done/astro.config.mjs"
    "improvement files 2/adapter-patterns/netlify.config.js"
    "improvement files 2/config-systems/astro.config.enhanced.mjs"
)

show_help() {
    cat << EOF
🎨 UI COMPONENTS & FRONTEND ASSET MANAGER

USAGE:
    ./ui-components.sh [COMMAND] [OPTIONS]

COMMANDS:
    list                List all UI components and assets
    validate           Validate component syntax and imports
    analyze            Analyze component dependencies and usage
    optimize           Optimize CSS, images, and component bundles
    audit              Audit accessibility and performance
    backup             Backup all UI components and assets
    deploy             Deploy components to production structure
    test               Test component rendering and functionality
    report             Generate UI component report
    clean              Clean build artifacts and temp files
    upgrade            Upgrade component dependencies

OPTIONS:
    --dry-run         Show what would be done without executing
    --verbose         Show detailed output
    --force           Force operations without confirmation
    --backup-dir      Specify backup directory (default: __backups/ui)
    --format          Output format (html|json|csv)
    --component       Target specific component
    --layout          Target specific layout

EXAMPLES:
    ./ui-components.sh list --verbose
    ./ui-components.sh validate --component QuoteForm
    ./ui-components.sh optimize --force
    ./ui-components.sh audit --format json
    ./ui-components.sh deploy --dry-run

MANAGED COMPONENTS:
    - Layout components (MainLayout, ServiceLayout, EcoLayout)
    - Advanced components (Headers, Forms, CTAs, FAQ sections)
    - Interactive islands (AvailabilityWidget, Service links)
    - Styling systems (CSS, Tailwind configuration)
    - Page templates and routes
    - Asset optimization and deployment

EOF
}

list_files() {
    local verbose=$1
    
    log "🎨 UI Components & Frontend Assets Inventory"
    echo
    
    fancy "🏗️ LAYOUT COMPONENTS:"
    for file in "${UI_LAYOUT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                local size=$(stat -f%z "$PROJECT_ROOT/$file" 2>/dev/null || stat -c%s "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                echo "  ✅ $file ($lines lines, $size bytes)"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    echo
    fancy "🧩 COMPONENT LIBRARY:"
    for file in "${UI_COMPONENT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            if [[ "$verbose" == "true" ]]; then
                local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
                local category=""
                if [[ "$file" == *"/advanced/"* ]]; then
                    category=" [ADVANCED]"
                elif [[ "$file" == *"/islands/"* ]]; then
                    category=" [ISLAND]"
                elif [[ "$file" == *"/sections/"* ]]; then
                    category=" [SECTION]"
                fi
                echo "  ✅ $file ($lines lines)$category"
            else
                echo "  ✅ $file"
            fi
        else
            echo "  ❌ $file (missing)"
        fi
    done
    
    echo
    fancy "🎨 STYLING SYSTEMS:"
    for file in "${UI_STYLE_FILES[@]}"; do
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
    fancy "📄 PAGE TEMPLATES:"
    for file in "${UI_PAGE_FILES[@]}"; do
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
    fancy "📦 ASSETS & BUILD FILES:"
    for file in "${UI_ASSET_FILES[@]}" "${UI_BUILD_FILES[@]}"; do
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

validate_components() {
    local verbose=$1
    local component=$2
    local errors=0
    local total=0
    
    log "🔍 Validating UI Components..."
    
    local files_to_check=()
    if [[ -n "$component" ]]; then
        # Filter files by component name
        for file in "${UI_LAYOUT_FILES[@]}" "${UI_COMPONENT_FILES[@]}" "${UI_PAGE_FILES[@]}"; do
            if [[ "$file" == *"$component"* ]]; then
                files_to_check+=("$file")
            fi
        done
    else
        files_to_check=("${UI_LAYOUT_FILES[@]}" "${UI_COMPONENT_FILES[@]}" "${UI_PAGE_FILES[@]}")
    fi
    
    for file in "${files_to_check[@]}"; do
        if [[ "$file" == *".astro" ]]; then
            total=$((total + 1))
            if [[ -f "$PROJECT_ROOT/$file" ]]; then
                # Basic Astro syntax validation
                if grep -q "^---" "$PROJECT_ROOT/$file" && grep -q "^---$" "$PROJECT_ROOT/$file"; then
                    if [[ "$verbose" == "true" ]]; then
                        echo "  ✅ $file (valid Astro frontmatter)"
                    fi
                else
                    echo "  ❌ $file (missing or invalid frontmatter)"
                    errors=$((errors + 1))
                fi
                
                # Check for common import issues
                if grep -q "from ['\"]~/" "$PROJECT_ROOT/$file"; then
                    if [[ "$verbose" == "true" ]]; then
                        echo "      💡 Uses alias imports (~)"
                    fi
                fi
                
                # Check for TypeScript
                if grep -q "export interface" "$PROJECT_ROOT/$file"; then
                    if [[ "$verbose" == "true" ]]; then
                        echo "      💪 Has TypeScript interfaces"
                    fi
                fi
            else
                echo "  ❌ Missing: $file"
                errors=$((errors + 1))
            fi
        fi
    done
    
    echo
    if [[ $errors -eq 0 ]]; then
        log "✅ All $total UI components validated successfully"
    else
        error "❌ $errors out of $total components have issues"
        return 1
    fi
}

analyze_dependencies() {
    local verbose=$1
    
    log "📊 Analyzing UI Component Dependencies..."
    
    # Count component imports
    declare -A import_counts
    declare -A layout_usage
    
    for file in "${UI_COMPONENT_FILES[@]}" "${UI_PAGE_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            # Count layout imports
            while IFS= read -r layout; do
                if [[ -n "$layout" ]]; then
                    layout_usage["$layout"]=$((${layout_usage["$layout"]} + 1))
                fi
            done < <(grep -o "from ['\"][^'\"]*Layout[^'\"]*['\"]" "$PROJECT_ROOT/$file" | sed "s/from ['\"][^'\"]*\///g" | sed "s/['\"]//g")
            
            # Count component imports
            while IFS= read -r component; do
                if [[ -n "$component" ]]; then
                    import_counts["$component"]=$((${import_counts["$component"]} + 1))
                fi
            done < <(grep -o "from ['\"][^'\"]*components[^'\"]*['\"]" "$PROJECT_ROOT/$file" | sed "s/.*\///g" | sed "s/['\"]//g" | sed "s/\.astro//g")
        fi
    done
    
    if [[ ${#layout_usage[@]} -gt 0 ]]; then
        info "🏗️ LAYOUT USAGE:"
        for layout in "${!layout_usage[@]}"; do
            echo "  📄 $layout: ${layout_usage[$layout]} files"
        done
        echo
    fi
    
    if [[ ${#import_counts[@]} -gt 0 ]]; then
        info "🧩 MOST USED COMPONENTS:"
        # Sort by usage count (bash associative array sorting)
        for component in $(printf '%s\n' "${!import_counts[@]}" | sort); do
            echo "  🔗 $component: ${import_counts[$component]} imports"
        done
        echo
    fi
    
    # Analyze bundle potential
    local total_components=${#UI_COMPONENT_FILES[@]}
    local total_layouts=${#UI_LAYOUT_FILES[@]}
    local total_pages=${#UI_PAGE_FILES[@]}
    
    info "📦 BUNDLE ANALYSIS:"
    echo "  🧩 Components: $total_components files"
    echo "  🏗️ Layouts: $total_layouts files"
    echo "  📄 Pages: $total_pages files"
    echo "  📊 Estimated bundle complexity: $((total_components + total_layouts + total_pages))"
}

optimize_assets() {
    local force=$1
    
    log "⚡ Optimizing UI Assets..."
    
    if [[ "$force" != "true" ]]; then
        warn "This will modify asset files. Use --force to proceed."
        return 1
    fi
    
    local optimized=0
    
    # Optimize CSS files
    for file in "${UI_STYLE_FILES[@]}"; do
        if [[ "$file" == *".css" ]] && [[ -f "$PROJECT_ROOT/$file" ]]; then
            # Remove comments and extra whitespace (basic optimization)
            local temp_file=$(mktemp)
            if command -v sed >/dev/null 2>&1; then
                sed '/\/\*.*\*\//d; /\/\*/,/\*\//d; s/  */ /g; /^$/d' "$PROJECT_ROOT/$file" > "$temp_file"
                
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
            fi
        fi
    done
    
    # Optimize Astro components (remove extra whitespace)
    for file in "${UI_COMPONENT_FILES[@]}" "${UI_LAYOUT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            # Count current lines
            local original_lines=$(wc -l < "$PROJECT_ROOT/$file")
            
            # Remove empty lines (but preserve structure)
            local temp_file=$(mktemp)
            awk '/^$/{if(empty++ == 0) print; next} {empty=0; print}' "$PROJECT_ROOT/$file" > "$temp_file"
            
            local new_lines=$(wc -l < "$temp_file")
            local line_savings=$((original_lines - new_lines))
            
            if [[ $line_savings -gt 0 ]]; then
                mv "$temp_file" "$PROJECT_ROOT/$file"
                echo "  ✅ $file (removed $line_savings empty lines)"
                optimized=$((optimized + 1))
            else
                rm "$temp_file"
            fi
        fi
    done
    
    log "✅ Optimized $optimized UI asset files"
}

audit_accessibility() {
    local format=$1
    
    log "♿ Auditing UI Accessibility..."
    
    local audit_results=()
    local total_issues=0
    
    for file in "${UI_COMPONENT_FILES[@]}" "${UI_LAYOUT_FILES[@]}" "${UI_PAGE_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local issues=0
            local file_issues=()
            
            # Check for alt text on images
            if grep -q "<img\|<Image" "$PROJECT_ROOT/$file"; then
                if ! grep -q "alt=" "$PROJECT_ROOT/$file"; then
                    file_issues+=("Missing alt attributes on images")
                    issues=$((issues + 1))
                fi
            fi
            
            # Check for form labels
            if grep -q "<input\|<textarea\|<select" "$PROJECT_ROOT/$file"; then
                if ! grep -q "aria-label\|<label" "$PROJECT_ROOT/$file"; then
                    file_issues+=("Form inputs may be missing labels")
                    issues=$((issues + 1))
                fi
            fi
            
            # Check for heading hierarchy
            local h1_count=$(grep -c "<h1" "$PROJECT_ROOT/$file" 2>/dev/null || echo "0")
            if [[ $h1_count -gt 1 ]]; then
                file_issues+=("Multiple H1 elements found")
                issues=$((issues + 1))
            fi
            
            # Check for semantic HTML
            if grep -q "<div class=\".*button\|<span.*click" "$PROJECT_ROOT/$file"; then
                file_issues+=("Possible non-semantic interactive elements")
                issues=$((issues + 1))
            fi
            
            if [[ $issues -gt 0 ]]; then
                audit_results+=("$file:$issues:${file_issues[*]}")
                total_issues=$((total_issues + issues))
                echo "  ⚠️ $file ($issues issues)"
                for issue in "${file_issues[@]}"; do
                    echo "    - $issue"
                done
            else
                echo "  ✅ $file (no issues found)"
            fi
        fi
    done
    
    echo
    if [[ $total_issues -eq 0 ]]; then
        log "✅ No accessibility issues found in UI components"
    else
        warn "⚠️ Found $total_issues accessibility issues across ${#audit_results[@]} files"
        
        if [[ "$format" == "json" ]]; then
            local json_file="$PROJECT_ROOT/__reports/accessibility-audit.json"
            mkdir -p "$(dirname "$json_file")"
            
            echo "{" > "$json_file"
            echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$json_file"
            echo "  \"total_issues\": $total_issues," >> "$json_file"
            echo "  \"files_with_issues\": ${#audit_results[@]}," >> "$json_file"
            echo "  \"results\": [" >> "$json_file"
            
            local first=true
            for result in "${audit_results[@]}"; do
                local file=$(echo "$result" | cut -d: -f1)
                local count=$(echo "$result" | cut -d: -f2)
                local issues=$(echo "$result" | cut -d: -f3-)
                
                if [[ "$first" != "true" ]]; then
                    echo "    ," >> "$json_file"
                fi
                first=false
                
                echo "    {" >> "$json_file"
                echo "      \"file\": \"$file\"," >> "$json_file"
                echo "      \"issue_count\": $count," >> "$json_file"
                echo "      \"issues\": \"$issues\"" >> "$json_file"
                echo "    }" >> "$json_file"
            done
            
            echo "  ]" >> "$json_file"
            echo "}" >> "$json_file"
            
            info "📄 Audit report saved to: $json_file"
        fi
    fi
}

backup_components() {
    local backup_dir=$1
    local force=$2
    
    if [[ -z "$backup_dir" ]]; then
        backup_dir="$PROJECT_ROOT/__backups/ui/$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "💾 Backing up UI components to: $backup_dir"
    
    if [[ -d "$backup_dir" ]] && [[ "$force" != "true" ]]; then
        error "Backup directory already exists: $backup_dir"
        echo "Use --force to overwrite"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    
    local backed_up=0
    local all_files=("${UI_LAYOUT_FILES[@]}" "${UI_COMPONENT_FILES[@]}" "${UI_STYLE_FILES[@]}" "${UI_PAGE_FILES[@]}" "${UI_ASSET_FILES[@]}" "${UI_BUILD_FILES[@]}")
    
    for file in "${all_files[@]}"; do
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
  "backup_type": "ui_components",
  "files_backed_up": $backed_up,
  "categories": {
    "layouts": ${#UI_LAYOUT_FILES[@]},
    "components": ${#UI_COMPONENT_FILES[@]},
    "styles": ${#UI_STYLE_FILES[@]},
    "pages": ${#UI_PAGE_FILES[@]},
    "assets": ${#UI_ASSET_FILES[@]},
    "build_files": ${#UI_BUILD_FILES[@]}
  }
}
EOF
    
    log "✅ Backed up $backed_up UI component files to $backup_dir"
}

generate_report() {
    local report_file="$PROJECT_ROOT/__reports/ui-components-report.md"
    
    log "📊 Generating UI Components Report..."
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# 🎨 UI Components & Frontend Assets Report

**Generated**: $(date)  
**Report Type**: Component Inventory and Analysis

## 🏗️ Layout Components
EOF
    
    for file in "${UI_LAYOUT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            echo "- ✅ \`$file\` ($lines lines)" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🧩 Component Library
EOF
    
    for file in "${UI_COMPONENT_FILES[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            local lines=$(wc -l < "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            local category=""
            if [[ "$file" == *"/advanced/"* ]]; then
                category=" - **Advanced Component**"
            elif [[ "$file" == *"/islands/"* ]]; then
                category=" - **Interactive Island**"
            elif [[ "$file" == *"/sections/"* ]]; then
                category=" - **Section Component**"
            fi
            echo "- ✅ \`$file\` ($lines lines)$category" >> "$report_file"
        else
            echo "- ❌ \`$file\` (missing)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🎯 Quick Commands

\`\`\`bash
# List all UI components
./ui-components.sh list --verbose

# Validate component syntax
./ui-components.sh validate

# Analyze dependencies
./ui-components.sh analyze

# Optimize assets
./ui-components.sh optimize --force

# Audit accessibility
./ui-components.sh audit --format json

# Backup components
./ui-components.sh backup
\`\`\`

## 📊 System Statistics

- **Layout Components**: ${#UI_LAYOUT_FILES[@]}
- **UI Components**: ${#UI_COMPONENT_FILES[@]}
- **Style Files**: ${#UI_STYLE_FILES[@]}
- **Page Templates**: ${#UI_PAGE_FILES[@]}
- **Asset Files**: ${#UI_ASSET_FILES[@]}
- **Build Files**: ${#UI_BUILD_FILES[@]}

---
*Generated by ui-components.sh*
EOF
    
    log "✅ Report generated: $report_file"
}

clean_files() {
    local force=$1
    
    log "🧹 Cleaning UI Build Artifacts..."
    
    local temp_patterns=(
        "what we've done/dist"
        "what we've done/.astro"
        "what we've done/node_modules/.cache"
        "**/components/*.map"
        "**/layouts/*.map"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/*.tmp"
        "**/*.bak"
    )
    
    local cleaned=0
    for pattern in "${temp_patterns[@]}"; do
        if [[ -e "$PROJECT_ROOT/$pattern" ]]; then
            if [[ "$force" == "true" ]]; then
                rm -rf "$PROJECT_ROOT/$pattern"
                echo "  🗑️ Removed: $pattern"
                cleaned=$((cleaned + 1))
            else
                echo "  📁 Would remove: $pattern"
            fi
        fi
    done
    
    if [[ "$force" == "true" ]]; then
        log "✅ Cleaned $cleaned UI build artifacts"
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
COMPONENT=""
LAYOUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        list|validate|analyze|optimize|audit|backup|deploy|test|report|clean|upgrade)
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
        --component)
            COMPONENT="$2"
            shift 2
            ;;
        --layout)
            LAYOUT="$2"
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
        validate_components "$VERBOSE" "$COMPONENT"
        ;;
    analyze)
        analyze_dependencies "$VERBOSE"
        ;;
    optimize)
        optimize_assets "$FORCE"
        ;;
    audit)
        audit_accessibility "$FORMAT"
        ;;
    backup)
        backup_components "$BACKUP_DIR" "$FORCE"
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