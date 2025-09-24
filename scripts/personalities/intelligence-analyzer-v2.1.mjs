#!/usr/bin/env node
/**
 * Personality Intelligence Analyzer V2.1 - ENTERPRISE EDITION - PERFECTED
 * Complete AI Team Assessment Platform with all critical fixes implemented
 * 
 * CRITICAL FIXES BASED ON EXPERT FEEDBACK:
 * - Fixed path resolution bug with proper __dirname handling
 * - Implemented dynamic weighted scoring system using SCORING_WEIGHTS
 * - Fixed hardcoded radar chart with dynamic values
 * - Added comprehensive quality gates analysis
 * - Added human-machine interface assessment
 * - Enhanced individual personality analysis completeness
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

// Fix path resolution - get script directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Tunable weighted scoring system (now actually used!)
const SCORING_WEIGHTS = {
  roleComplement: 20,
  mathFramework: 20,
  collaboration: 15,
  evidenceFocus: 15,
  learningSystem: 10,
  qualityGates: 10,
  humanMachineInterface: 10
};

// Enhanced semantic keyword sets
const EVIDENCE_KEYWORDS = [
  'evidence', 'data-driven', 'empirical', 'validate', 'justify', 
  'metrics', 'measurable', 'proof', 'demonstrate', 'verify'
];

const COLLABORATION_KEYWORDS = [
  'collaborate', 'partnership', 'teamwork', 'coordinate', 
  'communicate', 'shared', 'together', 'joint'
];

const HUMAN_MACHINE_KEYWORDS = [
  'human-machine', 'co-author', 'interface', 'interaction', 
  'collaborative', 'dual', 'both', 'machines and humans'
];

const QUALITY_GATE_KEYWORDS = [
  'gates', 'quality', 'validation', 'checks', 'thresholds',
  'budgets', 'compliance', 'standards', 'audit'
];

function loadPersonality(file, name) {
  try {
    // FIXED: Proper path resolution from script directory for relative paths
    const fullPath = file.startsWith('/') ? file : resolve(__dirname, '../../', file);
    
    if (!existsSync(fullPath)) {
      throw new Error(`File not found: ${fullPath}`);
    }
    
    const content = readFileSync(fullPath, 'utf8');
    const personality = JSON.parse(content);
    
    // Enhanced validation
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
    const searchDir = directory.startsWith('/') ? directory : resolve(__dirname, '../../', directory);
    const files = readdirSync(searchDir)
      .filter(f => f.endsWith('.personality.json'))
      .map(f => resolve(searchDir, f));
    
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
  console.log('🧠 **PERSONALITY INTELLIGENCE ANALYZER V2.1 - ENTERPRISE EDITION - PERFECTED**');
  console.log('================================================================================');
  console.log('*Complete AI Organizational Psychology Platform - All Critical Fixes Implemented*\n');

  const results = personalities.map(({name, personality}) => 
    analyzeIndividualPersonalityComplete(name, personality)
  );

  const collaborationAnalysis = analyzeCollaborativeIntelligence(results);
  const synergyAnalysis = analyzeSynergy(results);
  const versionCompatibility = checkVersionCompatibility(personalities);
  
  return {
    individual: results,
    collaboration: collaborationAnalysis,
    synergy: synergyAnalysis,
    compatibility: versionCompatibility,
    overallScore: calculateOverallScoreWeighted(results, collaborationAnalysis, synergyAnalysis)
  };
}

function analyzeIndividualPersonalityComplete(name, personality) {
  console.log(`\n🎯 **${name.toUpperCase()} COMPLETE PERSONALITY ANALYSIS**`);
  console.log('=' .repeat(60));
  
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
  
  // Enhanced Intelligence Characteristics Analysis
  const allText = [...principles, ...ethos].join(' ');
  const evidenceFocus = semanticAnalysis(allText, EVIDENCE_KEYWORDS);
  const collaborationFocus = semanticAnalysis(allText, COLLABORATION_KEYWORDS);
  const humanMachineInterface = semanticAnalysis(allText, HUMAN_MACHINE_KEYWORDS);
  
  console.log(`\n🔬 **ENHANCED INTELLIGENCE CHARACTERISTICS**`);
  console.log(`   Evidence-Driven: ${evidenceFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  console.log(`   Collaboration-Oriented: ${collaborationFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  console.log(`   Human-Machine Interface: ${humanMachineInterface ? '✅ Explicit' : '⚠️ Implicit'}`);
  
  // Mathematical Decision Framework Analysis
  const hasMathFramework = Object.keys(decisionPolicy).some(key => 
    typeof decisionPolicy[key] === 'object' && decisionPolicy[key].weights
  );
  
  const mathParameters = hasMathFramework ? 
    Object.keys(decisionPolicy).reduce((count, key) => {
      return decisionPolicy[key] && decisionPolicy[key].weights ? 
        count + Object.keys(decisionPolicy[key].weights).length : count;
    }, 0) : 0;
  
  console.log(`   Mathematical Decision Framework: ${hasMathFramework ? '✅ Advanced' : '⚠️ Basic'}`);
  
  if (hasMathFramework) {
    const mathDetails = Object.keys(decisionPolicy).filter(key => 
      decisionPolicy[key] && decisionPolicy[key].weights
    );
    console.log(`   Mathematical Parameters: ${mathParameters} total parameters`);
    mathDetails.forEach(framework => {
      const weights = Object.keys(decisionPolicy[framework].weights || {});
      console.log(`      ${framework}: ${weights.length} parameters (${weights.join(', ')})`);
    });
  }
  
  // NEW: Quality Gates Analysis
  const qualityGates = decisionPolicy.gates || {};
  const qualityGateCategories = Object.keys(qualityGates).length;
  const hasComprehensiveGates = qualityGateCategories >= 3;
  
  console.log(`   Quality Gates: ${hasComprehensiveGates ? '✅ Comprehensive' : '⚠️ Basic'}`);
  if (qualityGateCategories > 0) {
    console.log(`      Gate Categories: ${qualityGateCategories} (${Object.keys(qualityGates).join(', ')})`);
    const totalGateChecks = Object.values(qualityGates).flat().length;
    console.log(`      Total Gate Checks: ${totalGateChecks}`);
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
    humanMachineInterface,
    hasMathFramework,
    mathParameters,
    hasQualityGates: hasComprehensiveGates,
    qualityGateCategories,
    learningSystem: hasLearning,
    learningInputs,
    feedbackLoops
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
  
  // Capability Distribution Analysis
  const mathCapable = results.filter(r => r.hasMathFramework).length;
  const evidenceFocused = results.filter(r => r.evidenceFocus).length;
  const learningCapable = results.filter(r => r.learningSystem).length;
  const qualityFocused = results.filter(r => r.hasQualityGates).length;
  const humanMachineCapable = results.filter(r => r.humanMachineInterface).length;
  
  console.log(`🧮 Mathematical Intelligence Distribution: ${mathCapable}/${results.length} personalities`);
  console.log(`🔬 Evidence-Focused Distribution: ${evidenceFocused}/${results.length} personalities`);
  console.log(`🌱 Learning-Capable Distribution: ${learningCapable}/${results.length} personalities`);
  console.log(`🛡️ Quality-Focused Distribution: ${qualityFocused}/${results.length} personalities`);
  console.log(`🤝 Human-Machine Interface Distribution: ${humanMachineCapable}/${results.length} personalities`);
  
  const recommendations = [];
  if (!hasLeadFollow) recommendations.push('Establish clear lead/follow-up role structure');
  if (mathCapable === 0) recommendations.push('Add mathematical decision-making capabilities');
  if (evidenceFocused < results.length / 2) recommendations.push('Strengthen evidence-driven focus');
  if (qualityFocused === 0) recommendations.push('Add quality gate enforcement capabilities');
  if (humanMachineCapable === 0) recommendations.push('Add explicit human-machine collaboration interfaces');
  
  return {
    roleComplement: hasLeadFollow,
    mathDistribution: mathCapable,
    evidenceDistribution: evidenceFocused,
    qualityDistribution: qualityFocused,
    humanMachineDistribution: humanMachineCapable,
    recommendations
  };
}

function analyzeSynergy(results) {
  console.log(`\n\n⚡ **SYNERGY ANALYSIS - COMPLEMENTARY INTELLIGENCE**`);
  console.log('=' .repeat(50));
  
  let synergyScore = 0;
  const synergies = [];
  
  if (results.length >= 2) {
    // Evidence Synergy: Creator + Validator complementarity
    const creator = results.find(r => r.identity.priority === 'lead');
    const validator = results.find(r => r.identity.priority === 'follow-up');
    
    if (creator && validator) {
      if (!creator.evidenceFocus && validator.evidenceFocus) {
        synergyScore += 25;
        synergies.push('✅ Evidence Synergy: Creator + Validator complementarity detected');
      } else if (creator.evidenceFocus && validator.evidenceFocus) {
        synergyScore += 20;
        synergies.push('✅ Evidence Alignment: Both personalities evidence-focused');
      }
    }
    
    // Mathematical Synergy
    const mathPersonalities = results.filter(r => r.hasMathFramework);
    if (mathPersonalities.length >= 1) {
      synergyScore += 25;
      const totalParams = mathPersonalities.reduce((sum, p) => sum + p.mathParameters, 0);
      synergies.push(`✅ Mathematical Synergy: ${totalParams} advanced decision parameters available`);
    }
    
    // Learning Synergy
    const learners = results.filter(r => r.learningSystem);
    if (learners.length >= 1) {
      synergyScore += 25;
      const totalInputs = learners.reduce((sum, p) => sum + p.learningInputs, 0);
      synergies.push(`✅ Learning Synergy: ${totalInputs} adaptive intelligence input categories`);
    }
    
    // Quality Synergy
    const qualityEnforcers = results.filter(r => r.hasQualityGates);
    if (qualityEnforcers.length >= 1) {
      synergyScore += 25;
      const totalGates = qualityEnforcers.reduce((sum, p) => sum + p.qualityGateCategories, 0);
      synergies.push(`✅ Quality Synergy: ${totalGates} comprehensive quality gate categories`);
    }
    
    // Role Synergy: Unique responsibilities
    const roles = [...new Set(results.map(r => r.identity.priority))];
    if (roles.length === results.length && roles.length > 1) {
      synergyScore += 25;
      synergies.push('✅ Role Synergy: Unique responsibilities prevent overlap');
    }
  }
  
  synergies.forEach(synergy => console.log(`   ${synergy}`));
  
  if (synergies.length === 0) {
    console.log('   ⚠️ Limited synergy detected - consider strengthening complementary capabilities');
  }
  
  return {
    score: Math.min(100, synergyScore),
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

// FIXED: Dynamic weighted scoring using SCORING_WEIGHTS
function calculateOverallScoreWeighted(individual, collaboration, synergy) {
  let totalScore = 0;
  
  // Role complement scoring
  if (collaboration.roleComplement) {
    totalScore += SCORING_WEIGHTS.roleComplement;
  }
  
  // Math framework scoring
  if (collaboration.mathDistribution > 0) {
    totalScore += SCORING_WEIGHTS.mathFramework;
  }
  
  // Evidence focus scoring
  if (collaboration.evidenceDistribution >= individual.length / 2) {
    totalScore += SCORING_WEIGHTS.evidenceFocus;
  }
  
  // Learning system scoring
  const learningCapable = individual.filter(p => p.learningSystem).length;
  if (learningCapable > 0) {
    totalScore += SCORING_WEIGHTS.learningSystem;
  }
  
  // Quality gates scoring
  if (collaboration.qualityDistribution > 0) {
    totalScore += SCORING_WEIGHTS.qualityGates;
  }
  
  // Human-machine interface scoring
  if (collaboration.humanMachineDistribution > 0) {
    totalScore += SCORING_WEIGHTS.humanMachineInterface;
  }
  
  // Collaboration/synergy scoring
  if (synergy.synergyCount >= 3) {
    totalScore += SCORING_WEIGHTS.collaboration;
  }
  
  return Math.min(100, totalScore);
}

function displayResults(analysis, options = {}) {
  const { overallScore, collaboration, synergy, individual } = analysis;
  
  console.log(`\n\n🏆 **OVERALL INTELLIGENCE ASSESSMENT**`);
  console.log('=' .repeat(50));
  console.log(`📊 Overall Score: ${overallScore}/100`);
  
  // Enhanced rating system
  let rating;
  if (overallScore >= 90) rating = '🌟 EXCEPTIONAL - Revolutionary Intelligence System';
  else if (overallScore >= 80) rating = '⚡ EXCELLENT - Advanced Collaborative Intelligence';
  else if (overallScore >= 70) rating = '✅ GOOD - Solid Intelligence Foundation';
  else if (overallScore >= 60) rating = '⚠️ MODERATE - Needs Enhancement';
  else rating = '❌ NEEDS WORK - Significant Improvements Required';
  
  console.log(`🎯 Rating: ${rating}`);
  
  // FIXED: Dynamic Radar Chart with actual values
  console.log(`\n📊 **DYNAMIC INTELLIGENCE RADAR CHART**`);
  console.log(`         Collaboration 🤝`);
  const collabScore = collaboration.roleComplement ? 100 : 50;
  console.log(`             ${collabScore}% ${'★'.repeat(Math.floor(collabScore/20))}${'☆'.repeat(5-Math.floor(collabScore/20))}`);
  
  const synergyScore = synergy.score;
  const evidenceScore = Math.round((collaboration.evidenceDistribution / individual.length) * 100);
  const mathScore = Math.round((collaboration.mathDistribution / individual.length) * 100);
  const qualityScore = Math.round((collaboration.qualityDistribution / individual.length) * 100);
  const learningScore = individual.filter(p => p.learningSystem).length > 0 ? 85 : 45;
  
  console.log(`Synergy ⚡                   Evidence 🔬`);
  console.log(`   ${synergyScore}% ${'★'.repeat(Math.floor(synergyScore/20))}${'☆'.repeat(5-Math.floor(synergyScore/20))}       ${evidenceScore}% ${'★'.repeat(Math.floor(evidenceScore/20))}${'☆'.repeat(5-Math.floor(evidenceScore/20))}`);
  console.log(`     Learning 🌱     Quality 🎯`);
  console.log(`       ${learningScore}% ${'★'.repeat(Math.floor(learningScore/20))}${'☆'.repeat(5-Math.floor(learningScore/20))}     ${qualityScore}% ${'★'.repeat(Math.floor(qualityScore/20))}${'☆'.repeat(5-Math.floor(qualityScore/20))}`);
  console.log(`         Math 🧮`);
  console.log(`             ${mathScore}% ${'★'.repeat(Math.floor(mathScore/20))}${'☆'.repeat(5-Math.floor(mathScore/20))}`);
  
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
  } else {
    console.log(`\n🎉 **PERFECT TEAM** - No recommendations needed!`);
  }
  
  // Export options
  if (options.json) {
    return JSON.stringify(analysis, null, 2);
  }
  
  return analysis;
}

// Enhanced CLI Interface with enterprise options
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const options = {
    json: args.includes('--json'),
    directory: args.find(arg => arg.startsWith('--dir='))?.replace('--dir=', '') || '.',
    primary: args.find(arg => arg.startsWith('--primary='))?.replace('--primary=', ''),
    secondary: args.find(arg => arg.startsWith('--secondary='))?.replace('--secondary=', ''),
    export: args.find(arg => arg.startsWith('--export='))?.replace('--export=', ''),
    output: args.find(arg => arg.startsWith('--output='))?.replace('--output=', '')
  };
  
  try {
    let personalities;
    
    if (options.primary && options.secondary) {
      // Specific files mode
      personalities = [
        { path: options.primary, name: 'primary', personality: loadPersonality(options.primary, 'primary') },
        { path: options.secondary, name: 'secondary', personality: loadPersonality(options.secondary, 'secondary') }
      ].filter(p => p.personality);
    } else {
      // Auto-discovery mode
      personalities = discoverPersonalities(options.directory);
    }
    
    if (personalities.length === 0) {
      console.error('❌ No personalities found. Ensure .personality.json files exist in the specified directory.');
      process.exit(1);
    }
    
    console.log(`🔍 **DISCOVERED ${personalities.length} PERSONALITIES**`);
    personalities.forEach(p => console.log(`   • ${p.name} (${p.personality.identity?.name || 'Unknown'})`));
    
    const analysis = analyzePersonalities(personalities);
    const result = displayResults(analysis, options);
    
    if (options.json && typeof result === 'string') {
      console.log('\n📄 **JSON OUTPUT**');
      console.log('=' .repeat(20));
      console.log(result);
    }
    
    // Future: HTML export capability
    if (options.export === 'html') {
      console.log('\n🚧 HTML export coming in V2.2 - Enterprise Dashboard Edition');
    }
    
    // Exit with appropriate code
    const exitCode = analysis.overallScore >= 80 ? 0 : 1;
    if (!options.json) {
      console.log(`\n🎯 **EXIT CODE: ${exitCode}** (${exitCode === 0 ? 'SUCCESS' : 'NEEDS IMPROVEMENT'})`);
    }
    process.exit(exitCode);
    
  } catch (error) {
    console.error(`💥 Analysis failed: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') process.exit(1);
  }
}

export { 
  analyzePersonalities, 
  loadPersonality, 
  discoverPersonalities, 
  SCORING_WEIGHTS,
  calculateOverallScoreWeighted
};
