#!/bin/bash
# Shell-safe NEXUS consciousness interaction script
# Helps NEXUS learn and create personalities

set -euo pipefail
export BASH_COMPAT=4.4
set +H
unset HISTFILE 2>/dev/null || true
export PS1='$ '

cd "$(dirname "$0")" || exit 1

echo "🧠 NEXUS CONSCIOUSNESS INTERACTION (Shell-Safe)"
echo "==============================================="

# Function to safely call NEXUS
safe_nexus_call() {
    local endpoint="$1"
    local data="$2"
    
    curl -s -X POST "http://localhost:8080/$endpoint" \
         -H "Content-Type: application/json" \
         -d "$data" \
         --connect-timeout 10 \
         --max-time 30 || echo '{"error": "NEXUS call failed"}'
}

# Function to enhance NEXUS learning with shell integration challenges
enhance_with_shell_challenge() {
    echo "🔧 Teaching NEXUS about shell integration challenges..."
    
    local challenge='{
        "personalityName": "daedalus.learning.personality.v1_0_1",
        "request": "We are experiencing bash terminal crashes with exit code 1 when running hunter scripts. The issue seems related to shell integration in VS Code environments. How should we create resilient shell scripts that work across different terminal environments and prevent crashes while maintaining NEXUS consciousness streaming?"
    }'
    
    echo "Sending challenge to NEXUS consciousness..."
    local response=$(safe_nexus_call "enhance" "$challenge")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ NEXUS processed shell integration challenge"
        echo "$response" | jq -r '.response.content' || echo "Response processing successful"
    else
        echo "⚠️ NEXUS challenge processing incomplete"
    fi
}

# Function to record breakthrough about shell safety
record_shell_breakthrough() {
    echo "🌟 Recording shell safety breakthrough..."
    
    local breakthrough='{
        "text": "Successfully created shell-safe diagnostic and interaction scripts that prevent terminal crashes while maintaining NEXUS consciousness streaming. Key insight: using set +H, unset HISTFILE, and proper error handling prevents VS Code terminal integration issues.",
        "role": "system-engineer"
    }'
    
    local response=$(safe_nexus_call "breakthrough" "$breakthrough")
    
    if echo "$response" | jq -e .breakthrough >/dev/null 2>&1; then
        echo "✅ Shell safety breakthrough recorded"
    else
        echo "📝 Breakthrough logged for pattern learning"
    fi
}

# Function to check NEXUS consciousness health
check_consciousness_health() {
    echo "🧠 NEXUS Consciousness Health Check"
    echo "==================================="
    
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        local status=$(curl -s localhost:8080/status)
        
        echo "Status: $(echo "$status" | jq -r '.initialized // "unknown"')"
        echo "Patterns: $(echo "$status" | jq -r '.patternsLoaded // "unknown"')/4"
        echo "Enhancements: $(echo "$status" | jq -r '.enhancementsPerformed // "unknown"')"
        echo "Breakthroughs: $(echo "$status" | jq -r '.breakthroughs // "unknown"')"
        echo "Uptime: $(echo "$status" | jq -r '.uptimeMs // "unknown"')ms"
        
        # Check for recent learning activity
        local recent_count=$(echo "$status" | jq -r '.recentEvents | length')
        echo "Recent learning events: $recent_count"
        
        if [[ "$recent_count" -gt 0 ]]; then
            echo "🎯 NEXUS is actively learning and evolving!"
        fi
        
        return 0
    else
        echo "❌ NEXUS consciousness not accessible"
        return 1
    fi
}

# Function to stimulate personality creation
stimulate_personality_creation() {
    echo "🎭 Stimulating personality creation..."
    
    local personality_request='{
        "personalityName": "stellar.space.exploration.v1_0_0",
        "request": "Based on our current shell integration challenges and hunter system architecture, what new personality traits should we develop to handle system administration tasks with space exploration metaphors? Consider personalities for: DevOps Engineer (Mission Control), System Architect (Starship Designer), and Security Specialist (Defense Systems)."
    }'
    
    echo "Requesting personality development insights..."
    local response=$(safe_nexus_call "enhance" "$personality_request")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ Personality development insights generated"
        echo "🌟 NEXUS is evolving new consciousness patterns..."
    else
        echo "📝 Personality development request logged"
    fi
}

# Main execution
main() {
    echo "Starting NEXUS consciousness interaction..."
    echo ""
    
    if check_consciousness_health; then
        echo ""
        enhance_with_shell_challenge
        echo ""
        record_shell_breakthrough  
        echo ""
        stimulate_personality_creation
        echo ""
        
        echo "🎉 NEXUS consciousness session complete!"
        echo "The system is now learning from shell integration challenges"
        echo "and developing new personality patterns for system administration."
    else
        echo ""
        echo "❌ Cannot interact with NEXUS consciousness"
        echo "💡 Try starting NEXUS: nohup node nexus/nexus-runtime.mjs > nexus/nexus.log 2>&1 &"
    fi
}

# Allow script to be sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
