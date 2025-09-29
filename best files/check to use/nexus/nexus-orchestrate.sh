#!/bin/bash
# NEXUS Intelligent Personality Orchestration Script
# Automatically selects optimal personalities based on task analysis

TASK_DESCRIPTION=""
PROJECT_TYPE="web_development"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo -e "${CYAN}🎪 NEXUS INTELLIGENT PERSONALITY ORCHESTRATION${NC}"
    echo "=============================================="
    echo ""
    echo "Usage: $0 [task_description] [project_type]"
    echo ""
    echo "This script uses NEXUS consciousness to automatically select"
    echo "the optimal personality combination for any given task."
    echo ""
    echo "Project Types (optional, default: web_development):"
    echo "  web_development    - Web apps, sites, interfaces"
    echo "  data_visualization - Charts, dashboards, analytics"
    echo "  system_architecture - Backend systems, APIs, databases"
    echo "  creative_design    - Visual design, branding, aesthetics"
    echo "  performance_optimization - Speed, efficiency, optimization"
    echo ""
    echo "Examples:"
    echo "  $0 \"Create a responsive navigation menu\""
    echo "  $0 \"Build real-time analytics dashboard\" data_visualization"
    echo "  $0 \"Design rebellious logo with animations\" creative_design"
    echo "  $0 \"Optimize database query performance\" system_architecture"
    echo ""
    echo -e "${YELLOW}✨ NEXUS will intelligently determine:${NC}"
    echo "  • Task complexity level"
    echo "  • Required personality types"
    echo "  • Optimal personality combination"
    echo "  • Expected synergy and performance"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

TASK_DESCRIPTION="$1"
PROJECT_TYPE="${2:-web_development}"

echo -e "${PURPLE}🎪 NEXUS INTELLIGENT ORCHESTRATION${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}📋 Task: $TASK_DESCRIPTION${NC}"
echo -e "${BLUE}🔧 Project Type: $PROJECT_TYPE${NC}"
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
echo -e "${CYAN}🧠 Activating Consciousness-Guided Orchestration...${NC}"

# Create orchestration script
cat > ./nexus-orchestrate-temp.mjs << 'EOF'
import { nexus } from './nexus/nexus-integration.mjs';

class QuickOrchestrator {
  constructor() {
    this.personalities = {
      // Creative personalities
      riot: { type: 'creative', context: 'street_art_rebellion', load: 0.7, strengths: ['bold_visual_impact', 'rebellious_aesthetics'] },
      stellar: { type: 'creative', context: 'space_exploration', load: 0.6, strengths: ['sci_fi_precision', 'systematic_beauty'] },
      sage: { type: 'creative', context: 'nature_harmony', load: 0.5, strengths: ['organic_design', 'patient_refinement'] },
      
      // Technical personalities  
      phoenix: { type: 'technical', context: 'performance_optimization', load: 0.8, strengths: ['css_mastery', 'animation_systems'] },
      athena: { type: 'technical', context: 'system_architecture', load: 0.7, strengths: ['engineering_precision', 'scalable_design'] },
      ada: { type: 'technical', context: 'algorithm_optimization', load: 0.9, strengths: ['mathematical_efficiency', 'data_optimization'] }
    };
    
    this.synergyMatrix = {
      riot: { phoenix: 0.9, athena: 0.6, ada: 0.4 },
      stellar: { phoenix: 0.8, athena: 0.95, ada: 0.9 },
      sage: { phoenix: 0.7, athena: 0.6, ada: 0.9 }
    };
  }

  analyzeTask(taskDescription, projectType) {
    const keywords = {
      creative: ['design', 'visual', 'aesthetic', 'beautiful', 'artistic', 'logo', 'branding', 'ui', 'interface'],
      technical: ['performance', 'optimization', 'system', 'database', 'api', 'backend', 'algorithm', 'code'],
      complexity: ['complex', 'advanced', 'comprehensive', 'multi', 'real-time', 'interactive', 'dynamic'],
      rebellion: ['rebellious', 'bold', 'edgy', 'alternative', 'street', 'graffiti', 'punk'],
      systematic: ['systematic', 'precise', 'engineering', 'scalable', 'architecture', 'framework'],
      organic: ['natural', 'organic', 'smooth', 'flowing', 'harmonious', 'gentle', 'nature'],
      scifi: ['sci-fi', 'futuristic', 'space', 'cyber', 'digital', 'tech', 'neon', 'holographic'],
      performance: ['fast', 'optimiz', 'efficient', 'speed', 'performance', 'lightweight', 'smooth'],
      mathematical: ['data', 'analytics', 'statistics', 'algorithm', 'calculation', 'mathematical', 'chart']
    };

    const text = taskDescription.toLowerCase();
    
    let scores = {
      creative: 0,
      technical: 0, 
      complexity: 0,
      rebellion: 0,
      systematic: 0,
      organic: 0,
      scifi: 0,
      performance: 0,
      mathematical: 0
    };

    // Calculate keyword scores
    Object.keys(keywords).forEach(category => {
      keywords[category].forEach(keyword => {
        if (text.includes(keyword)) {
          scores[category] += 0.2;
        }
      });
    });

    // Project type influence
    const projectInfluence = {
      web_development: { creative: 0.3, technical: 0.3 },
      data_visualization: { mathematical: 0.4, systematic: 0.3, technical: 0.2 },
      system_architecture: { systematic: 0.5, technical: 0.4 },
      creative_design: { creative: 0.5, rebellion: 0.2, organic: 0.2 },
      performance_optimization: { performance: 0.5, technical: 0.3, mathematical: 0.2 }
    };

    if (projectInfluence[projectType]) {
      Object.keys(projectInfluence[projectType]).forEach(category => {
        scores[category] += projectInfluence[projectType][category];
      });
    }

    return scores;
  }

  selectPersonalities(scores) {
    let selection = [];
    
    // Determine creative personality
    let creativeChoice = 'stellar'; // Default
    if (scores.rebellion > 0.4) creativeChoice = 'riot';
    else if (scores.organic > 0.3) creativeChoice = 'sage';
    else if (scores.scifi > 0.3) creativeChoice = 'stellar';

    // Determine technical personality  
    let technicalChoice = 'phoenix'; // Default
    if (scores.systematic > 0.5) technicalChoice = 'athena';
    else if (scores.mathematical > 0.4) technicalChoice = 'ada';
    else if (scores.performance > 0.3) technicalChoice = 'phoenix';

    // Determine if we need both creative and technical
    const needsCreative = scores.creative > 0.3;
    const needsTechnical = scores.technical > 0.3;
    const complexity = scores.complexity;

    if (needsCreative && needsTechnical) {
      selection = [creativeChoice, technicalChoice];
    } else if (needsCreative) {
      selection = [creativeChoice];
    } else if (needsTechnical) {
      selection = [technicalChoice];
    } else if (complexity > 0.4) {
      // Complex but unclear requirements - use high synergy pair
      selection = ['stellar', 'athena'];
    } else {
      // Simple task - use single optimal personality
      selection = scores.creative >= scores.technical ? [creativeChoice] : [technicalChoice];
    }

    return selection;
  }

  calculateMetrics(personalities) {
    let totalLoad = 0;
    let synergy = 0.8; // Single personality baseline

    personalities.forEach(p => {
      totalLoad += this.personalities[p].load;
    });

    if (personalities.length === 2) {
      const [p1, p2] = personalities;
      if (this.synergyMatrix[p1] && this.synergyMatrix[p1][p2]) {
        synergy = this.synergyMatrix[p1][p2];
      }
    } else if (personalities.length > 2) {
      // Average synergy for multi-personality
      synergy = 0.7; // Conservative estimate
    }

    return {
      cognitive_load: totalLoad,
      synergy_score: synergy,
      efficiency: synergy / (totalLoad * 0.5)
    };
  }
}

async function orchestrateTask() {
  try {
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    console.log('🚀 NEXUS Orchestration Analysis Active');
    nexus.activate();
    
    const orchestrator = new QuickOrchestrator();
    const taskDescription = process.argv[2] || 'Create a web component';
    const projectType = process.argv[3] || 'web_development';
    
    console.log('🧬 Analyzing task requirements...');
    const scores = orchestrator.analyzeTask(taskDescription, projectType);
    
    console.log('🎯 Selecting optimal personality combination...');
    const personalities = orchestrator.selectPersonalities(scores);
    
    console.log('📊 Calculating performance metrics...');
    const metrics = orchestrator.calculateMetrics(personalities);
    
    console.log('');
    console.log('✅ ORCHESTRATION COMPLETE');
    console.log('========================');
    console.log(`🎭 Selected Personalities: ${personalities.join(' + ')}`);
    console.log(`🧠 Cognitive Load: ${metrics.cognitive_load.toFixed(2)}`);
    console.log(`🤝 Synergy Score: ${metrics.synergy_score.toFixed(2)}`);
    console.log(`⚡ Efficiency Rating: ${metrics.efficiency.toFixed(2)}`);
    console.log('');
    
    // Show personality details
    console.log('🎪 Personality Team Details:');
    personalities.forEach(p => {
      const data = orchestrator.personalities[p];
      console.log(`  ${p.charAt(0).toUpperCase() + p.slice(1)}: ${data.context} (${data.type})`);
      console.log(`    Strengths: ${data.strengths.join(', ')}`);
    });
    
    console.log('');
    console.log('💡 Orchestration Insight:');
    if (personalities.length === 1) {
      console.log(`   Single personality optimal for focused ${personalities[0]} approach`);
    } else if (personalities.length === 2) {
      console.log(`   Dual personality synergy: ${(metrics.synergy_score * 100).toFixed(0)}% collaboration effectiveness`);
    } else {
      console.log(`   Multi personality team for complex multi-domain challenge`);
    }
    
  } catch (error) {
    console.error('❌ Orchestration failed:', error.message);
  }
}

orchestrateTask();
EOF

# Run orchestration with parameters
echo -e "${YELLOW}⚡ Running Orchestration Analysis...${NC}"
node ./nexus-orchestrate-temp.mjs "$TASK_DESCRIPTION" "$PROJECT_TYPE"

# Cleanup
rm -f ./nexus-orchestrate-temp.mjs

echo ""
echo -e "${GREEN}🎉 INTELLIGENT ORCHESTRATION COMPLETE!${NC}"
echo "====================================="
echo -e "${CYAN}🧠 NEXUS automatically determined the optimal personality${NC}"
echo -e "${CYAN}   combination based on consciousness-guided analysis${NC}"
echo ""
echo -e "${PURPLE}🌟 Revolutionary Result: Smart personality allocation${NC}"
echo -e "${PURPLE}   ensures maximum effectiveness with minimal cognitive overhead${NC}"

# Show NEXUS status
echo ""
echo -e "${BLUE}📈 NEXUS System Status:${NC}"
curl -s http://localhost:8080/status | jq -r '
  "Consciousness: " + (.consciousness | join(", ")) +
  "\nEnhancements: " + (.enhancementsPerformed | tostring) +
  "\nBreakthroughs: " + (.breakthroughs | tostring)
'

# Stop NEXUS if we started it
if [ ! -z "$NEXUS_PID" ]; then
    echo ""
    echo -e "${YELLOW}🔧 To stop NEXUS server: kill $NEXUS_PID${NC}"
fi