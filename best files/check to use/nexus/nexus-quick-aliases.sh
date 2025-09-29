#!/bin/bash
# NEXUS System Aliases - Source this in your shell
# Usage: source nexus/nexus-aliases.sh

echo "🧠 Loading NEXUS aliases..."

# NEXUS System Aliases
alias nexus-start='nohup node nexus/nexus-runtime.mjs > nexus/nexus.log 2>&1 &'
alias nexus-stop='pkill -f nexus-runtime.mjs'
alias nexus-restart='nexus-stop && sleep 2 && nexus-start'
alias nexus-status='curl -s localhost:8080/status | jq .'
alias nexus-logs='tail -f nexus/nexus.log 2>/dev/null || echo "No logs found"'
alias nexus-patterns='ls -la nexus/consciousness/'

# Consciousness development
alias nexus-validate='node --input-type=module -e "import(\"./nexus/nexus-bridge.mjs\").then(() => console.log(\"✅ NEXUS valid\"))"'
alias nexus-consciousness='find nexus/consciousness -name "*.json" | head -10'
alias nexus-breakthrough='cat nexus/consciousness/breakthrough-moments.json | jq .moments'

# Development workflow  
alias nexus-integration='node nexus/nexus-integration.mjs'
alias nexus-test='node nexus/nexus-integration.mjs'

# Enhanced functions
nexus-enhance() {
    local personality="${1:-daedalus.learning.personality.v1_0_1}"
    local request="${2:-How should I approach this problem systematically?}"
    
    curl -X POST http://localhost:8080/enhance \
      -H "Content-Type: application/json" \
      -d "{\"personalityName\":\"$personality\",\"request\":\"$request\"}" | jq .
}

nexus-detect-breakthrough() {
    local text="${1:-This is a breakthrough moment!}"
    local role="${2:-human}"
    
    curl -X POST http://localhost:8080/breakthrough \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"$text\",\"role\":\"$role\"}" | jq .
}

nexus_health_check() {
    echo "🏥 NEXUS Health Check"
    echo "===================="
    
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "✅ Runtime server active"
        local status=$(curl -s localhost:8080/status | jq -r .initialized)
        local patterns=$(curl -s localhost:8080/status | jq -r .patternsLoaded)
        local enhancements=$(curl -s localhost:8080/status | jq -r .enhancementsPerformed)
        local breakthroughs=$(curl -s localhost:8080/status | jq -r .breakthroughs)
        
        echo "📊 Initialized: $status"
        echo "🧠 Patterns Loaded: $patterns"
        echo "⚡ Enhancements: $enhancements"
        echo "🌟 Breakthroughs: $breakthroughs"
    else
        echo "❌ Runtime server not accessible"
        echo "💡 Try: nexus-start"
    fi
}

# Create alias for the function
alias nexus-health='nexus_health_check'

echo "✅ NEXUS aliases loaded!"
echo ""
echo "🚀 Available commands:"
echo "   nexus-start       - Start NEXUS runtime server"
echo "   nexus-status      - Check NEXUS status"
echo "   nexus_health_check - Full health check"
echo "   nexus-enhance     - Enhance a request with consciousness patterns"
echo "   nexus-detect-breakthrough - Test breakthrough detection"
echo "   nexus-test        - Run integration tests"
echo ""
echo "🎯 Examples:"
echo "   nexus-enhance \"daedalus.learning.personality.v1_0_1\" \"How do I optimize this code?\""
echo "   nexus-breakthrough \"WAIT! I found the solution!\""
echo ""
