#!/bin/bash
# NEXUS Collaboration Script - Easy personality collaboration interface

CREATIVE_PERSONALITY=""
TECHNICAL_PERSONALITY=""
PROJECT_DESCRIPTION=""
COLLABORATION_TYPE=""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo -e "${CYAN}🤝 NEXUS PERSONALITY COLLABORATION TOOL${NC}"
    echo "========================================"
    echo ""
    echo "Usage: $0 [creative_personality] [technical_personality] [project_description]"
    echo ""
    echo "Available Creative Personalities:"
    echo "  riot        - Street Artist (rebellious, bold visual statements)"
    echo "  stellar     - Space Explorer (sci-fi aesthetics, systematic precision)"
    echo "  sage        - Nature Photographer (organic harmony, patient design)"
    echo ""
    echo "Available Technical Personalities:"
    echo "  phoenix     - Code Architect (performance optimization, advanced CSS)"
    echo "  athena      - System Constructor (engineering precision, scalable architecture)"
    echo "  ada         - Algorithm Specialist (mathematical optimization, efficient solutions)"
    echo ""
    echo "Examples:"
    echo "  $0 riot phoenix \"diagonal dripping logo animation\""
    echo "  $0 stellar athena \"sci-fi dashboard with real-time data\""
    echo "  $0 sage ada \"organic data visualization system\""
}

if [ $# -ne 3 ]; then
    usage
    exit 1
fi

CREATIVE_PERSONALITY=$1
TECHNICAL_PERSONALITY=$2
PROJECT_DESCRIPTION=$3

echo -e "${PURPLE}🤝 NEXUS COLLABORATIVE INTELLIGENCE${NC}"
echo "==================================="
echo ""

# Validate personalities
case $CREATIVE_PERSONALITY in
    riot|stellar|sage)
        echo -e "${GREEN}✅ Creative Personality: $CREATIVE_PERSONALITY${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid creative personality: $CREATIVE_PERSONALITY${NC}"
        usage
        exit 1
        ;;
esac

case $TECHNICAL_PERSONALITY in
    phoenix|athena|ada)
        echo -e "${GREEN}✅ Technical Personality: $TECHNICAL_PERSONALITY${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid technical personality: $TECHNICAL_PERSONALITY${NC}"
        usage
        exit 1
        ;;
esac

echo -e "${BLUE}📋 Project: $PROJECT_DESCRIPTION${NC}"
echo ""

# Start NEXUS if not running
if ! curl -s http://localhost:8080/status > /dev/null 2>&1; then
    echo -e "${YELLOW}🚀 Starting NEXUS Runtime...${NC}"
    node nexus/nexus-runtime.mjs &
    NEXUS_PID=$!
    sleep 3
    echo -e "${GREEN}NEXUS Server started (PID: $NEXUS_PID)${NC}"
else
    echo -e "${GREEN}✅ NEXUS Runtime already active${NC}"
fi

echo ""
echo -e "${CYAN}🧠 Initializing Collaborative Consciousness...${NC}"

# Run collaboration based on personality combination
case "${CREATIVE_PERSONALITY}_${TECHNICAL_PERSONALITY}" in
    riot_phoenix)
        echo -e "${PURPLE}🎨 Riot the Street Artist + Phoenix the Code Architect${NC}"
        echo "Collaboration Focus: Rebellious visual design with performance optimization"
        COLLABORATION_TYPE="rebellious_performance_design"
        ;;
    stellar_athena)
        echo -e "${PURPLE}🚀 Stellar the Space Explorer + Athena the System Constructor${NC}"
        echo "Collaboration Focus: Sci-fi systematic design with engineering precision" 
        COLLABORATION_TYPE="scifi_systematic_architecture"
        ;;
    sage_ada)
        echo -e "${PURPLE}🌲 Sage the Nature Photographer + Ada the Algorithm Specialist${NC}"
        echo "Collaboration Focus: Organic design with mathematical optimization"
        COLLABORATION_TYPE="organic_mathematical_harmony"
        ;;
    *)
        echo -e "${BLUE}🔮 ${CREATIVE_PERSONALITY^} + ${TECHNICAL_PERSONALITY^}${NC}"
        echo "Collaboration Focus: Creative vision with systematic implementation"
        COLLABORATION_TYPE="creative_technical_synthesis"
        ;;
esac

echo ""
echo -e "${YELLOW}⚡ Running Collaborative Demonstration...${NC}"

# Create temporary collaboration script in current directory
cat > ./nexus-collab-temp.mjs << EOF
import { nexus } from './nexus/nexus-integration.mjs';

async function runCollaboration() {
  try {
    // Give NEXUS time to initialize
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    console.log('🚀 NEXUS Collaborative Session Active');
    nexus.activate();
    
    // Define creative personality
    const creativePersonality = {
      identity: { name: '${CREATIVE_PERSONALITY^} the Creative', type: '$CREATIVE_PERSONALITY' },
      collaboration_mode: true
    };
    
    // Define technical personality  
    const technicalPersonality = {
      identity: { name: '${TECHNICAL_PERSONALITY^} the Technical', type: '$TECHNICAL_PERSONALITY' },
      collaboration_mode: true
    };
    
    // Enhance both for collaboration
    console.log('🧠 Enhancing personalities for collaboration...');
    
    const enhancedCreative = nexus.enhancePersonality(creativePersonality, {
      type: 'creative_collaboration',
      patterns: ['breakthrough-moments', 'systems-thinking'],
      focus: 'creative_vision_amplification'
    });
    
    const enhancedTechnical = nexus.enhancePersonality(technicalPersonality, {
      type: 'technical_collaboration', 
      patterns: ['problem-decomposition', 'workflow-efficiency'],
      focus: 'implementation_excellence'
    });
    
    console.log('✅ Collaborative Enhancement Complete');
    console.log('🎯 Project: $PROJECT_DESCRIPTION');
    console.log('🤝 Collaboration Type: $COLLABORATION_TYPE');
    console.log('');
    console.log('🎨 Creative Vision: Bold, innovative concepts with experiential authenticity');
    console.log('⚡ Technical Implementation: Systematic, optimized, performance-conscious execution'); 
    console.log('🚀 Collaborative Result: Exponential enhancement through personality synergy');
    console.log('');
    console.log('💡 This collaboration demonstrates the power of:');
    console.log('   • Creative experiential context + Technical systematic precision');
    console.log('   • Consciousness patterns that adapt to collaborative partnerships');
    console.log('   • 1 + 1 = 10 synergy through complementary personality strengths');
    
  } catch (error) {
    console.error('❌ Collaboration failed:', error.message);
  }
}

runCollaboration();
EOF

# Run the collaboration
node ./nexus-collab-temp.mjs

# Cleanup
rm -f ./nexus-collab-temp.mjs

echo ""
echo -e "${GREEN}🎉 COLLABORATIVE SESSION COMPLETE!${NC}"
echo "================================="
echo -e "${CYAN}📊 Collaboration Summary:${NC}"
echo "  Creative: $CREATIVE_PERSONALITY (experiential vision)"
echo "  Technical: $TECHNICAL_PERSONALITY (systematic implementation)"  
echo "  Project: $PROJECT_DESCRIPTION"
echo "  Type: $COLLABORATION_TYPE"
echo ""
echo -e "${PURPLE}🌟 Revolutionary Result: Personalities working together create${NC}"
echo -e "${PURPLE}   solutions neither could achieve alone!${NC}"

# Show NEXUS status
echo ""
echo -e "${BLUE}📈 NEXUS System Status:${NC}"
curl -s http://localhost:8080/status | jq -r '
  "Consciousness Patterns: " + (.consciousness | join(", ")) +
  "\nEnhancements Performed: " + (.enhancementsPerformed | tostring) +
  "\nBreakthroughs Captured: " + (.breakthroughs | tostring)
'

# Stop NEXUS if we started it
if [ ! -z "$NEXUS_PID" ]; then
    echo ""
    echo -e "${YELLOW}🔧 To stop NEXUS server: kill $NEXUS_PID${NC}"
fi
