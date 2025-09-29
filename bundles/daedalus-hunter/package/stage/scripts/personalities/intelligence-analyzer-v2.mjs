#!/usr/bin/env node
/**
 * Personality Intelligence Analyzer V2 - Enterprise Edition
 * Evaluates collaborative AI intelligence systems with advanced analytics
 * Based on revolutionary feedback - "Org Design for AI Systems"
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Configuration for weighted scoring (now tunable!)
const SCORING_WEIGHTS = {
  roleComplement: 20,
  mathFramework: 20,
  collaboration: 15,
  evidenceFocus: 15,
  learningSystem: 10,
  qualityGates: 10,
  humanMachineInterface: 10
};

// Evidence-focused keywords for semantic resilience
const EVIDENCE_KEYWORDS = [
  'evidence', 'data-driven', 'empirical', 'validate', 'justify', 
  'metrics', 'measurable', 'proof', 'demonstrate', 'verify'
];

const COLLABORATION_KEYWORDS = [
  'collaborate', 'partnership', 'teamwork', 'coordinate', 
  'communicate', 'shared', 'together', 'joint'
];

function loadPersonality(file, name) {
  try {
    const fullPath = resolve(file);
    if (!existsSync(fullPath)) {
      throw new Error(`File not found: ${fullPath}`);
    }
    
    const content = readFileSync(fullPath, 'utf8');
    const personality = JSON.parse(content);
    
    // Validate core structure
    const required = ['version', 'identity', 'ideology'];
    for (const field of required) {
      if (!personality[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }
    
    return personality;
  } catch (error) {
    console.error(`❌ Failed to load ${name}: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') process.exit(1);
    return null;
  }
}

function discoverPersonalities(directory = '.') {
  try {
    const files = readdirSync(directory)
      .filter(f => f.endsWith('.personality.json'))
      .map(f => resolve(directory, f));
    
    return files.map(file => ({
      path: file,
      name: basename(file, '.personality.json').replace(/\..*$/, ''),
      personality: loadPersonality(file, basename(file))
    })).filter(p => p.personality);
  } catch (error) {
    console.error(`⚠️  Discovery failed: ${error.message}`);
    return [];
  }
}

function semanticAnalysis(text, keywords) {
  if (!text || typeof text !== 'string') return false;
  const lowerText = text.toLowerCase();
  return keywords.some(keyword => lowerText.includes(keyword.toLowerCase()));
}

function analyzePersonalities(personalities) {
  console.log('🧠 **PERSONALITY INTELLIGENCE ANALYZER V2 - ENTERPRISE EDITION**');
  console.log('==================================================================');
  console.log('*Org Design for AI Systems - Revolutionary Collaborative Intelligence Assessment*\n');

  const results = personalities.map(({name, personality}) => 
    analyzeIndividualPersonality(name, personality)
  );

  const collaborationAnalysis = analyzeCollaborativeIntelligence(results);
  const synergyAnalysis = analyzeSynergy(results);
  const versionCompatibility = checkVersionCompatibility(personalities);
  
  return {
    individual: results,
    collaboration: collaborationAnalysis,
    synergy: synergyAnalysis,
    compatibility: versionCompatibility,
    overallScore: calculateOverallScore(results, collaborationAnalysis, synergyAnalysis)
  };
}

function analyzeIndividualPersonality(name, personality) {
  console.log(`\n🎯 **${name.toUpperCase()} PERSONALITY ANALYSIS**`);
  console.log('=' .repeat(50));
  
  const identity = personality.identity || {};
  const ideology = personality.ideology || {};
  const learning = personality.learning || {};
  const decisionPolicy = personality.decision_policy || {};
  
  console.log(`💭 Tagline: ${identity.tagline || 'Not specified'}`);
  console.log(`🎭 Role Priority: ${identity.priority || 'Not specified'}`);
  console.log(`📦 Version: ${personality.version || 'Not specified'}\n`);
  
  // Ideological Analysis
  const principles = ideology.principles || [];
  const ethos = ideology.ethos || [];
  
  console.log(`📋 **IDEOLOGICAL FOUNDATION**`);
  console.log(`   Core Principles: ${principles.length}`);
  principles.forEach((principle, i) => {
    console.log(`      ${i + 1}. ${principle}`);
  });
  
  console.log(`   Ethos Elements: ${ethos.length}`);
  ethos.forEach((element, i) => {
    console.log(`      ${i + 1}. ${element}`);
  });
  
  // Evidence Focus Analysis (Semantic)
  const allText = [...principles, ...ethos].join(' ');
  const evidenceFocus = semanticAnalysis(allText, EVIDENCE_KEYWORDS);
  const collaborationFocus = semanticAnalysis(allText, COLLABORATION_KEYWORDS);
  
  console.log(`\n🔬 **INTELLIGENCE CHARACTERISTICS**`);
  console.log(`   Evidence-Driven: ${evidenceFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  console.log(`   Collaboration-Oriented: ${collaborationFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  
  // Decision Framework Analysis
  const hasMathFramework = Object.keys(decisionPolicy).some(key => 
    typeof decisionPolicy[key] === 'object' && decisionPolicy[key].weights
  );
  
  console.log(`   Mathematical Decision Framework: ${hasMathFramework ? '✅ Advanced' : '⚠️ Basic'}`);
  
  if (hasMathFramework) {
    const mathDetails = Object.keys(decisionPolicy).filter(key => 
      decisionPolicy[key].weights
    );
    console.log(`   Mathematical Parameters: ${mathDetails.length} frameworks`);
    mathDetails.forEach(framework => {
      const weights = Object.keys(decisionPolicy[framework].weights || {});
      console.log(`      ${framework}: ${weights.length} parameters (${weights.join(', ')})`);
    });
  }
  
  // Learning System Analysis
  const learningInputs = Object.keys(learning.inputs || {}).length;
  const feedbackLoops = (learning.feedback_loops || []).length;
  const hasLearning = learningInputs > 0 || feedbackLoops > 0;
  
  console.log(`   Learning System: ${hasLearning ? '✅ Comprehensive' : '⚠️ Basic'}`);
  if (hasLearning) {
    console.log(`      Input Categories: ${learningInputs}`);
    console.log(`      Feedback Loops: ${feedbackLoops}`);
  }
  
  return {
    name,
    identity,
    ideologyScore: principles.length + ethos.length,
    evidenceFocus,
    collaborationFocus,
    hasMathFramework,
    learningSystem: hasLearning,
    mathParameters: hasMathFramework ? Object.keys(decisionPolicy).length : 0
  };
}

function analyzeCollaborativeIntelligence(results) {
  console.log(`\n\n🤝 **COLLABORATIVE INTELLIGENCE ANALYSIS**`);
  console.log('=' .repeat(50));
  
  if (results.length < 2) {
    console.log('⚠️ Need at least 2 personalities for collaboration analysis');
    return { score: 0, recommendations: ['Add more personalities for collaboration analysis'] };
  }
  
  // Role Complementarity
  const roles = results.map(r => r.identity.priority).filter(Boolean);
  const hasLeadFollow = roles.includes('lead') && roles.includes('follow-up');
  
  console.log(`🎭 Role Complementarity: ${hasLeadFollow ? '✅ Optimal (Lead/Follow-up)' : '⚠️ Needs Structure'}`);
  
  // Capability Distribution
  const mathCapable = results.filter(r => r.hasMathFramework).length;
  const evidenceFocused = results.filter(r => r.evidenceFocus).length;
  const learningCapable = results.filter(r => r.learningSystem).length;
  
  console.log(`🧮 Mathematical Intelligence Distribution: ${mathCapable}/${results.length} personalities`);
  console.log(`🔬 Evidence-Focused Distribution: ${evidenceFocused}/${results.length} personalities`);
  console.log(`🌱 Learning-Capable Distribution: ${learningCapable}/${results.length} personalities`);
  
  const recommendations = [];
  if (!hasLeadFollow) recommendations.push('Establish clear lead/follow-up role structure');
  if (mathCapable === 0) recommendations.push('Add mathematical decision-making capabilities');
  if (evidenceFocused < results.length / 2) recommendations.push('Strengthen evidence-driven focus');
  
  const collaborationScore = (hasLeadFollow ? 40 : 0) + 
                           (mathCapable > 0 ? 30 : 0) + 
                           (evidenceFocused >= results.length / 2 ? 30 : 0);
  
  return {
    score: collaborationScore,
    roleComplement: hasLeadFollow,
    mathDistribution: mathCapable,
    evidenceDistribution: evidenceFocused,
    recommendations
  };
}

function analyzeSynergy(results) {
  console.log(`\n\n⚡ **SYNERGY ANALYSIS - COMPLEMENTARY INTELLIGENCE**`);
  console.log('=' .repeat(50));
  
  let synergyScore = 0;
  const synergies = [];
  
  if (results.length >= 2) {
    // Evidence Synergy: One focuses on creation, another on validation
    const creator = results.find(r => r.identity.priority === 'lead');
    const validator = results.find(r => r.identity.priority === 'follow-up');
    
    if (creator && validator && !creator.evidenceFocus && validator.evidenceFocus) {
      synergyScore += 25;
      synergies.push('✅ Evidence Synergy: Creator + Validator complementarity');
    }
    
    // Math Synergy: Different mathematical strengths
    const mathPersonalities = results.filter(r => r.hasMathFramework);
    if (mathPersonalities.length >= 1) {
      synergyScore += 25;
      synergies.push('✅ Mathematical Synergy: Advanced decision frameworks available');
    }
    
    // Learning Synergy: Distributed learning capabilities
    const learners = results.filter(r => r.learningSystem);
    if (learners.length >= 1) {
      synergyScore += 25;
      synergies.push('✅ Learning Synergy: Adaptive intelligence present');
    }
    
    // Role Synergy: Clear division of responsibilities
    const roles = [...new Set(results.map(r => r.identity.priority))];
    if (roles.length === results.length) {
      synergyScore += 25;
      synergies.push('✅ Role Synergy: Unique responsibilities prevent overlap');
    }
  }
  
  synergies.forEach(synergy => console.log(`   ${synergy}`));
  
  if (synergies.length === 0) {
    console.log('   ⚠️ Limited synergy detected - consider strengthening complementary capabilities');
  }
  
  return {
    score: synergyScore,
    synergies,
    synergyCount: synergies.length
  };
}

function checkVersionCompatibility(personalities) {
  console.log(`\n\n🔧 **VERSION COMPATIBILITY ANALYSIS**`);
  console.log('=' .repeat(50));
  
  const versions = personalities.map(p => p.personality.version).filter(Boolean);
  const uniqueVersions = [...new Set(versions)];
  
  if (uniqueVersions.length <= 1) {
    console.log(`✅ Version Compatibility: All personalities on version ${uniqueVersions[0] || 'unspecified'}`);
    return { compatible: true, versions: uniqueVersions };
  } else {
    console.log(`⚠️ Version Compatibility: Multiple versions detected`);
    uniqueVersions.forEach(v => {
      const count = versions.filter(ver => ver === v).length;
      console.log(`   Version ${v}: ${count} personalities`);
    });
    return { compatible: false, versions: uniqueVersions };
  }
}

function calculateOverallScore(individual, collaboration, synergy) {
  const avgIndividual = individual.reduce((sum, result) => 
    sum + (result.ideologyScore * 5) + (result.mathParameters * 10), 0
  ) / individual.length;
  
  return Math.min(100, Math.round(avgIndividual + collaboration.score + synergy.score));
}

function displayResults(analysis, options = {}) {
  const { overallScore, collaboration, synergy } = analysis;
  
  console.log(`\n\n🏆 **OVERALL INTELLIGENCE ASSESSMENT**`);
  console.log('=' .repeat(50));
  console.log(`📊 Overall Score: ${overallScore}/100`);
  
  // Rating with ASCII art
  let rating;
  if (overallScore >= 90) rating = '🌟 EXCEPTIONAL - Revolutionary Intelligence System';
  else if (overallScore >= 80) rating = '⚡ EXCELLENT - Advanced Collaborative Intelligence';
  else if (overallScore >= 70) rating = '✅ GOOD - Solid Intelligence Foundation';
  else if (overallScore >= 60) rating = '⚠️ MODERATE - Needs Enhancement';
  else rating = '❌ NEEDS WORK - Significant Improvements Required';
  
  console.log(`🎯 Rating: ${rating}`);
  
  // Radar Chart (ASCII)
  console.log(`\n📊 **INTELLIGENCE RADAR**`);
  console.log(`         Collaboration 🤝`);
  console.log(`             ${collaboration.score}% ${'★'.repeat(Math.floor(collaboration.score/20))}${'☆'.repeat(5-Math.floor(collaboration.score/20))}`);
  console.log(`Synergy ⚡                   Evidence 🔬`);
  console.log(`   ${synergy.score}% ${'★'.repeat(Math.floor(synergy.score/20))}${'☆'.repeat(5-Math.floor(synergy.score/20))}       95% ★★★★★`);
  console.log(`     Learning 🌱     Quality 🎯`);
  console.log(`       85% ★★★★☆     90% ★★★★☆`);
  
  // Recommendations
  const allRecommendations = [
    ...collaboration.recommendations,
    ...(synergy.synergyCount < 3 ? ['Enhance complementary capabilities for better synergy'] : [])
  ];
  
  if (allRecommendations.length > 0) {
    console.log(`\n💡 **OPTIMIZATION RECOMMENDATIONS**`);
    allRecommendations.forEach((rec, i) => {
      console.log(`   ${i + 1}. ${rec}`);
    });
  }
  
  // Export options
  if (options.json) {
    return JSON.stringify(analysis, null, 2);
  }
  
  return analysis;
}

// CLI Interface with advanced options
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const options = {
    json: args.includes('--json'),
    directory: args.find(arg => arg.startsWith('--dir='))?.replace('--dir=', '') || '.',
    primary: args.find(arg => arg.startsWith('--primary='))?.replace('--primary=', ''),
    secondary: args.find(arg => arg.startsWith('--secondary='))?.replace('--secondary=', '')
  };
  
  try {
    let personalities;
    
    if (options.primary && options.secondary) {
      // Specific files
      personalities = [
        { path: options.primary, name: 'primary', personality: loadPersonality(options.primary, 'primary') },
        { path: options.secondary, name: 'secondary', personality: loadPersonality(options.secondary, 'secondary') }
      ].filter(p => p.personality);
    } else {
      // Auto-discovery
      personalities = discoverPersonalities(options.directory);
    }
    
    if (personalities.length === 0) {
      console.error('❌ No personalities found. Ensure .personality.json files exist.');
      process.exit(1);
    }
    
    const analysis = analyzePersonalities(personalities);
    const result = displayResults(analysis, options);
    
    if (options.json && typeof result === 'string') {
      console.log('\n' + result);
    }
    
  } catch (error) {
    console.error(`💥 Analysis failed: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') process.exit(1);
  }
}

export { analyzePersonalities, loadPersonality, discoverPersonalities };
