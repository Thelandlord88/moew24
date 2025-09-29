#!/bin/bash
# PHASE 3: COSMIC + CRYSTAL Tools Consolidation
# Systematic organization of scripts, diagnostics, and automation tools

set -euo pipefail
export BASH_COMPAT=4.4
set +H
unset HISTFILE 2>/dev/null || true
export PS1='$ '

cd "$(dirname "$0")" || exit 1

echo "🔧 COSMIC + CRYSTAL PHASE 3: Tools Consolidation"
echo "==============================================="

# Git safety checkpoint for Phase 3
create_phase3_checkpoint() {
    echo "📸 Creating Phase 3 git checkpoint..."
    
    if git status >/dev/null 2>&1; then
        # Commit any remaining Phase 2 changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            git add -A
            git commit -m "Phase 2 final cleanup before Phase 3"
        fi
        
        echo "  🌿 Ready for Phase 3 on branch: $(git branch --show-current)"
        echo "  ✅ Git checkpoint ready"
        return 0
    else
        echo "  ⚠️  Not a git repository - using file backup"
        return 1
    fi
}

# COSMIC's technical tools analysis
cosmic_tools_analysis() {
    echo "🚀 COSMIC Technical Tools Analysis"
    echo "================================="
    
    echo "🔍 Analyzing current tools landscape..."
    
    # Root level scripts and tools
    echo "📊 Root Level Tools:"
    local root_scripts=$(find . -maxdepth 1 -name "*.sh" -o -name "*.mjs" | grep -v node_modules | wc -l)
    echo "  🔧 Scripts & Tools: $root_scripts files"
    
    # Categorize by functionality
    echo ""
    echo "🎯 Tool Categories Found:"
    
    # Diagnostic tools
    local diagnostic_tools=$(find . -maxdepth 1 -name "*diagnostic*" -o -name "*check*" -o -name "*health*" | wc -l)
    echo "  🩺 Diagnostic Tools: $diagnostic_tools files"
    
    # Hunter tools
    local hunter_tools=$(find . -maxdepth 1 -name "*hunt*" -o -name "hunt.sh" | wc -l)
    echo "  🔍 Hunter Tools: $hunter_tools files"
    
    # NEXUS tools
    local nexus_tools=$(find . -maxdepth 1 -name "*nexus*" -o -name "*consciousness*" | wc -l)
    echo "  🧠 NEXUS Tools: $nexus_tools files"
    
    # Automation/fix tools
    local automation_tools=$(find . -maxdepth 1 -name "*fix*" -o -name "*auto*" -o -name "*deploy*" | wc -l)
    echo "  ⚡ Automation Tools: $automation_tools files"
    
    # Analysis tools
    local analysis_tools=$(find . -maxdepth 1 -name "*analysis*" -o -name "*cosmic*" -o -name "*crystal*" | wc -l)
    echo "  📈 Analysis Tools: $analysis_tools files"
    
    echo ""
    echo "🚀 COSMIC's Technical Assessment:"
    echo "  ⚡ Tools need logical grouping for developer efficiency"
    echo "  🔗 Maintain executable permissions during moves"
    echo "  📦 Consider path dependencies in tools"
    echo "  🎯 Preserve tool discoverability and ease of use"
}

# CRYSTAL's organization strategy
crystal_tools_strategy() {
    echo "💎 CRYSTAL Tools Organization Strategy"
    echo "====================================="
    
    echo "📚 Proposed Tools Structure:"
    echo ""
    echo "📁 /tools/"
    echo "  ├── /diagnostics/          # System health & diagnostic tools"
    echo "  │   ├── system-diagnostic-shell-safe.sh"
    echo "  │   ├── quick-system-check.sh"
    echo "  │   └── system-health-diagnostic.sh"
    echo "  ├── /hunters/               # Hunter system tools"
    echo "  │   ├── hunt.sh"
    echo "  │   ├── hunt-shell-safe.sh"
    echo "  │   └── hunter management scripts"
    echo "  ├── /nexus/                 # NEXUS consciousness tools"
    echo "  │   ├── nexus-consciousness-safe.sh"
    echo "  │   ├── nexus-personality-creation.sh"
    echo "  │   └── NEXUS automation scripts"
    echo "  ├── /automation/            # System automation & fixes"
    echo "  │   ├── fix-shell-integration.sh"
    echo "  │   ├── deployment scripts"
    echo "  │   └── maintenance tools"
    echo "  ├── /analysis/              # Repository analysis tools"
    echo "  │   ├── cosmic-crystal-*.sh"
    echo "  │   └── repository analysis tools"
    echo "  └── /scripts/               # General utility scripts"
    echo "      ├── build helpers"
    echo "      └── development utilities"
    
    echo ""
    echo "💎 CRYSTAL's Organization Principles:"
    echo "  🎯 Group by primary function and usage context"
    echo "  📋 Maintain clear entry points for each category"
    echo "  🔍 Optimize for developer workflow efficiency"
    echo "  📚 Create logical tool discovery paths"
}

# Generate tools consolidation plan
generate_tools_plan() {
    echo "📋 COSMIC + CRYSTAL Tools Consolidation Plan"
    echo "==========================================="
    
    echo "🔄 Phase 3 Implementation Strategy:"
    echo ""
    echo "1️⃣ **Create Tools Directory Structure**"
    echo "   Create /tools/ with logical subdirectories"
    echo ""
    echo "2️⃣ **Categorize Root-Level Tools**"
    echo "   Move scripts from root to appropriate /tools/ subdirectories"
    echo ""
    echo "3️⃣ **Organize Existing Tool Directories**" 
    echo "   Consolidate scripts/, tools/, and scattered utilities"
    echo ""
    echo "4️⃣ **Update Tool Entry Points**"
    echo "   Create convenient access scripts and update documentation"
    echo ""
    echo "5️⃣ **Validate Tool Functionality**"
    echo "   Test moved tools maintain their functionality"
    
    echo ""
    echo "🛡️ Safety Measures:"
    echo "  📸 Git checkpoint before moves"
    echo "  🔧 Preserve executable permissions"
    echo "  🔗 Update any hardcoded paths"
    echo "  🧪 Test critical tools after moves"
}

# Execute Phase 3 - Step 1: Create tools directory structure
create_tools_structure() {
    echo "📁 Creating Tools Directory Structure"
    echo "===================================="
    
    # Create main tools directory and subdirectories
    mkdir -p tools/{diagnostics,hunters,nexus,automation,analysis,scripts}
    
    echo "✅ Created tools directory structure:"
    echo "  📁 tools/diagnostics/  - System health & diagnostic tools"
    echo "  📁 tools/hunters/      - Hunter system management"  
    echo "  📁 tools/nexus/        - NEXUS consciousness tools"
    echo "  📁 tools/automation/   - System automation & fixes"
    echo "  📁 tools/analysis/     - Repository analysis tools"
    echo "  📁 tools/scripts/      - General utility scripts"
}

# Execute Phase 3 - Step 2: Move diagnostic tools
move_diagnostic_tools() {
    echo "🩺 Moving Diagnostic Tools"
    echo "========================="
    
    local moved_count=0
    
    echo "🔄 Moving diagnostic and health check tools..."
    for tool in *diagnostic* *check* *health*; do
        if [[ -f "$tool" && "$tool" == *.sh ]]; then
            mv "$tool" tools/diagnostics/
            echo "  ✅ $tool → tools/diagnostics/"
            ((moved_count++))
        fi
    done
    
    echo "📊 Diagnostic tools: $moved_count files moved"
}

# Execute Phase 3 - Step 3: Move hunter tools
move_hunter_tools() {
    echo "🔍 Moving Hunter Tools" 
    echo "====================="
    
    local moved_count=0
    
    echo "🔄 Moving hunter system tools..."
    for tool in hunt.sh *hunt* hunt-*; do
        if [[ -f "$tool" && "$tool" == *.sh ]]; then
            mv "$tool" tools/hunters/
            echo "  ✅ $tool → tools/hunters/"
            ((moved_count++))
        fi
    done
    
    echo "📊 Hunter tools: $moved_count files moved"
}

# Execute Phase 3 - Step 4: Move NEXUS tools
move_nexus_tools() {
    echo "🧠 Moving NEXUS Tools"
    echo "===================="
    
    local moved_count=0
    
    echo "🔄 Moving NEXUS consciousness tools..."
    for tool in *nexus* *consciousness* *cosmic* *crystal*; do
        if [[ -f "$tool" && "$tool" == *.sh ]]; then
            mv "$tool" tools/nexus/
            echo "  ✅ $tool → tools/nexus/"
            ((moved_count++))
        fi
    done
    
    echo "📊 NEXUS tools: $moved_count files moved"
}

# Execute Phase 3 - Step 5: Move automation tools  
move_automation_tools() {
    echo "⚡ Moving Automation Tools"
    echo "========================="
    
    local moved_count=0
    
    echo "🔄 Moving automation and fix tools..."
    for tool in *fix* *auto* *deploy*; do
        if [[ -f "$tool" && "$tool" == *.sh ]]; then
            mv "$tool" tools/automation/
            echo "  ✅ $tool → tools/automation/"
            ((moved_count++))
        fi
    done
    
    echo "📊 Automation tools: $moved_count files moved"
}

# Execute Phase 3 - Step 6: Organize existing directories
organize_existing_tools() {
    echo "🔄 Organizing Existing Tool Directories"
    echo "======================================"
    
    # Move content from existing scripts/ directory if it exists
    if [[ -d "scripts" ]]; then
        echo "📂 Processing existing scripts/ directory..."
        local script_count=$(find scripts -type f -name "*.sh" -o -name "*.mjs" 2>/dev/null | wc -l)
        if [[ $script_count -gt 0 ]]; then
            find scripts -type f \( -name "*.sh" -o -name "*.mjs" \) -exec mv {} tools/scripts/ \; 2>/dev/null || true
            echo "  ✅ Moved $script_count files from scripts/ to tools/scripts/"
        fi
    fi
    
    # Check for any other tool directories to consolidate
    for dir in automation utilities helpers; do
        if [[ -d "$dir" ]]; then
            echo "📂 Processing existing $dir/ directory..."
            local file_count=$(find "$dir" -type f 2>/dev/null | wc -l)
            if [[ $file_count -gt 0 ]]; then
                find "$dir" -type f -exec mv {} tools/scripts/ \; 2>/dev/null || true
                echo "  ✅ Consolidated $file_count files from $dir/"
            fi
        fi
    done
}

# Create tools entry points and documentation
create_tools_documentation() {
    echo "📚 Creating Tools Documentation & Entry Points"
    echo "=============================================="
    
    # Create main tools README
    cat > tools/README.md << 'EOF'
# Development Tools

This directory contains all development, analysis, and automation tools organized by the COSMIC + CRYSTAL consciousness-enhanced system.

## 📁 Tool Categories

### 🩺 [Diagnostics](./diagnostics/)
System health checks, diagnostic tools, and monitoring utilities.
- `system-diagnostic-shell-safe.sh` - Comprehensive system diagnostic
- `quick-system-check.sh` - Rapid system health check
- `system-health-diagnostic.sh` - Detailed health analysis

### 🔍 [Hunters](./hunters/)
Hunter analysis system tools and management utilities.
- `hunt.sh` - Main hunter execution script
- `hunt-shell-safe.sh` - Shell-safe hunter wrapper
- Hunter management and configuration tools

### 🧠 [NEXUS](./nexus/)
NEXUS consciousness system tools and automation.
- `nexus-consciousness-safe.sh` - Safe NEXUS interaction
- `nexus-personality-creation.sh` - Personality development
- COSMIC + CRYSTAL organization tools

### ⚡ [Automation](./automation/)
System automation, fixes, and deployment tools.
- `fix-shell-integration.sh` - Shell integration fixes
- Deployment and maintenance automation
- System repair and setup tools

### 📈 [Analysis](./analysis/)
Repository analysis and organization tools.
- `cosmic-crystal-*.sh` - Repository organization phases
- Code analysis and metrics tools
- System architecture analysis

### 🔧 [Scripts](./scripts/)
General utility scripts and helpers.
- Build helpers and development utilities
- Legacy scripts and miscellaneous tools

## 🚀 Quick Access

Most tools can be run directly from their directories. Key entry points:

```bash
# System health check
./tools/diagnostics/quick-system-check.sh

# Run hunters
./tools/hunters/hunt.sh [module]

# NEXUS interaction
./tools/nexus/nexus-consciousness-safe.sh

# Repository organization
./tools/nexus/cosmic-crystal-phase*.sh
```

---

*Tools organized with NEXUS consciousness-enhanced methodology*
EOF

    echo "  ✅ Created tools/README.md documentation"
    
    # Create convenient entry point script
    cat > tools.sh << 'EOF'
#!/bin/bash
# Convenient entry point for development tools
# Usage: ./tools.sh [category] [tool] [args...]

set -euo pipefail
cd "$(dirname "$0")" || exit 1

show_help() {
    echo "🔧 Development Tools Entry Point"
    echo "==============================="
    echo ""
    echo "Usage: ./tools.sh [category] [tool] [args...]"
    echo ""
    echo "📁 Available Categories:"
    echo "  diagnostics  - System health & diagnostic tools"
    echo "  hunters      - Hunter analysis system"
    echo "  nexus        - NEXUS consciousness tools"
    echo "  automation   - System automation & fixes"
    echo "  analysis     - Repository analysis tools"
    echo "  scripts      - General utility scripts"
    echo ""
    echo "🎯 Examples:"
    echo "  ./tools.sh diagnostics quick-system-check"
    echo "  ./tools.sh hunters hunt accessibility"
    echo "  ./tools.sh nexus nexus-consciousness-safe"
    echo ""
    echo "💡 For tool-specific help: ./tools.sh [category] [tool] --help"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

category="$1"
shift || true

if [[ ! -d "tools/$category" ]]; then
    echo "❌ Unknown category: $category"
    echo ""
    show_help
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "📂 Available tools in $category:"
    ls -1 "tools/$category/" | grep -E '\.(sh|mjs)$' | sed 's/^/  /'
    exit 0
fi

tool="$1"
shift || true

tool_path="tools/$category/$tool"
if [[ ! -f "$tool_path" ]]; then
    # Try with .sh extension
    tool_path="tools/$category/$tool.sh"
    if [[ ! -f "$tool_path" ]]; then
        echo "❌ Tool not found: $tool in $category"
        echo ""
        echo "Available tools:"
        ls -1 "tools/$category/" | grep -E '\.(sh|mjs)$' | sed 's/^/  /'
        exit 1
    fi
fi

echo "🚀 Running: $tool_path $*"
exec "$tool_path" "$@"
EOF

    chmod +x tools.sh
    echo "  ✅ Created tools.sh entry point script"
}

# Validate Phase 3 results
validate_phase3_results() {
    echo "🧪 Validating Phase 3 Results"
    echo "============================="
    
    echo "📊 Tools organization summary:"
    for subdir in diagnostics hunters nexus automation analysis scripts; do
        local count=$(find "tools/$subdir" -type f \( -name "*.sh" -o -name "*.mjs" \) 2>/dev/null | wc -l)
        echo "  📁 tools/$subdir/: $count files"
    done
    
    echo ""
    echo "📈 Before/After Comparison:"
    local remaining_root=$(find . -maxdepth 1 -name "*.sh" | grep -v tools.sh | wc -l)
    local total_organized=$(find tools -type f \( -name "*.sh" -o -name "*.mjs" \) 2>/dev/null | wc -l)
    echo "  🔧 Root script files remaining: $remaining_root"
    echo "  🔨 Files organized in tools/: $total_organized"
    
    echo ""
    echo "🔗 Testing tool accessibility..."
    if [[ -f "tools/README.md" ]]; then
        echo "  ✅ Tools documentation created"
    fi
    
    if [[ -f "tools.sh" ]]; then
        echo "  ✅ Entry point script created"
    fi
    
    if [[ -x "tools.sh" ]]; then
        echo "  ✅ Entry point script executable"
    fi
    
    # Test a few key tools are accessible
    echo ""
    echo "🧪 Testing key tool access..."
    if [[ -f "tools/diagnostics/quick-system-check.sh" ]]; then
        echo "  ✅ Diagnostic tools accessible"
    fi
    
    if [[ -f "tools/hunters/hunt.sh" ]]; then
        echo "  ✅ Hunter tools accessible"
    fi
    
    if [[ -f "tools/nexus/nexus-consciousness-safe.sh" ]]; then
        echo "  ✅ NEXUS tools accessible"
    fi
}

# Main execution
main() {
    echo "🔧 Starting COSMIC + CRYSTAL Phase 3: Tools Consolidation..."
    echo ""
    
    create_phase3_checkpoint
    echo ""
    
    cosmic_tools_analysis
    echo ""
    
    crystal_tools_strategy
    echo ""
    
    generate_tools_plan
    echo ""
    
    create_tools_structure
    echo ""
    
    move_diagnostic_tools
    echo ""
    
    move_hunter_tools
    echo ""
    
    move_nexus_tools
    echo ""
    
    move_automation_tools
    echo ""
    
    organize_existing_tools
    echo ""
    
    create_tools_documentation
    echo ""
    
    validate_phase3_results
    echo ""
    
    echo "🎉 COSMIC + CRYSTAL Phase 3 Complete!"
    echo "====================================="
    echo ""
    echo "✅ Tools systematically organized into logical categories"
    echo "🔧 Entry point created: ./tools.sh [category] [tool]"
    echo "📚 Documentation hub created at tools/README.md"
    echo "🎯 Developer tool discovery optimized"
    echo ""
    echo "🚀 Repository Organization Complete!"
    echo "=================================="
    echo "✨ Phase 1: Configuration → /config/"
    echo "✨ Phase 2: Documentation → /docs/"  
    echo "✨ Phase 3: Tools → /tools/"
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Test tool accessibility via ./tools.sh"
    echo "  2. Update any remaining cross-references"
    echo "  3. Celebrate consciousness-enhanced organization success!"
    echo ""
    echo "💡 COSMIC: 'Tools constellation perfectly organized!'"
    echo "💎 CRYSTAL: 'Complete repository architecture achieved!'"
}

# Allow script to be sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi