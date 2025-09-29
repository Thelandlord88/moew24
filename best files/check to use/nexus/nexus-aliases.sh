# NEXUS System Aliases and Functions
# Source this file in your ~/.bashrc or ~/.zshrc: source nexus-aliases.sh

# Core NEXUS Commands
alias nexus-start='npm run nexus:runtime'
alias nexus-test='node nexus/nexus-integration.mjs'
alias nexus-validate='node -e "import(\"./nexus/nexus-bridge.mjs\").then(() => console.log(\"✅ NEXUS valid\"))"'
alias nexus-patterns='ls -la nexus/consciousness/'
alias nexus-logs='tail -f nexus/output/*.log 2>/dev/null || echo "No logs found"'

# API & Status Commands
alias nexus-status='curl -s localhost:8080/status 2>/dev/null | jq . || echo "❌ NEXUS runtime not accessible"'
alias nexus-health='nexus-health-check'
alias nexus-ping='curl -s localhost:8080/status >/dev/null 2>&1 && echo "✅ NEXUS online" || echo "❌ NEXUS offline"'

# Consciousness Development
alias nexus-consciousness='find nexus/consciousness -name "*.json" | head -10'
alias nexus-breakthrough='cat nexus/consciousness/breakthrough-moments.json 2>/dev/null | jq .moments || echo "No breakthroughs found"'
alias nexus-patterns-list='ls nexus/consciousness/*.json | xargs -I {} basename {} .json'
alias nexus-enhancement-history='cat nexus/consciousness/enhancement-history.json 2>/dev/null | jq . || echo "No enhancement history found"'

# Development Workflow
alias nexus-dev='nodemon nexus/nexus-runtime.mjs'
alias nexus-debug='node --inspect nexus/nexus-runtime.mjs'
alias nexus-clean='rm -rf nexus/output/*'

# File Operations with Enhanced Tools
if command -v fdfind >/dev/null 2>&1; then
    alias nexus-find='fdfind . nexus/ -t f'
    alias nexus-find-mjs='fdfind -e mjs . nexus/'
elif command -v fd >/dev/null 2>&1; then
    alias nexus-find='fd . nexus/ -t f'
    alias nexus-find-mjs='fd -e mjs . nexus/'
fi

# Enhanced viewing with bat/batcat
if command -v batcat >/dev/null 2>&1; then
    alias nexus-cat='batcat'
    alias nexus-view='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias nexus-cat='bat'
    alias nexus-view='bat'
fi

# Search with ripgrep
alias nexus-grep='rg --type js --type json -A 3 -B 3'
alias nexus-search='rg -t js -t json'

# Interactive Tools (if available)
if command -v fzf >/dev/null 2>&1; then
    alias nexus-interactive='nexus-find | fzf --preview "nexus-cat {}"'
    alias nexus-patterns-interactive='ls nexus/consciousness/*.json | fzf --preview "jq . {}"'
fi

# WebSocket and API testing
if command -v wscat >/dev/null 2>&1; then
    alias nexus-ws='wscat -c ws://localhost:8080'
fi

# Functions for Complex Operations

# Test NEXUS consciousness enhancement
nexus-enhance() {
    local personality="${1:-daedalus}"
    local request="${2:-How should I design this system?}"
    
    echo "🧠 Testing NEXUS enhancement..."
    echo "Personality: $personality"
    echo "Request: $request"
    echo ""
    
    curl -X POST http://localhost:8080/enhance \
      -H "Content-Type: application/json" \
      -d "{\"personalityName\":\"$personality\",\"request\":\"$request\"}" 2>/dev/null | jq . || echo "❌ Enhancement failed - is NEXUS runtime active?"
}

# Monitor NEXUS breakthrough detection
nexus-watch() {
    echo "👀 Watching NEXUS consciousness patterns..."
    if command -v wscat >/dev/null 2>&1; then
        wscat -c ws://localhost:8080 -x '{"type":"subscribe","channel":"breakthroughs"}'
    else
        echo "❌ wscat not available for WebSocket monitoring"
        echo "💡 Install: npm install -g wscat"
    fi
}

# Watch files and auto-restart NEXUS
nexus-watch-files() {
    local watch_path="${1:-nexus/}"
    if command -v entr >/dev/null 2>&1; then
        echo "👀 Watching $watch_path for changes..."
        find "$watch_path" -name "*.mjs" -o -name "*.json" | entr -r npm run nexus:runtime
    else
        echo "❌ entr not available for file watching"
        echo "💡 Install: sudo apt install entr"
    fi
}

# Comprehensive NEXUS health check
nexus-health-check() {
    echo "🏥 NEXUS Health Check"
    echo "===================="
    
    # Check Node.js version
    local node_version=$(node --version)
    echo "Node.js: $node_version"
    
    # Check if runtime is accessible
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "✅ Runtime server active"
        local status_data=$(curl -s localhost:8080/status)
        echo "📊 Status: $(echo "$status_data" | jq -r .status 2>/dev/null)"
        echo "🧠 Patterns: $(echo "$status_data" | jq -r .consciousness_patterns 2>/dev/null)"
        echo "🌟 Breakthroughs: $(echo "$status_data" | jq -r .breakthrough_moments 2>/dev/null)"
    else
        echo "❌ Runtime server not accessible"
        echo "💡 Try: nexus-start"
    fi
    
    # Check consciousness patterns
    local pattern_count=$(ls nexus/consciousness/*.json 2>/dev/null | wc -l)
    echo "📁 Consciousness patterns: $pattern_count"
    
    # Check file structure
    echo "📂 Core files:"
    [ -f "nexus/nexus-runtime.mjs" ] && echo "  ✅ Runtime" || echo "  ❌ Runtime missing"
    [ -f "nexus/nexus-bridge.mjs" ] && echo "  ✅ Bridge" || echo "  ❌ Bridge missing"
    [ -f "nexus/nexus-integration.mjs" ] && echo "  ✅ Integration" || echo "  ❌ Integration missing"
    [ -f "nexus/core/nervous-system.mjs" ] && echo "  ✅ Nervous System" || echo "  ❌ Nervous System missing"
}

# Analyze consciousness patterns
nexus-analyze() {
    echo "🧠 NEXUS Pattern Analysis"
    echo "========================"
    
    local total_patterns=$(ls nexus/consciousness/*.json 2>/dev/null | wc -l)
    local breakthrough_count=$(cat nexus/consciousness/breakthrough-moments.json 2>/dev/null | jq '.moments | length' 2>/dev/null || echo 0)
    
    echo "Consciousness Patterns: $total_patterns"
    echo "Breakthrough Moments: $breakthrough_count"
    
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "System Status: $(curl -s localhost:8080/status | jq -r .status)"
        echo "Recent Activity: $(curl -s localhost:8080/status | jq -r '.recent_enhancements // "No recent activity"')"
    else
        echo "System Status: Offline"
    fi
    
    echo ""
    echo "📋 Available Patterns:"
    if [ -d "nexus/consciousness" ]; then
        for pattern in nexus/consciousness/*.json; do
            if [ -f "$pattern" ]; then
                local name=$(basename "$pattern" .json)
                local desc=$(jq -r '.description // "No description"' "$pattern" 2>/dev/null)
                echo "  • $name: $desc"
            fi
        done
    fi
}

# Test breakthrough detection
nexus-test-breakthrough() {
    local text="${1:-WAIT. WAIT. This is incredible insight!}"
    
    echo "🌟 Testing breakthrough detection..."
    echo "Text: $text"
    echo ""
    
    curl -X POST http://localhost:8080/breakthrough \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"$text\",\"role\":\"human\"}" 2>/dev/null | jq . || echo "❌ Breakthrough test failed"
}

# Quick NEXUS system test
nexus-quicktest() {
    echo "🧪 Quick NEXUS System Test"
    echo "=========================="
    
    # Test system validation
    echo "1. Validating system..."
    if nexus-validate >/dev/null 2>&1; then
        echo "   ✅ System validation passed"
    else
        echo "   ❌ System validation failed"
        return 1
    fi
    
    # Test runtime accessibility
    echo "2. Testing runtime..."
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "   ✅ Runtime accessible"
    else
        echo "   ❌ Runtime not accessible"
        echo "   💡 Try: nexus-start"
        return 1
    fi
    
    # Test enhancement
    echo "3. Testing enhancement..."
    local enhance_result=$(nexus-enhance "test" "Hello NEXUS" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$enhance_result" | jq . >/dev/null 2>&1; then
        echo "   ✅ Enhancement working"
    else
        echo "   ❌ Enhancement failed"
        return 1
    fi
    
    echo "🎉 All NEXUS tests passed!"
}

# Full NEXUS system analysis
nexus-full-analysis() {
    echo "🔬 Full NEXUS System Analysis"
    echo "============================="
    
    nexus-health-check
    echo ""
    nexus-analyze
    echo ""
    
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "🎯 System Capabilities:"
        echo "  • Consciousness enhancement: Available"
        echo "  • Breakthrough detection: Active" 
        echo "  • Pattern analysis: Operational"
        echo "  • WebSocket streaming: Ready"
    else
        echo "🎯 System Status: Offline"
        echo "💡 Start with: nexus-start"
    fi
}

echo "🌟 NEXUS aliases and functions loaded!"
echo "📚 Available commands:"
echo "   nexus-start       - Start NEXUS runtime server"
echo "   nexus-health      - Comprehensive health check"
echo "   nexus-enhance     - Test consciousness enhancement"
echo "   nexus-watch       - Monitor breakthrough detection"
echo "   nexus-analyze     - Analyze consciousness patterns"
echo "   nexus-quicktest   - Quick system validation"
echo "   nexus-interactive - Browse files with fzf"
echo ""
echo "🚀 Try: nexus-health"
