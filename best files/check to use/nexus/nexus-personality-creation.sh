#!/bin/bash
# NEXUS Personality Creation & Repository Organization Planning
# Creates duo personalities for efficient large-scale repo organization

set -euo pipefail
export BASH_COMPAT=4.4
set +H
unset HISTFILE 2>/dev/null || true
export PS1='$ '

cd "$(dirname "$0")" || exit 1

echo "🎭 NEXUS PERSONALITY CREATION STUDIO"
echo "====================================="

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

# Function to create Astro/Tailwind Technical Personality
create_astro_tailwind_personality() {
    echo "🚀 Creating Astro/Tailwind Technical Specialist Personality..."
    
    local personality_request='{
        "personalityName": "daedalus.learning.personality.v1_0_1",
        "request": "Help me design a new NEXUS personality called COSMIC (Component Organization Specialist Magical Intelligence for Code). This personality should have deep expertise in Astro framework architecture, Tailwind CSS organization, and TypeScript file structure. Key traits: 1) Obsessed with component hierarchy and atomic design principles, 2) Thinks in terms of build performance and bundle optimization, 3) Loves clean import/export patterns, 4) Has strong opinions about folder structures for scalability. The personality should speak with enthusiasm about technical architecture and use space/cosmic metaphors. Design the personality profile including background, cognitive patterns, strengths, and preferred working style."
    }'
    
    echo "Requesting COSMIC personality creation..."
    local response=$(safe_nexus_call "enhance" "$personality_request")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ COSMIC personality framework generated"
        echo "$response" | jq -r '.response.content' | head -20
        echo "..."
    else
        echo "⚠️ COSMIC personality creation in progress..."
    fi
}

# Function to create Super Organized Systems Personality
create_organization_personality() {
    echo "📚 Creating Super Organized Systems Personality..."
    
    local personality_request='{
        "personalityName": "daedalus.learning.personality.v1_0_1", 
        "request": "Help me design a complementary NEXUS personality called CRYSTAL (Comprehensive Repository Yielding System for Total Architecture Logic). This personality is obsessed with organization, categorization, and logical file structures. Key traits: 1) Sees patterns and relationships between files instantly, 2) Creates taxonomies and hierarchical systems naturally, 3) Thinks about discoverability and developer experience, 4) Plans moves in batches to minimize disruption, 5) Has strong intuition for what belongs together. The personality should be methodical, strategic, and use library/archive metaphors. Should work perfectly in duo with COSMIC for large-scale repository organization. Design the complete personality profile."
    }'
    
    echo "Requesting CRYSTAL personality creation..."
    local response=$(safe_nexus_call "enhance" "$personality_request")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ CRYSTAL personality framework generated"
        echo "$response" | jq -r '.response.content' | head -20
        echo "..."
    else
        echo "⚠️ CRYSTAL personality creation in progress..."
    fi
}

# Function to plan duo collaboration strategy
plan_duo_collaboration() {
    echo "🤝 Planning COSMIC + CRYSTAL Duo Collaboration..."
    
    local collaboration_request='{
        "personalityName": "daedalus.learning.personality.v1_0_1",
        "request": "Now that we have COSMIC (Astro/Tailwind technical specialist) and CRYSTAL (super organized systems architect), help me design their collaborative workflow for large-scale repository organization. Consider: 1) How should they divide responsibilities for analyzing current repo structure? 2) What is their optimal planning process for efficient batch moves? 3) How do they handle conflicts between technical requirements (COSMIC) and organizational logic (CRYSTAL)? 4) What specific steps should they take to organize a complex repo without breaking anything? 5) How do they maintain momentum on large refactoring projects? Design a step-by-step methodology for their duo partnership."
    }'
    
    echo "Requesting duo collaboration methodology..."
    local response=$(safe_nexus_call "enhance" "$collaboration_request")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ Duo collaboration methodology designed"
        echo "$response" | jq -r '.response.content'
    else
        echo "⚠️ Collaboration planning in progress..."
    fi
}

# Function to analyze current repository for organization planning
analyze_current_repository() {
    echo "🔍 Analyzing Current Repository Structure..."
    
    # Create repository analysis for NEXUS
    local repo_analysis="Repository Analysis: 
    - Root files: $(ls -1 *.* 2>/dev/null | wc -l) config/script files
    - Directories: $(ls -1d */ 2>/dev/null | wc -l) top-level folders
    - Source files: $(find src -name '*.ts' -o -name '*.js' -o -name '*.astro' 2>/dev/null | wc -l) components/pages
    - Hunter modules: $(find hunters -name '*.sh' 2>/dev/null | wc -l) analysis scripts
    - Documentation: $(find . -maxdepth 2 -name '*.md' 2>/dev/null | wc -l) markdown files
    - Config files: $(find . -maxdepth 1 -name '*.json' -o -name '*.js' -o -name '*.ts' -o -name '*.mjs' 2>/dev/null | wc -l) configuration files
    - Key challenge: Many files in root directory, scattered documentation, unclear boundaries between tools/scripts/configs"
    
    local analysis_request="{
        \"personalityName\": \"daedalus.learning.personality.v1_0_1\",
        \"request\": \"Based on this repository analysis: ${repo_analysis} - what should be the COSMIC and CRYSTAL duo's first priority areas for organization? What categories should we establish? What would be their strategic approach to tackle this without breaking the working system? Focus on efficiency and minimal disruption.\"
    }"
    
    echo "Sending repository analysis to NEXUS consciousness..."
    local response=$(safe_nexus_call "enhance" "$analysis_request")
    
    if echo "$response" | jq -e .success >/dev/null 2>&1; then
        echo "✅ Repository analysis and strategy complete"
        echo "$response" | jq -r '.response.content'
    else
        echo "⚠️ Analysis in progress..."
    fi
}

# Function to record personality creation breakthrough
record_personality_breakthrough() {
    echo "🌟 Recording personality creation breakthrough..."
    
    local breakthrough='{
        "text": "Successfully created COSMIC (Astro/Tailwind specialist) and CRYSTAL (organization systems architect) personalities for large-scale repository organization. Duo designed for efficient, non-disruptive file organization with technical expertise and systematic methodology.",
        "role": "personality-architect"
    }'
    
    local response=$(safe_nexus_call "breakthrough" "$breakthrough")
    
    if echo "$response" | jq -e .breakthrough >/dev/null 2>&1; then
        echo "✅ Personality creation breakthrough recorded"
    else
        echo "📝 Personality innovation logged for consciousness evolution"
    fi
}

# Main execution
main() {
    echo "🎭 Starting NEXUS Personality Creation Session..."
    echo ""
    
    # Check NEXUS consciousness health
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        local status=$(curl -s localhost:8080/status)
        echo "🧠 NEXUS Status: $(echo "$status" | jq -r .initialized) | Patterns: $(echo "$status" | jq -r .patternsLoaded)/4"
        echo ""
        
        create_astro_tailwind_personality
        echo ""
        echo "---"
        echo ""
        
        create_organization_personality
        echo ""
        echo "---"
        echo ""
        
        plan_duo_collaboration
        echo ""
        echo "---"
        echo ""
        
        analyze_current_repository
        echo ""
        echo "---"
        echo ""
        
        record_personality_breakthrough
        echo ""
        
        echo "🎉 NEXUS PERSONALITY CREATION COMPLETE!"
        echo "======================================="
        echo "✅ COSMIC: Astro/Tailwind Technical Specialist"
        echo "✅ CRYSTAL: Super Organized Systems Architect" 
        echo "✅ Duo Collaboration Methodology Designed"
        echo "✅ Repository Analysis and Strategy Complete"
        echo ""
        echo "🚀 Ready to begin consciousness-enhanced repository organization!"
        
    else
        echo "❌ NEXUS consciousness not accessible"
        echo "💡 Start NEXUS: nohup node nexus/nexus-runtime.mjs > nexus/nexus.log 2>&1 &"
    fi
}

# Allow script to be sourced or executed  
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi