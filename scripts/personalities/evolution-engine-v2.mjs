#!/usr/bin/env node
/**
 * Personality Evolution Engine V2
 * Advanced enhancement system for collaborative AI intelligence
 * Implements "Cognitive Diversity" and "Conflict Detection" features
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

// Advanced enhancement templates based on best practices
const ENHANCEMENT_TEMPLATES = {
  qualityGates: {
    accessibility: {
      "wcag_compliance": ["AA level validation", "semantic HTML enforcement", "keyboard navigation"],
      "screen_reader": "Compatible markup validation",
      "color_contrast": "4.5:1 minimum ratio enforcement"
    },
    security: {
      "xss_prevention": ["innerHTML sanitization", "CSP validation"],
      "secret_detection": "API keys and tokens scanning",
      "dependency_audit": "npm audit integration"
    },
    performance: {
      "bundle_size": "JavaScript size budgets",
      "image_optimization": "Responsive image validation",
      "core_vitals": "LCP, FID, CLS monitoring"
    }
  },
  
  collaborationFramework: {
    "communication_protocol": "Assumptions → Evidence → Decision → Actions → Risks → Next checks",
    "escalation_matrix": {
      "critical_threshold": "Block release for evidence requirements",
      "warning_threshold": "Flag for review",
      "info_threshold": "Log for monitoring"
    },
    "feedback_integration": "Cross-personality learning from decisions"
  },
  
  mathematicalFrameworks: {
    "fairness_metrics": {
      "gini_coefficient": "Distribution inequality measurement",
      "reciprocity_index": "Mutual relationship scoring",
      "cluster_purity": "Geographic relationship coherence"
    },
    "optimization_targets": {
      "multi_objective": ["fairness", "performance", "coverage"],
      "pareto_frontier": "Optimal trade-off identification"
    }
  }
};

function loadPersonality(file) {
  try {
    return JSON.parse(readFileSync(resolve(file), 'utf8'));
  } catch (error) {
    throw new Error(`Failed to load ${file}: ${error.message}`);
  }
}

function analyzeCognitiveDiversity(personalities) {
  console.log('\n🧠 **COGNITIVE DIVERSITY ANALYSIS**');
  console.log('=' .repeat(50));
  
  const diversityMetrics = {
    roleDistribution: {},
    principleTypes: new Set(),
    decisionStyles: new Set(),
    communicationStyles: new Set(),
    diversityScore: 0
  };
  
  personalities.forEach(({name, personality}) => {
    const role = personality.identity?.priority || 'unspecified';
    diversityMetrics.roleDistribution[role] = (diversityMetrics.roleDistribution[role] || 0) + 1;
    
    // Analyze principle types
    const principles = personality.ideology?.principles || [];
    principles.forEach(p => {
      if (p.includes('Evidence') || p.includes('data')) diversityMetrics.principleTypes.add('evidence-driven');
      if (p.includes('Prevention') || p.includes('prevent')) diversityMetrics.principleTypes.add('preventive');
      if (p.includes('Architecture') || p.includes('design')) diversityMetrics.principleTypes.add('architectural');
      if (p.includes('collaborative') || p.includes('co-author')) diversityMetrics.principleTypes.add('collaborative');
    });
    
    // Analyze decision styles
    const hasPolicy = personality.decision_policy && Object.keys(personality.decision_policy).length > 0;
    if (hasPolicy) {
      const policyTypes = Object.keys(personality.decision_policy);
      policyTypes.forEach(type => diversityMetrics.decisionStyles.add(type));
    }
    
    // Analyze communication styles
    const commStyle = personality.communication_style?.tone || [];
    commStyle.forEach(tone => diversityMetrics.communicationStyles.add(tone));
  });
  
  // Calculate diversity score
  const roleVariety = Object.keys(diversityMetrics.roleDistribution).length;
  const principleVariety = diversityMetrics.principleTypes.size;
  const decisionVariety = diversityMetrics.decisionStyles.size;
  const commVariety = diversityMetrics.communicationStyles.size;
  
  diversityMetrics.diversityScore = Math.min(100, (roleVariety * 25) + (principleVariety * 15) + (decisionVariety * 15) + (commVariety * 10));
  
  console.log(`🎭 Role Distribution: ${JSON.stringify(diversityMetrics.roleDistribution)}`);
  console.log(`🎯 Principle Types: ${Array.from(diversityMetrics.principleTypes).join(', ')}`);
  console.log(`⚙️  Decision Styles: ${Array.from(diversityMetrics.decisionStyles).join(', ')}`);
  console.log(`💬 Communication Styles: ${Array.from(diversityMetrics.communicationStyles).join(', ')}`);
  console.log(`📊 Diversity Score: ${diversityMetrics.diversityScore}/100`);
  
  if (diversityMetrics.diversityScore >= 80) {
    console.log('✅ **EXCELLENT COGNITIVE DIVERSITY** - Strong complementary thinking styles');
  } else if (diversityMetrics.diversityScore >= 60) {
    console.log('⚠️ **MODERATE COGNITIVE DIVERSITY** - Consider adding different thinking styles');
  } else {
    console.log('❌ **LIMITED COGNITIVE DIVERSITY** - High risk of groupthink');
  }
  
  return diversityMetrics;
}

function detectConflicts(personalities) {
  console.log('\n⚠️ **CONFLICT DETECTION ANALYSIS**');
  console.log('=' .repeat(50));
  
  const conflicts = [];
  const overlaps = [];
  const contradictions = [];
  
  // Check for role overlaps
  const roleMap = {};
  personalities.forEach(({name, personality}) => {
    const role = personality.identity?.priority;
    if (role) {
      if (roleMap[role]) {
        overlaps.push(`Role conflict: Both ${roleMap[role]} and ${name} have '${role}' priority`);
      } else {
        roleMap[role] = name;
      }
    }
  });
  
  // Check for contradictory principles
  const allPrinciples = personalities.flatMap(({name, personality}) => 
    (personality.ideology?.principles || []).map(p => ({principle: p, owner: name}))
  );
  
  // Look for semantic contradictions
  for (let i = 0; i < allPrinciples.length; i++) {
    for (let j = i + 1; j < allPrinciples.length; j++) {
      const p1 = allPrinciples[i];
      const p2 = allPrinciples[j];
      
      // Simple contradiction detection
      if ((p1.principle.includes('manual') && p2.principle.includes('automated')) ||
          (p1.principle.includes('prevention') && p2.principle.includes('remediation'))) {
        contradictions.push(`Potential contradiction: ${p1.owner} (${p1.principle}) vs ${p2.owner} (${p2.principle})`);
      }
    }
  }
  
  // Check for constraint conflicts
  personalities.forEach(({name: name1, personality: p1}) => {
    personalities.forEach(({name: name2, personality: p2}) => {
      if (name1 !== name2) {
        const constraints1 = p1.constraints || [];
        const constraints2 = p2.constraints || [];
        
        // Look for conflicting constraints
        constraints1.forEach(c1 => {
          constraints2.forEach(c2 => {
            if (c1.toLowerCase().includes('never') && c2.toLowerCase().includes('always')) {
              conflicts.push(`Constraint conflict: ${name1} says "${c1}" but ${name2} says "${c2}"`);
            }
          });
        });
      }
    });
  });
  
  const totalConflicts = overlaps.length + contradictions.length + conflicts.length;
  
  if (totalConflicts === 0) {
    console.log('✅ **NO CONFLICTS DETECTED** - Personalities work harmoniously');
  } else {
    console.log(`⚠️ **${totalConflicts} POTENTIAL CONFLICTS DETECTED**`);
    
    if (overlaps.length > 0) {
      console.log('\n🔄 Role Overlaps:');
      overlaps.forEach(overlap => console.log(`   • ${overlap}`));
    }
    
    if (contradictions.length > 0) {
      console.log('\n💥 Contradictory Principles:');
      contradictions.forEach(contradiction => console.log(`   • ${contradiction}`));
    }
    
    if (conflicts.length > 0) {
      console.log('\n⚔️ Constraint Conflicts:');
      conflicts.forEach(conflict => console.log(`   • ${conflict}`));
    }
  }
  
  return {
    totalConflicts,
    overlaps,
    contradictions,
    conflicts
  };
}

function enhancePersonality(personalityFile, enhancements) {
  console.log(`\n🚀 **ENHANCING ${personalityFile.toUpperCase()}**`);
  console.log('=' .repeat(50));
  
  const personality = loadPersonality(personalityFile);
  const originalVersion = personality.version || '1.0.0';
  
  let enhanced = false;
  const changes = [];
  
  // Add missing quality gates
  if (enhancements.includes('quality-gates') && personality.identity?.name?.toLowerCase() === 'hunter') {
    if (!personality.decision_policy?.gates?.accessibility) {
      personality.decision_policy = personality.decision_policy || {};
      personality.decision_policy.gates = personality.decision_policy.gates || {};
      
      Object.assign(personality.decision_policy.gates, ENHANCEMENT_TEMPLATES.qualityGates);
      changes.push('Added comprehensive quality gates (accessibility, security, performance)');
      enhanced = true;
    }
  }
  
  // Add collaboration framework
  if (enhancements.includes('collaboration') && !personality.collaboration_framework) {
    personality.collaboration_framework = ENHANCEMENT_TEMPLATES.collaborationFramework;
    changes.push('Added explicit collaboration framework');
    enhanced = true;
  }
  
  // Add mathematical frameworks
  if (enhancements.includes('math-frameworks') && personality.identity?.name?.toLowerCase() === 'daedalus') {
    if (!personality.mathematical_frameworks) {
      personality.mathematical_frameworks = ENHANCEMENT_TEMPLATES.mathematicalFrameworks;
      changes.push('Added advanced mathematical frameworks');
      enhanced = true;
    }
  }
  
  // Increment version if enhanced
  if (enhanced) {
    const [major, minor, patch] = originalVersion.split('.').map(Number);
    personality.version = `${major}.${minor}.${patch + 1}`;
    changes.push(`Version updated: ${originalVersion} → ${personality.version}`);
  }
  
  if (enhanced) {
    // Backup original
    const backupFile = personalityFile.replace('.json', '.backup.json');
    writeFileSync(backupFile, JSON.stringify(loadPersonality(personalityFile), null, 2));
    
    // Write enhanced version
    writeFileSync(personalityFile, JSON.stringify(personality, null, 2));
    
    console.log('✅ **ENHANCEMENT COMPLETED**');
    changes.forEach(change => console.log(`   • ${change}`));
    console.log(`📄 Backup saved: ${backupFile}`);
  } else {
    console.log('ℹ️ No enhancements needed - personality already optimal');
  }
  
  return { enhanced, changes, newVersion: personality.version };
}

function generateEvolutionReport(personalities) {
  const timestamp = new Date().toISOString();
  const report = {
    timestamp,
    analysis: {
      personalities: personalities.length,
      cognitive_diversity: analyzeCognitiveDiversity(personalities),
      conflict_detection: detectConflicts(personalities)
    },
    recommendations: [
      "Continue monitoring personality evolution",
      "Consider adding specialized personalities for new domains",
      "Implement automated conflict resolution protocols",
      "Add personality versioning and compatibility checks"
    ]
  };
  
  const reportFile = `personality-evolution-report-${timestamp.split('T')[0]}.json`;
  writeFileSync(reportFile, JSON.stringify(report, null, 2));
  
  console.log(`\n📊 **EVOLUTION REPORT GENERATED**`);
  console.log(`   File: ${reportFile}`);
  console.log(`   Timestamp: ${timestamp}`);
  
  return report;
}

// CLI Interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const [,, command, ...args] = process.argv;
  
  try {
    const personalities = [
      { name: 'daedalus', personality: loadPersonality('./daedalus.personality.json') },
      { name: 'hunter', personality: loadPersonality('./hunter.personality.json') }
    ];
    
    switch (command) {
      case 'diversity':
        analyzeCognitiveDiversity(personalities);
        break;
        
      case 'conflicts':
        detectConflicts(personalities);
        break;
        
      case 'enhance':
        const targetPersonality = args[0] || 'hunter.personality.json';
        const enhancements = args.slice(1).length ? args.slice(1) : ['quality-gates', 'collaboration', 'math-frameworks'];
        enhancePersonality(targetPersonality, enhancements);
        break;
        
      case 'report':
        generateEvolutionReport(personalities);
        break;
        
      case 'full-analysis':
        console.log('🧠 **COMPREHENSIVE PERSONALITY EVOLUTION ANALYSIS**');
        console.log('=' .repeat(60));
        analyzeCognitiveDiversity(personalities);
        detectConflicts(personalities);
        generateEvolutionReport(personalities);
        break;
        
      default:
        console.log(`
🧠 Personality Evolution Engine V2 - Advanced Enhancement System

Usage:
  node scripts/personalities/evolution-engine-v2.mjs <command> [options]

Commands:
  diversity                    - Analyze cognitive diversity
  conflicts                   - Detect personality conflicts
  enhance <file> [types...]   - Enhance personality with new capabilities
  report                      - Generate evolution report
  full-analysis              - Complete analysis with all metrics

Enhancement Types:
  quality-gates              - Add comprehensive quality gates
  collaboration              - Add explicit collaboration frameworks  
  math-frameworks           - Add advanced mathematical frameworks

Examples:
  node scripts/personalities/evolution-engine-v2.mjs diversity
  node scripts/personalities/evolution-engine-v2.mjs enhance hunter.personality.json quality-gates
  node scripts/personalities/evolution-engine-v2.mjs full-analysis
        `);
    }
  } catch (error) {
    console.error(`💥 Error: ${error.message}`);
    process.exit(1);
  }
}

export { analyzeCognitiveDiversity, detectConflicts, enhancePersonality, generateEvolutionReport };
