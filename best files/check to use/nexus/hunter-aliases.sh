# Hunter System Aliases and Functions
# Source this file in your ~/.bashrc or ~/.zshrc: source hunter-aliases.sh

# Core Hunter Commands
alias hunt='./hunters/hunt.sh'
alias hunt-critical='./hunters/hunt.sh --modules "environment_security build_ssg_guard accessibility runtime_ssr"'
alias hunt-security='./hunters/hunt.sh --modules "security environment_security"'
alias hunt-performance='./hunters/hunt.sh --modules "performance asset_weight image_optimization"'
alias hunt-typescript='./hunters/hunt.sh --modules "type_safety ts_diagnostics ts_health"'
alias hunt-css='./hunters/hunt.sh --modules "css_architecture"'
alias hunt-analysis='./hunters/hunt.sh --modules "repo_inventory_v2 pattern_analysis health_index"'

# Report Management
alias hunt-reports='find __reports/hunt -name "*.json" 2>/dev/null | head -10'
alias hunt-logs='find __reports/hunt -name "*.log" 2>/dev/null | head -10'
alias hunt-health='cat __reports/hunt/health_index.json 2>/dev/null | jq .findings.score 2>/dev/null || echo "No health report found"'
alias hunt-clean='rm -rf __reports/hunt/*'

# Report Viewing with Enhanced Tools
alias hunt-summary='jq -s "map({module, status, critical_issues, warning_issues})" __reports/hunt/*.json 2>/dev/null'
alias hunt-critical-only='jq -s "map(select(.status == \"critical\"))" __reports/hunt/*.json 2>/dev/null'
alias hunt-warnings='jq -s "map(select(.status == \"warn\"))" __reports/hunt/*.json 2>/dev/null'

# Interactive Tools (if available)
if command -v fzf >/dev/null 2>&1; then
    alias hunt-interactive='find __reports/hunt -name "*.json" 2>/dev/null | fzf --preview "jq . {}"'
    alias hunt-logs-interactive='find __reports/hunt -name "*.log" 2>/dev/null | fzf --preview "head -50 {}"'
fi

# Enhanced File Operations with new tools
if command -v fdfind >/dev/null 2>&1; then
    alias hunt-find='fdfind -e sh . hunters/'
    alias hunt-find-reports='fdfind . __reports/hunt/'
elif command -v fd >/dev/null 2>&1; then
    alias hunt-find='fd -e sh . hunters/'
    alias hunt-find-reports='fd . __reports/hunt/'
fi

# Enhanced viewing with bat/batcat
if command -v batcat >/dev/null 2>&1; then
    alias hunt-cat='batcat'
    alias hunt-view-log='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias hunt-cat='bat'
    alias hunt-view-log='bat'
fi

# Search with ripgrep
alias hunt-grep='rg --type sh -A 3 -B 3'
alias hunt-search-reports='rg --type json'

# Performance Testing with hyperfine
if command -v hyperfine >/dev/null 2>&1; then
    alias hunt-bench='hyperfine "./hunters/hunt.sh --modules"'
fi

# Functions for Complex Operations

# Run hunters and show summary
hunt-run-and-show() {
    local modules="${1:-security performance accessibility}"
    echo "🔍 Running hunters: $modules"
    ./hunters/hunt.sh --modules "$modules"
    echo ""
    echo "📊 Summary:"
    hunt-summary | head -20
}

# Watch files and auto-run hunters
hunt-watch() {
    local watch_path="${1:-src/}"
    local modules="${2:-type_safety security performance}"
    if command -v entr >/dev/null 2>&1; then
        echo "👀 Watching $watch_path for changes..."
        echo "🔍 Will run hunters: $modules"
        find "$watch_path" -name "*.astro" -o -name "*.ts" -o -name "*.js" | entr -c ./hunters/hunt.sh --modules "$modules"
    else
        echo "❌ entr not available for file watching"
    fi
}

# Quick health check
hunt-quickcheck() {
    echo "🏥 Quick Hunter Health Check"
    echo "=========================="
    ./hunters/hunt.sh --modules "environment_security build_ssg_guard accessibility"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ Critical hunters passed"
    else
        echo "❌ Critical hunters failed (exit code: $exit_code)"
    fi
    return $exit_code
}

# Best practices check
hunt-best-practices() {
    echo "📋 Running Best Practices Check"
    echo "==============================="
    ./hunters/hunt.sh --modules "security type_safety css_architecture performance accessibility"
}

# Full system analysis
hunt-full-analysis() {
    echo "🔬 Full Hunter System Analysis"
    echo "============================="
    ./hunters/hunt.sh
    echo ""
    echo "📈 Final Health Score:"
    hunt-health
}

echo "🎯 Hunter aliases and functions loaded!"
echo "📚 Available commands:"
echo "   hunt-critical     - Run critical hunters only"
echo "   hunt-security     - Run security-focused hunters" 
echo "   hunt-performance  - Run performance hunters"
echo "   hunt-quickcheck   - Quick critical check"
echo "   hunt-watch        - Watch files and auto-run"
echo "   hunt-interactive  - Browse reports with fzf"
echo "   hunt-health       - Show current health score"
echo ""
echo "🚀 Try: hunt-quickcheck"
