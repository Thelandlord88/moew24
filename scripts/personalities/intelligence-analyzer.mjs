#!/usr/bin/env node
/**
 * Personality Intelligence Analyzer
 * Deep analysis and optimization recommendations for human-machine collaboration
 */

import { readFileSync } from 'node:fs';

function analyzePersonalityIntelligence() {
  const daedalus = JSON.parse(readFileSync('./daedalus.personality.json', 'utf8'));
  const hunter = JSON.parse(readFileSync('./hunter.personality.json', 'utf8'));
  
  console.log('🧠 PERSONALITY INTELLIGENCE ANALYSIS');
  console.log('====================================');
  console.log('');
  
  // 1. Ideological Coherence Analysis
  console.log('🎯 1. IDEOLOGICAL COHERENCE ASSESSMENT');
  console.log('--------------------------------------');
  
  const daedalusPrinciples = daedalus.ideology.principles.length;
  const hunterPrinciples = hunter.ideology.principles.length;
  
  console.log(`   Daedalus Principles: ${daedalusPrinciples} (Architectural focus)`);
  console.log(`   Hunter Principles: ${hunterPrinciples} (Quality focus)`);
  
  // Check for complementary roles
  const daedalusRole = daedalus.identity.priority; // "lead"
  const hunterRole = hunter.identity.priority;     // "follow-up"
  
  const roleComplement = daedalusRole === 'lead' && hunterRole === 'follow-up';
  console.log(`   ✓ Role Complementarity: ${roleComplement ? 'OPTIMAL' : 'NEEDS ADJUSTMENT'}`);
  
  // 2. Decision Framework Analysis
  console.log('');
  console.log('🧮 2. DECISION FRAMEWORK SOPHISTICATION');
  console.log('---------------------------------------');
  
  // Daedalus mathematical sophistication
  const hasMathFramework = !!daedalus.decision_policy?.link_scoring?.weights;
  const mathParams = hasMathFramework ? Object.keys(daedalus.decision_policy.link_scoring.weights).length : 0;
  
  console.log(`   Daedalus Mathematical Parameters: ${mathParams}`);
  console.log(`   ✓ Mathematical Decision Making: ${hasMathFramework ? 'ADVANCED' : 'BASIC'}`);
  
  // Hunter quality gate sophistication
  const hunterGates = hunter.decision_policy?.gates ? Object.keys(hunter.decision_policy.gates).length : 0;
  console.log(`   Hunter Quality Gate Categories: ${hunterGates}`);
  console.log(`   ✓ Quality Enforcement: ${hunterGates >= 3 ? 'COMPREHENSIVE' : 'BASIC'}`);
  
  // 3. Learning System Analysis
  console.log('');
  console.log('🌱 3. LEARNING SYSTEM CAPABILITIES');
  console.log('----------------------------------');
  
  const daedalusInputs = Object.keys(daedalus.learning.inputs).length;
  const hunterInputs = Object.keys(hunter.learning.inputs).length;
  
  console.log(`   Daedalus Input Categories: ${daedalusInputs} (geo, runtime, content)`);
  console.log(`   Hunter Input Categories: ${hunterInputs} (signals, product)`);
  
  const hasFeedbackLoops = daedalus.learning.feedback_loops?.length > 0;
  console.log(`   ✓ Feedback Loops: ${hasFeedbackLoops ? 'OPERATIONAL' : 'MISSING'}`);
  
  // 4. Collaboration Protocol Analysis
  console.log('');
  console.log('🤝 4. COLLABORATION INTELLIGENCE');
  console.log('--------------------------------');
  
  const hasCollaboration = !!hunter.collaboration_with_daedalus;
  console.log(`   ✓ Explicit Collaboration: ${hasCollaboration ? 'DEFINED' : 'IMPLICIT'}`);
  
  if (hasCollaboration) {
    const collabAspects = Object.keys(hunter.collaboration_with_daedalus).length;
    console.log(`   Collaboration Aspects: ${collabAspects} (observes, enforces, advises)`);
  }
  
  // 5. Human-Machine Interface Analysis
  console.log('');
  console.log('🔗 5. HUMAN-MACHINE INTERFACE OPTIMIZATION');
  console.log('------------------------------------------');
  
  const hasHumanMachineEthos = daedalus.ideology.principles.some(p => p.includes('Machines and humans co-author'));
  console.log(`   ✓ Dual Interface Philosophy: ${hasHumanMachineEthos ? 'EXPLICIT' : 'IMPLICIT'}`);
  
  const hasCommunicationStyle = !!daedalus.communication_style;
  console.log(`   ✓ Communication Framework: ${hasCommunicationStyle ? 'STRUCTURED' : 'BASIC'}`);
  
  // 6. Evidence-Driven Intelligence
  console.log('');
  console.log('📊 6. EVIDENCE-DRIVEN DECISION MAKING');
  console.log('-------------------------------------');
  
  const daedalusEvidenceFocus = daedalus.ideology.principles.some(p => p.includes('Evidence over assumptions'));
  const hunterEvidenceFocus = hunter.ideology.principles.some(p => p.includes('justified by evidence'));
  
  console.log(`   ✓ Daedalus Evidence Priority: ${daedalusEvidenceFocus ? 'PRIMARY' : 'SECONDARY'}`);
  console.log(`   ✓ Hunter Evidence Discipline: ${hunterEvidenceFocus ? 'ENFORCED' : 'SUGGESTED'}`);
  
  // 7. Recommendations for Improvement
  console.log('');
  console.log('💡 7. OPTIMIZATION RECOMMENDATIONS');
  console.log('-----------------------------------');
  
  const recommendations = [];
  
  if (!hasCollaboration) {
    recommendations.push('Add explicit collaboration framework to Hunter personality');
  }
  
  if (mathParams < 5) {
    recommendations.push('Expand mathematical decision parameters for more nuanced optimization');
  }
  
  if (hunterGates < 4) {
    recommendations.push('Add more quality gate categories (accessibility, security, performance)');
  }
  
  if (!hasCommunicationStyle) {
    recommendations.push('Add structured communication protocols to both personalities');
  }
  
  if (recommendations.length === 0) {
    console.log('   🌟 ASSESSMENT: Personalities are well-optimized for human-machine intelligence');
  } else {
    console.log('   🔧 Suggested improvements:');
    recommendations.forEach((rec, i) => {
      console.log(`      ${i + 1}. ${rec}`);
    });
  }
  
  // 8. Overall Intelligence Score
  console.log('');
  console.log('🏆 8. OVERALL INTELLIGENCE ASSESSMENT');
  console.log('-------------------------------------');
  
  let score = 0;
  score += roleComplement ? 20 : 0;           // Role complementarity
  score += hasMathFramework ? 20 : 0;         // Mathematical framework
  score += hunterGates >= 3 ? 15 : 0;         // Quality gates
  score += hasFeedbackLoops ? 15 : 0;         // Learning capability
  score += hasCollaboration ? 15 : 0;         // Collaboration framework
  score += daedalusEvidenceFocus ? 10 : 0;    // Evidence focus
  score += hunterEvidenceFocus ? 5 : 0;       // Evidence discipline
  
  console.log(`   📊 Intelligence Score: ${score}/100`);
  
  if (score >= 90) console.log('   🌟 Rating: EXCEPTIONAL - Enterprise-ready systematic intelligence');
  else if (score >= 75) console.log('   🎯 Rating: EXCELLENT - Strong collaborative intelligence');
  else if (score >= 60) console.log('   ⚡ Rating: GOOD - Solid foundation with growth potential');
  else console.log('   🔧 Rating: DEVELOPING - Needs optimization for full intelligence');
  
  return { score, recommendations };
}

// CLI execution
if (import.meta.url === `file://${process.argv[1]}`) {
  analyzePersonalityIntelligence();
}

export { analyzePersonalityIntelligence };
