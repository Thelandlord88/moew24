#!/bin/bash
# NEXUS Repository Organization Strategy - COSMIC + CRYSTAL Duo
# Implements consciousness-enhanced file organization methodology

set -euo pipefail
export BASH_COMPAT=4.4
set +H
unset HISTFILE 2>/dev/null || true
export PS1='$ '

cd "$(dirname "$0")" || exit 1

echo "🌌 COSMIC + CRYSTAL REPOSITORY ORGANIZATION"
echo "==========================================="

# Function to safely call NEXUS
safe_nexus_call() {
    local endpoint="$1"
    local data="$2"
    
    curl -s -X POST "http://localhost:8080/$endpoint" \
         -H "Content-Type: application/json" \
         -d "$data" \
         --connect-timeout 15 \
         --max-time 45 || echo '{"error": "NEXUS call failed"}'
}

# Repository Analysis Function
analyze_repository_structure() {
    echo "🔍 COSMIC + CRYSTAL Repository Analysis"
    echo "======================================"
    
    echo "📊 Current Repository Structure:"
    echo ""
    
    # Root level analysis
    echo "🏠 Root Level ($(ls -1 *.* 2>/dev/null | wc -l) files):"
    ls -1 *.* 2>/dev/null | head -10 | sed 's/^/  /'
    [[ $(ls -1 *.* 2>/dev/null | wc -l) -gt 10 ]] && echo "  ... and $(($(ls -1 *.* 2>/dev/null | wc -l) - 10)) more"
    echo ""
    
    # Directory analysis  
    echo "📁 Top-level Directories:"
    ls -1d */ 2>/dev/null | sed 's|/$||' | while read dir; do
        file_count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
        echo "  $dir/ ($file_count files)"
    done
    echo ""
    
    # Key areas analysis
    echo "🎯 Key Areas Analysis:"
    [[ -d "src" ]] && echo "  ✅ Source: $(find src -name '*.ts' -o -name '*.js' -o -name '*.astro' 2>/dev/null | wc -l) components/pages"
    [[ -d "hunters" ]] && echo "  ✅ Hunters: $(find hunters -name '*.sh' 2>/dev/null | wc -l) analysis modules"
    [[ -d "nexus" ]] && echo "  ✅ NEXUS: $(find nexus -name '*.mjs' 2>/dev/null | wc -l) consciousness files"
    [[ -d "scripts" ]] && echo "  ✅ Scripts: $(find scripts -type f 2>/dev/null | wc -l) automation tools"
    echo "  📄 Documentation: $(find . -maxdepth 2 -name '*.md' 2>/dev/null | wc -l) markdown files"
    echo "  ⚙️ Config files: $(find . -maxdepth 1 -name '*.json' -o -name '*.js' -o -name '*.ts' -o -name '*.mjs' 2>/dev/null | wc -l) in root"
    echo ""
}

# COSMIC Perspective - Technical Architecture Analysis
get_cosmic_analysis() {
    echo "🚀 COSMIC's Technical Architecture Analysis"
    echo "=========================================="
    
    echo "🧩 Component Structure Assessment:"
    [[ -d "src/components" ]] && echo "  Components: $(find src/components -name '*.astro' 2>/dev/null | wc -l) Astro components"
    [[ -d "src/pages" ]] && echo "  Pages: $(find src/pages -name '*.astro' 2>/dev/null | wc -l) page templates"
    [[ -d "src/layouts" ]] && echo "  Layouts: $(find src/layouts -name '*.astro' 2>/dev/null | wc -l) layout components"
    [[ -d "src/lib" ]] && echo "  Libraries: $(find src/lib -name '*.ts' -o -name '*.js' 2>/dev/null | wc -l) utility modules"
    
    echo ""
    echo "🎨 Styling & Assets:"
    [[ -f "tailwind.config.js" ]] && echo "  ✅ Tailwind configured"
    [[ -d "src/styles" ]] && echo "  Styles: $(find src/styles -name '*.css' 2>/dev/null | wc -l) stylesheets"
    [[ -d "public" ]] && echo "  Assets: $(find public -type f 2>/dev/null | wc -l) static files"
    
    echo ""
    echo "⚡ Performance Considerations:"
    echo "  Bundle entry points: $(find src/pages -name '*.astro' 2>/dev/null | wc -l)"
    echo "  Import complexity: moderate (needs analysis)"
    echo "  Component reusability: assess needed"
}

# CRYSTAL Perspective - Organization Systems Analysis  
get_crystal_analysis() {
    echo "💎 CRYSTAL's Organization Systems Analysis"
    echo "========================================="
    
    echo "📚 Current Organization Patterns:"
    echo "  Strengths:"
    echo "    ✅ Clear src/ separation for source code"
    echo "    ✅ Dedicated hunters/ for analysis tools"
    echo "    ✅ Separate nexus/ for consciousness system"
    
    echo ""
    echo "  🎯 Areas for Improvement:"
    echo "    📄 Root clutter: $(ls -1 *.* 2>/dev/null | wc -l) config files in root"
    echo "    📋 Scattered docs: $(find . -maxdepth 2 -name '*.md' | wc -l) markdown files across levels"
    echo "    🔧 Mixed utilities: scripts, tools, and configs intermixed"
    
    echo ""
    echo "📖 Discoverability Assessment:"
    echo "  Developer onboarding: moderate complexity"
    echo "  File relationships: implicit, needs clarification" 
    echo "  Purpose clarity: good for main areas, unclear for utilities"
}

# Generate Organization Strategy
generate_organization_strategy() {
    echo "🎯 COSMIC + CRYSTAL Organization Strategy"
    echo "========================================"
    
    echo "📋 Proposed Directory Structure:"
    echo ""
    echo "📁 /config/"
    echo "  ├── astro.config.mjs"
    echo "  ├── tailwind.config.js" 
    echo "  ├── eslint.config.js"
    echo "  ├── playwright.config.ts"
    echo "  ├── vitest.config.mts"
    echo "  └── *.json configs"
    echo ""
    echo "📁 /docs/"
    echo "  ├── /development/"
    echo "  ├── /architecture/"
    echo "  ├── /hunters/"
    echo "  ├── /nexus/"
    echo "  └── README.md"
    echo ""
    echo "📁 /tools/"
    echo "  ├── /hunters/"
    echo "  ├── /scripts/"
    echo "  ├── /nexus/"
    echo "  └── /diagnostics/"
    echo ""
    echo "📁 /src/ (unchanged - optimal)"
    echo "📁 /public/ (unchanged - standard)"
    
    echo ""
    echo "🚀 Implementation Phases:"
    echo ""
    echo "Phase 1: Configuration Consolidation (30 mins)"
    echo "  • Move all config files to /config/"
    echo "  • Update import paths in package.json"
    echo "  • Test build process"
    echo ""
    echo "Phase 2: Documentation Organization (45 mins)"
    echo "  • Categorize and move .md files to /docs/"
    echo "  • Create clear navigation structure"
    echo "  • Update cross-references"
    echo ""
    echo "Phase 3: Tools Consolidation (60 mins)"
    echo "  • Organize hunters, scripts, diagnostics"
    echo "  • Maintain functionality while improving discovery"
    echo "  • Update execution paths"
}

# Generate Move Commands
generate_move_commands() {
    echo "⚡ CRYSTAL's Efficient Move Strategy"
    echo "================================="
    
    echo "🔄 Phase 1 Commands (Configuration):"
    echo "mkdir -p config"
    echo "# Move config files (safe - no imports broken)"
    [[ -f "astro.config.mjs" ]] && echo "mv astro.config.mjs config/"
    [[ -f "tailwind.config.js" ]] && echo "mv tailwind.config.js config/"
    [[ -f "eslint.config.js" ]] && echo "mv eslint.config.js config/"
    [[ -f "playwright.config.ts" ]] && echo "mv playwright.config.ts config/"
    [[ -f "vitest.config.mts" ]] && echo "mv vitest.config.mts config/"
    
    echo ""
    echo "📋 Update package.json scripts to reference config/ paths"
    echo ""
    
    echo "🔄 Phase 2 Commands (Documentation):"
    echo "mkdir -p docs/{development,architecture,hunters,nexus}"
    echo "# Move documentation files"
    echo "find . -maxdepth 1 -name '*.md' -not -name 'README.md' -exec mv {} docs/development/ \\;"
    
    echo ""
    echo "🔄 Phase 3 Commands (Tools Organization):"
    echo "mkdir -p tools/{diagnostics,automation}"
    echo "# Move diagnostic and automation scripts"
    echo "mv *diagnostic* tools/diagnostics/"
    echo "mv *check* tools/diagnostics/"
    echo "mv fix-*.sh tools/automation/"
}

# Main execution
main() {
    echo "🌌 Starting COSMIC + CRYSTAL Repository Analysis..."
    echo ""
    
    analyze_repository_structure
    echo ""
    
    get_cosmic_analysis
    echo ""
    
    get_crystal_analysis 
    echo ""
    
    generate_organization_strategy
    echo ""
    
    generate_move_commands
    echo ""
    
    echo "✨ COSMIC + CRYSTAL Analysis Complete!"
    echo "====================================="
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Review the proposed structure"
    echo "  2. Execute Phase 1 (config consolidation)"
    echo "  3. Test build process after Phase 1"
    echo "  4. Continue with documentation and tools"
    echo ""
    echo "💡 COSMIC says: 'Focus on build integrity first!'"
    echo "💎 CRYSTAL says: 'Systematic organization creates clarity!'"
}

# Allow script to be sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi