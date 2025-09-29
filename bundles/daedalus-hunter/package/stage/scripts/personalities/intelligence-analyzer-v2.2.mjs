#!/usr/bin/env node
/**
 * Personality Intelligence Analyzer V2.2 - REALISTIC EXCELLENCE EDITION
 * Anti-fragile AI Team Assessment with Recalibrated Scoring and Deep Analysis
 * 
 * CRITICAL FIXES BASED ON PERFECTION ANALYSIS:
 * - Recalibrated scoring weights to prioritize Quality and Math for production
 * - Deep quality gate analysis (coverage + depth measurement)
 * - Enhanced mathematical sophistication evaluation
 * - Realistic excellence scoring (92/100 target, not false 100/100)
 * - Stress-test mode for antifragile system design
 * - "Perfect" danger detection and warnings
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// RECALIBRATED: Production-focused scoring weights
const SCORING_WEIGHTS = {
  roleComplement: 15,        // ↓ Still important, not over-weighted
  mathFramework: 25,         // ↑ Critical for intelligent decisions
  collaboration: 15,         // ↓ Collaboration without capability = dangerous
  evidenceFocus: 15,         // Keep strong - foundation of intelligence
  learningSystem: 10,        // Keep - adaptive capability
  qualityGates: 20,          // ↑ MOST critical for production systems
  humanMachineInterface: 10  // Keep - essential for modern AI
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

// Production quality gate requirements
const CRITICAL_QUALITY_GATES = [
  'security', 'accessibility', 'performance', 'build', 'seo'
];

const ADVANCED_QUALITY_GATES = [
  'privacy', 'internationalization', 'compliance', 'audit', 'monitoring'
];

function loadPersonality(file, name) {
  try {
    const fullPath = file.startsWith('/') ? file : resolve(__dirname, '../../', file);
    
    if (!existsSync(fullPath)) {
      throw new Error(`File not found: ${fullPath}`);
    }
    
    const content = readFileSync(fullPath, 'utf8');
    const personality = JSON.parse(content);
    
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

// NEW: Deep Quality Gate Analysis
function analyzeQualityGatesDeep(personality) {
  const gates = personality.decision_policy?.gates || {};
  const categories = Object.keys(gates);
  
  // Calculate coverage based on critical gates
  const criticalCoverage = CRITICAL_QUALITY_GATES.filter(gate => 
    categories.some(cat => cat.toLowerCase().includes(gate))
  ).length;
  const coverageScore = Math.round((criticalCoverage / CRITICAL_QUALITY_GATES.length) * 100);
  
  // Calculate depth based on total rules
  const totalRules = categories.reduce((sum, cat) => {
    const gateRules = gates[cat];
    if (Array.isArray(gateRules)) return sum + gateRules.length;
    if (typeof gateRules === 'object') return sum + Object.keys(gateRules).length;
    return sum + 1;
  }, 0);
  
  const depthScore = totalRules >= 20 ? 100 : 
                   totalRules >= 12 ? 80 :
                   totalRules >= 6 ? 60 :
                   totalRules >= 3 ? 40 : 20;
  
  // Advanced gates bonus
  const advancedCoverage = ADVANCED_QUALITY_GATES.filter(gate =>
    categories.some(cat => cat.toLowerCase().includes(gate))
  ).length;
  const advancedBonus = advancedCoverage * 5;
  
  const finalScore = Math.min(100, Math.round((coverageScore + depthScore + advancedBonus) / 2));
  
  return {
    coverage: coverageScore,
    depth: depthScore,
    advanced: advancedCoverage,
    totalRules,
    categories: categories.length,
    score: finalScore,
    rating: finalScore >= 80 ? 'Comprehensive' : 
           finalScore >= 60 ? 'Good' :
           finalScore >= 40 ? 'Basic' : 'Insufficient'
  };
}

// NEW: Deep Mathematical Sophistication Analysis
function analyzeMathematicalDepth(personality) {
  const decisionPolicy = personality.decision_policy || {};
  const mathFrameworks = personality.mathematical_frameworks || {};
  
  let sophisticationScore = 0;
  const capabilities = [];
  
  // Basic mathematical parameters
  let totalParams = 0;
  Object.keys(decisionPolicy).forEach(key => {
    if (decisionPolicy[key] && decisionPolicy[key].weights) {
      const params = Object.keys(decisionPolicy[key].weights).length;
      totalParams += params;
      capabilities.push(`${key}: ${params} parameters`);
    }
  });
  
  if (totalParams > 0) {
    sophisticationScore += Math.min(30, totalParams * 6);
  }
  
  // Advanced mathematical frameworks
  if (mathFrameworks.optimization_targets) {
    sophisticationScore += 25;
    capabilities.push('Multi-objective optimization');
  }
  
  if (mathFrameworks.fairness_metrics) {
    sophisticationScore += 25;
    capabilities.push('Fairness/ethics modeling');
    
    // Check for specific fairness algorithms
    const fairness = mathFrameworks.fairness_metrics;
    if (fairness.gini_coefficient) {
      sophisticationScore += 10;
      capabilities.push('Gini coefficient inequality measurement');
    }
    if (fairness.cluster_purity) {
      sophisticationScore += 10;
      capabilities.push('Geographic relationship coherence');
    }
  }
  
  if (mathFrameworks.optimization_targets?.policy_sweeper) {
    sophisticationScore += 20;
    capabilities.push('Automated A/B testing for configurations');
  }
  
  // Constraint handling and multi-objective optimization
  if (mathFrameworks.optimization_targets?.pareto_frontier) {
    sophisticationScore += 15;
    capabilities.push('Pareto frontier optimization');
  }
  
  const finalScore = Math.min(100, sophisticationScore);
  
  return {
    totalParameters: totalParams,
    capabilities,
    sophisticationScore: finalScore,
    rating: finalScore >= 85 ? 'Advanced' :
           finalScore >= 70 ? 'Good' :
           finalScore >= 50 ? 'Basic' : 'Insufficient'
  };
}

function analyzePersonalities(personalities, options = {}) {
  const stressTest = options.stressTest || false;
  
  console.log('🧠 **PERSONALITY INTELLIGENCE ANALYZER V2.2 - REALISTIC EXCELLENCE EDITION**');
  console.log('================================================================================');
  console.log('*Anti-fragile AI Team Assessment - Production-Ready Intelligence Measurement*');
  
  if (stressTest) {
    console.log('🔥 **STRESS TEST MODE ENABLED** - Adversarial Evaluation Active');
  }
  
  console.log('');

  const results = personalities.map(({name, personality}) => 
    analyzeIndividualPersonalityRealistic(name, personality, { stressTest })
  );

  const collaborationAnalysis = analyzeCollaborativeIntelligenceV2(results);
  const synergyAnalysis = analyzeSynergyRealistic(results);
  const versionCompatibility = checkVersionCompatibility(personalities);
  
  return {
    individual: results,
    collaboration: collaborationAnalysis,
    synergy: synergyAnalysis,
    compatibility: versionCompatibility,
    overallScore: calculateRealisticScore(results, collaborationAnalysis, synergyAnalysis),
    stressTest: stressTest
  };
}

function analyzeIndividualPersonalityRealistic(name, personality, options = {}) {
  console.log(`\n🎯 **${name.toUpperCase()} REALISTIC INTELLIGENCE ANALYSIS**`);
  console.log('=' .repeat(65));
  
  const identity = personality.identity || {};
  const ideology = personality.ideology || {};
  const learning = personality.learning || {};
  
  console.log(`💭 Tagline: ${identity.tagline || 'Not specified'}`);
  console.log(`🎭 Role Priority: ${identity.priority || 'Not specified'}`);
  console.log(`📦 Version: ${personality.version || 'Not specified'}\n`);
  
  // Enhanced Intelligence Analysis
  const principles = ideology.principles || [];
  const ethos = ideology.ethos || [];
  const allText = [...principles, ...ethos].join(' ');
  
  const evidenceFocus = semanticAnalysis(allText, EVIDENCE_KEYWORDS);
  const collaborationFocus = semanticAnalysis(allText, COLLABORATION_KEYWORDS);
  const humanMachineInterface = semanticAnalysis(allText, HUMAN_MACHINE_KEYWORDS);
  
  // DEEP ANALYSIS: Quality Gates
  const qualityAnalysis = analyzeQualityGatesDeep(personality);
  console.log(`🛡️ **PRODUCTION QUALITY ANALYSIS**`);
  console.log(`   Overall Quality Score: ${qualityAnalysis.score}/100 (${qualityAnalysis.rating})`);
  console.log(`   Gate Coverage: ${qualityAnalysis.coverage}% (${qualityAnalysis.categories} categories)`);
  console.log(`   Rule Depth: ${qualityAnalysis.depth}% (${qualityAnalysis.totalRules} total rules)`);
  if (qualityAnalysis.advanced > 0) {
    console.log(`   Advanced Gates: ${qualityAnalysis.advanced} (privacy, i18n, compliance)`);
  }
  
  // DEEP ANALYSIS: Mathematical Sophistication  
  const mathAnalysis = analyzeMathematicalDepth(personality);
  console.log(`\n🧮 **MATHEMATICAL SOPHISTICATION ANALYSIS**`);
  console.log(`   Overall Math Score: ${mathAnalysis.sophisticationScore}/100 (${mathAnalysis.rating})`);
  console.log(`   Decision Parameters: ${mathAnalysis.totalParameters}`);
  mathAnalysis.capabilities.forEach(cap => {
    console.log(`   • ${cap}`);
  });
  
  // Standard Intelligence Characteristics
  console.log(`\n🔬 **INTELLIGENCE CHARACTERISTICS**`);
  console.log(`   Evidence-Driven: ${evidenceFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  console.log(`   Collaboration-Oriented: ${collaborationFocus ? '✅ Strong' : '⚠️ Moderate'}`);
  console.log(`   Human-Machine Interface: ${humanMachineInterface ? '✅ Explicit' : '⚠️ Implicit'}`);
  
  // Learning System Analysis
  const learningInputs = Object.keys(learning.inputs || {}).length;
  const feedbackLoops = (learning.feedback_loops || []).length;
  const hasLearning = learningInputs > 0 || feedbackLoops > 0;
  
  console.log(`   Learning System: ${hasLearning ? '✅ Comprehensive' : '⚠️ Basic'}`);
  if (hasLearning) {
    console.log(`      Input Categories: ${learningInputs}`);
    console.log(`      Feedback Loops: ${feedbackLoops}`);
  }
  
  // Stress Test Warnings
  if (options.stressTest) {
    console.log(`\n🔥 **STRESS TEST RESULTS**`);
    if (qualityAnalysis.score < 80) {
      console.log(`   ⚠️ VULNERABILITY: Quality gates insufficient for production load`);
    }
    if (mathAnalysis.sophisticationScore < 70) {
      console.log(`   ⚠️ VULNERABILITY: Mathematical frameworks may fail under complex optimization`);
    }
    if (!evidenceFocus) {
      console.log(`   ⚠️ VULNERABILITY: Lack of evidence focus = potential for assumption-based failures`);
    }
  }
  
  return {
    name,
    identity,
    ideologyScore: principles.length + ethos.length,
    evidenceFocus,
    collaborationFocus,
    humanMachineInterface,
    qualityAnalysis,
    mathAnalysis,
    learningSystem: hasLearning,
    learningInputs,
    feedbackLoops
  };
}

function analyzeCollaborativeIntelligenceV2(results) {
  console.log(`\n\n🤝 **COLLABORATIVE INTELLIGENCE ANALYSIS V2**`);
  console.log('=' .repeat(50));
  
  if (results.length < 2) {
    console.log('⚠️ Need at least 2 personalities for collaboration analysis');
    return { 
      score: 0, 
      recommendations: ['Add more personalities for collaboration analysis'],
      distribution: {}
    };
  }
  
  // Role Complementarity
  const roles = results.map(r => r.identity.priority).filter(Boolean);
  const hasLeadFollow = roles.includes('lead') && roles.includes('follow-up');
  
  console.log(`🎭 Role Complementarity: ${hasLeadFollow ? '✅ Optimal (Lead/Follow-up)' : '⚠️ Needs Structure'}`);
  
  // Realistic Capability Distribution Analysis
  const mathCapable = results.filter(r => r.mathAnalysis.sophisticationScore >= 70).length;
  const evidenceFocused = results.filter(r => r.evidenceFocus).length;
  const qualityFocused = results.filter(r => r.qualityAnalysis.score >= 80).length;
  const learningCapable = results.filter(r => r.learningSystem).length;
  const humanMachineCapable = results.filter(r => r.humanMachineInterface).length;
  
  console.log(`🧮 Advanced Mathematical Intelligence: ${mathCapable}/${results.length} personalities (≥70% threshold)`);
  console.log(`🔬 Evidence-Focused Distribution: ${evidenceFocused}/${results.length} personalities`);
  console.log(`🛡️ Production-Ready Quality Focus: ${qualityFocused}/${results.length} personalities (≥80% threshold)`);
  console.log(`🌱 Learning-Capable Distribution: ${learningCapable}/${results.length} personalities`);
  console.log(`🤝 Human-Machine Interface Distribution: ${humanMachineCapable}/${results.length} personalities`);
  
  // Realistic recommendations
  const recommendations = [];
  if (!hasLeadFollow) recommendations.push('Establish clear lead/follow-up role structure');
  if (mathCapable === 0) recommendations.push('CRITICAL: No personalities meet advanced mathematical threshold (70%+)');
  if (qualityFocused === 0) recommendations.push('CRITICAL: No personalities meet production quality threshold (80%+)');
  if (evidenceFocused < results.length / 2) recommendations.push('Strengthen evidence-driven focus across team');
  if (humanMachineCapable === 0) recommendations.push('Add explicit human-machine collaboration interfaces');
  
  return {
    roleComplement: hasLeadFollow,
    mathDistribution: mathCapable,
    evidenceDistribution: evidenceFocused,
    qualityDistribution: qualityFocused,
    humanMachineDistribution: humanMachineCapable,
    learningDistribution: learningCapable,
    recommendations,
    distribution: {
      math: mathCapable / results.length,
      evidence: evidenceFocused / results.length,
      quality: qualityFocused / results.length,
      learning: learningCapable / results.length,
      humanMachine: humanMachineCapable / results.length
    }
  };
}

function analyzeSynergyRealistic(results) {
  console.log(`\n\n⚡ **REALISTIC SYNERGY ANALYSIS**`);
  console.log('=' .repeat(40));
  
  let synergyScore = 0;
  const synergies = [];
  const gaps = [];
  
  if (results.length >= 2) {
    // Evidence-Quality Synergy
    const evidenceStrong = results.filter(r => r.evidenceFocus);
    const qualityStrong = results.filter(r => r.qualityAnalysis.score >= 80);
    
    if (evidenceStrong.length > 0 && qualityStrong.length > 0) {
      synergyScore += 25;
      synergies.push('✅ Evidence-Quality Synergy: Strong empirical validation + production gates');
    } else {
      gaps.push('⚠️ Gap: Need both evidence focus AND production quality gates');
    }
    
    // Math-Implementation Synergy
    const mathStrong = results.filter(r => r.mathAnalysis.sophisticationScore >= 70);
    const implementationCapable = results.filter(r => r.qualityAnalysis.score >= 60);
    
    if (mathStrong.length > 0 && implementationCapable.length > 0) {
      synergyScore += 25;
      const totalParams = mathStrong.reduce((sum, r) => sum + r.mathAnalysis.totalParameters, 0);
      synergies.push(`✅ Math-Implementation Synergy: ${totalParams} advanced parameters with quality enforcement`);
    } else {
      gaps.push('⚠️ Gap: Mathematical sophistication needs implementation quality backing');
    }
    
    // Learning-Adaptation Synergy
    const learners = results.filter(r => r.learningSystem && r.feedbackLoops > 0);
    if (learners.length >= 1) {
      synergyScore += 20;
      const totalInputs = learners.reduce((sum, r) => sum + r.learningInputs, 0);
      synergies.push(`✅ Learning-Adaptation Synergy: ${totalInputs} input categories with feedback loops`);
    } else {
      gaps.push('⚠️ Gap: Need learning systems with active feedback loops');
    }
    
    // Role Complementarity Check
    const roles = [...new Set(results.map(r => r.identity.priority))];
    if (roles.length === results.length && roles.length > 1) {
      synergyScore += 20;
      synergies.push('✅ Role Complementarity: Unique responsibilities prevent overlap');
    } else {
      gaps.push('⚠️ Gap: Role overlap detected - unclear responsibility boundaries');
    }
    
    // Human-Machine Interface Synergy
    const interfaceCapable = results.filter(r => r.humanMachineInterface);
    if (interfaceCapable.length >= 1) {
      synergyScore += 10;
      synergies.push('✅ Human-Machine Synergy: Explicit collaboration interfaces present');
    } else {
      gaps.push('⚠️ Gap: No explicit human-machine collaboration interfaces');
    }
  }
  
  console.log('**SYNERGIES DETECTED:**');
  synergies.forEach(synergy => console.log(`   ${synergy}`));
  
  if (gaps.length > 0) {
    console.log('\n**SYNERGY GAPS:**');
    gaps.forEach(gap => console.log(`   ${gap}`));
  }
  
  return {
    score: Math.min(100, synergyScore),
    synergies,
    gaps,
    synergyCount: synergies.length,
    gapCount: gaps.length
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

// REALISTIC SCORING: Properly weighted, hard to achieve perfection
function calculateRealisticScore(individual, collaboration, synergy) {
  let totalScore = 0;
  const scoringDetails = [];
  
  // Role complement scoring
  if (collaboration.roleComplement) {
    totalScore += SCORING_WEIGHTS.roleComplement;
    scoringDetails.push(`Role Complement: +${SCORING_WEIGHTS.roleComplement}`);
  }
  
  // Advanced math framework scoring (stricter threshold)
  const advancedMath = collaboration.mathDistribution;
  if (advancedMath > 0) {
    const mathScore = Math.round(SCORING_WEIGHTS.mathFramework * (advancedMath / individual.length));
    totalScore += mathScore;
    scoringDetails.push(`Advanced Math: +${mathScore} (${advancedMath}/${individual.length} personalities)`);
  }
  
  // Evidence focus scoring
  if (collaboration.evidenceDistribution >= individual.length / 2) {
    totalScore += SCORING_WEIGHTS.evidenceFocus;
    scoringDetails.push(`Evidence Focus: +${SCORING_WEIGHTS.evidenceFocus}`);
  }
  
  // Learning system scoring
  if (collaboration.learningDistribution > 0) {
    const learningScore = Math.round(SCORING_WEIGHTS.learningSystem * (collaboration.learningDistribution / individual.length));
    totalScore += learningScore;
    scoringDetails.push(`Learning Systems: +${learningScore}`);
  }
  
  // Production quality gates scoring (stricter threshold)
  const productionReady = collaboration.qualityDistribution;
  if (productionReady > 0) {
    const qualityScore = Math.round(SCORING_WEIGHTS.qualityGates * (productionReady / individual.length));
    totalScore += qualityScore;
    scoringDetails.push(`Production Quality: +${qualityScore} (${productionReady}/${individual.length} personalities)`);
  }
  
  // Human-machine interface scoring
  if (collaboration.humanMachineDistribution > 0) {
    const interfaceScore = Math.round(SCORING_WEIGHTS.humanMachineInterface * (collaboration.humanMachineDistribution / individual.length));
    totalScore += interfaceScore;
    scoringDetails.push(`Human-Machine Interface: +${interfaceScore}`);
  }
  
  // Synergy scoring (realistic expectations)
  if (synergy.synergyCount >= 4 && synergy.gapCount <= 1) {
    totalScore += SCORING_WEIGHTS.collaboration;
    scoringDetails.push(`Synergy Excellence: +${SCORING_WEIGHTS.collaboration}`);
  } else if (synergy.synergyCount >= 3) {
    const partialSynergy = Math.round(SCORING_WEIGHTS.collaboration * 0.7);
    totalScore += partialSynergy;
    scoringDetails.push(`Good Synergy: +${partialSynergy}`);
  }
  
  return {
    score: Math.min(100, totalScore),
    details: scoringDetails,
    maxPossible: Object.values(SCORING_WEIGHTS).reduce((sum, weight) => sum + weight, 0)
  };
}

function displayResults(analysis, options = {}) {
  const { overallScore, collaboration, synergy, individual, stressTest } = analysis;
  const scoreDetails = overallScore.details || [];
  
  console.log(`\n\n🏆 **REALISTIC INTELLIGENCE ASSESSMENT**`);
  console.log('=' .repeat(50));
  console.log(`📊 Overall Score: ${overallScore.score}/100 (Max Possible: ${overallScore.maxPossible})`);
  
  // Realistic rating system
  let rating;
  if (overallScore.score >= 92) rating = '🌟 EXCEPTIONAL - Production-Ready Excellence (Rare Achievement!)';
  else if (overallScore.score >= 85) rating = '⚡ EXCELLENT - Advanced Intelligence System';
  else if (overallScore.score >= 75) rating = '✅ GOOD - Solid Foundation with Growth Potential';
  else if (overallScore.score >= 65) rating = '⚠️ MODERATE - Needs Enhancement for Production';
  else rating = '❌ DEVELOPING - Significant Improvements Required';
  
  console.log(`🎯 Rating: ${rating}`);
  
  // Show scoring breakdown
  console.log(`\n🔍 **SCORING BREAKDOWN**`);
  scoreDetails.forEach(detail => {
    console.log(`   • ${detail}`);
  });
  
  // REALISTIC Dynamic Radar Chart
  console.log(`\n📊 **REALISTIC INTELLIGENCE RADAR**`);
  console.log(`         Collaboration 🤝`);
  const collabScore = collaboration.roleComplement ? 95 : 50;
  console.log(`             ${collabScore}% ${'★'.repeat(Math.floor(collabScore/20))}${'☆'.repeat(5-Math.floor(collabScore/20))}`);
  
  const synergyScore = synergy.score;
  const evidenceScore = Math.round((collaboration.distribution.evidence) * 100);
  const mathScore = Math.round((collaboration.distribution.math) * 100);
  const qualityScore = Math.round((collaboration.distribution.quality) * 100);
  const learningScore = Math.round((collaboration.distribution.learning) * 100);
  
  console.log(`Synergy ⚡                   Evidence 🔬`);
  console.log(`   ${synergyScore}% ${'★'.repeat(Math.floor(synergyScore/20))}${'☆'.repeat(5-Math.floor(synergyScore/20))}       ${evidenceScore}% ${'★'.repeat(Math.floor(evidenceScore/20))}${'☆'.repeat(5-Math.floor(evidenceScore/20))}`);
  console.log(`     Learning 🌱     Quality 🎯`);
  console.log(`       ${learningScore}% ${'★'.repeat(Math.floor(learningScore/20))}${'☆'.repeat(5-Math.floor(learningScore/20))}     ${qualityScore}% ${'★'.repeat(Math.floor(qualityScore/20))}${'☆'.repeat(5-Math.floor(qualityScore/20))}`);
  console.log(`         Math 🧮`);
  console.log(`             ${mathScore}% ${'★'.repeat(Math.floor(mathScore/20))}${'☆'.repeat(5-Math.floor(mathScore/20))}`);
  
  // Recommendations and warnings
  const allRecommendations = [
    ...collaboration.recommendations,
    ...(synergy.gapCount > 0 ? synergy.gaps : []),
    ...(overallScore.score === 100 ? ['⚠️ PERFECTION WARNING: 100% scores often indicate measurement gaps - consider stress testing'] : [])
  ];
  
  if (allRecommendations.length > 0) {
    console.log(`\n💡 **OPTIMIZATION RECOMMENDATIONS**`);
    allRecommendations.forEach((rec, i) => {
      console.log(`   ${i + 1}. ${rec}`);
    });
  } else if (overallScore.score >= 90) {
    console.log(`\n🎯 **ANTIFRAGILE EXCELLENCE ACHIEVED**`);
    console.log('   Your AI team demonstrates exceptional intelligence.');
    console.log('   Consider stress-testing with --stress-test mode to identify edge cases.');
    console.log('   The goal is antifragile systems that improve under pressure.');
  }
  
  // Stress test results summary
  if (stressTest) {
    console.log(`\n🔥 **STRESS TEST SUMMARY**`);
    const vulnerabilities = individual.flatMap(p => 
      p.qualityAnalysis?.score < 80 ? [`${p.name}: Quality vulnerability`] : []
    ).concat(
      individual.flatMap(p => 
        p.mathAnalysis?.sophisticationScore < 70 ? [`${p.name}: Mathematical sophistication risk`] : []
      )
    );
    
    if (vulnerabilities.length === 0) {
      console.log('   ✅ No critical vulnerabilities detected under stress testing');
    } else {
      console.log('   ⚠️ Vulnerabilities detected:');
      vulnerabilities.forEach(vuln => console.log(`      • ${vuln}`));
    }
  }
  
  // Export options
  if (options.json) {
    return JSON.stringify(analysis, null, 2);
  }
  
  return analysis;
}

// Enhanced CLI Interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const options = {
    json: args.includes('--json'),
    directory: args.find(arg => arg.startsWith('--dir='))?.replace('--dir=', '') || '.',
    primary: args.find(arg => arg.startsWith('--primary='))?.replace('--primary=', ''),
    secondary: args.find(arg => arg.startsWith('--secondary='))?.replace('--secondary=', ''),
    stressTest: args.includes('--stress-test')
  };
  
  try {
    let personalities;
    
    if (options.primary && options.secondary) {
      personalities = [
        { path: options.primary, name: 'primary', personality: loadPersonality(options.primary, 'primary') },
        { path: options.secondary, name: 'secondary', personality: loadPersonality(options.secondary, 'secondary') }
      ].filter(p => p.personality);
    } else {
      personalities = discoverPersonalities(options.directory);
    }
    
    if (personalities.length === 0) {
      console.error('❌ No personalities found. Ensure .personality.json files exist in the specified directory.');
      process.exit(1);
    }
    
    console.log(`🔍 **DISCOVERED ${personalities.length} PERSONALITIES FOR REALISTIC ANALYSIS**`);
    personalities.forEach(p => console.log(`   • ${p.name} (${p.personality.identity?.name || 'Unknown'})`));
    
    const analysis = analyzePersonalities(personalities, options);
    const result = displayResults(analysis, options);
    
    if (options.json && typeof result === 'string') {
      console.log('\n📄 **JSON OUTPUT**');
      console.log('=' .repeat(20));
      console.log(result);
    }
    
    // Realistic exit codes based on production readiness
    const exitCode = analysis.overallScore.score >= 85 ? 0 : 1;
    if (!options.json) {
      console.log(`\n🎯 **EXIT CODE: ${exitCode}** (${exitCode === 0 ? 'PRODUCTION READY' : 'NEEDS ENHANCEMENT'})`);
      console.log(`   Threshold: 85+ for production deployment`);
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
  analyzeQualityGatesDeep,
  analyzeMathematicalDepth,
  calculateRealisticScore
};
