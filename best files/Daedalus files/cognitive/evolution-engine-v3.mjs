#!/usr/bin/env node
/**
 * Personality Evolution Engine V3 - Production Grade
 * Enterprise-ready AI organizational psychology system
 * 
 * IMPROVEMENTS BASED ON CRITICAL FEEDBACK:
 * - Fixed path resolution bug with proper __dirname handling
 * - Added --dry-run preview mode for safe operations
 * - Enhanced semantic conflict detection with keyword pairs
 * - Post-enhancement validation for team compatibility
 * - Dynamic personality path configuration
 * - Comprehensive error handling and validation
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

// Fix path resolution bug - resolve from script location, not cwd
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Enhanced semantic analysis with keyword pairs
const CONTRADICTION_PAIRS = [
  { 
    a: ['manual', 'hand-edit', 'hand-coded'], 
    b: ['automated', 'auto', 'systematic', 'generated'],
    severity: 'high'
  },
  { 
    a: ['prevention', 'prevent', 'avoid'], 
    b: ['remediation', 'fix', 'patch', 'repair'],
    severity: 'medium'
  },
  { 
    a: ['strict', 'rigid', 'never'], 
    b: ['flexible', 'adaptive', 'sometimes'],
    severity: 'medium'
  },
  { 
    a: ['centralized', 'single'], 
    b: ['distributed', 'multiple', 'duplicate'],
    severity: 'low'
  }
];

// Enhanced string prototype for semantic matching
String.prototype.includesAny = function(words) {
  return words.some(w => this.toLowerCase().includes(w.toLowerCase()));
};

// Enhanced enhancement templates with documentation
const ENHANCEMENT_TEMPLATES = {
  qualityGates: {
    description: "Comprehensive quality assurance gates for enterprise deployment",
    accessibility: {
      "wcag_compliance": ["AA level validation", "semantic HTML enforcement", "keyboard navigation"],
      "screen_reader": "Compatible markup validation", 
      "color_contrast": "4.5:1 minimum ratio enforcement"
    },
    security: {
      "xss_prevention": ["innerHTML sanitization", "CSP validation"],
      "secret_detection": "API keys and tokens scanning",
      "dependency_audit": "npm audit integration",
      "https_enforcement": "Secure protocol validation"
    },
    performance: {
      "bundle_size": "JavaScript size budgets",
      "image_optimization": "Responsive image validation", 
      "core_vitals": "LCP, FID, CLS monitoring",
      "lighthouse_score": "Performance threshold enforcement"
    }
  },
  
  collaborationFramework: {
    description: "Explicit collaboration protocols for multi-agent coordination",
    "communication_protocol": "Assumptions → Evidence → Decision → Actions → Risks → Next checks",
    "escalation_matrix": {
      "critical_threshold": "Block release for evidence requirements",
      "warning_threshold": "Flag for review with stakeholder notification",
      "info_threshold": "Log for monitoring and trend analysis"
    },
    "feedback_integration": "Cross-personality learning from collaborative decisions",
    "conflict_resolution": "Automated mediation protocols for disagreement handling"
  },
  
  mathematicalFrameworks: {
    description: "Advanced mathematical decision-making and optimization capabilities",
    "fairness_metrics": {
      "gini_coefficient": "Distribution inequality measurement with threshold alerts",
      "reciprocity_index": "Mutual relationship scoring with balance optimization",
      "cluster_purity": "Geographic relationship coherence measurement"
    },
    "optimization_targets": {
      "multi_objective": ["fairness", "performance", "coverage", "accessibility"],
      "pareto_frontier": "Optimal trade-off identification with constraint handling",
      "policy_sweeper": "Automated A/B testing for configuration optimization"
    }
  }
};

function loadPersonality(file, basePath = '.') {
  try {
    // Fix path resolution - use script directory if relative path
    const fullPath = file.startsWith('/') ? file : resolve(basePath, file);
    
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
    
    // Validate identity structure
    if (!personality.identity.name) {
      throw new Error('Missing identity.name field');
    }
    
    return personality;
  } catch (error) {
    console.error(`❌ Failed to load personality from ${file}: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') process.exit(1);
    return null;
  }
}

function analyzeCognitiveDiversity(personalities, options = {}) {
  if (!options.quiet) {
    console.log('\n🧠 **COGNITIVE DIVERSITY ANALYSIS**');
    console.log('=' .repeat(50));
  }
  
  const diversityMetrics = {
    roleDistribution: {},
    principleTypes: new Set(),
    decisionStyles: new Set(), 
    communicationStyles: new Set(),
    diversityScore: 0,
    recommendations: []
  };
  
  personalities.forEach(({name, personality}) => {
    const role = personality.identity?.priority || 'unspecified';
    diversityMetrics.roleDistribution[role] = (diversityMetrics.roleDistribution[role] || 0) + 1;
    
    // Enhanced principle analysis
    const principles = personality.ideology?.principles || [];
    principles.forEach(p => {
      if (p.includesAny(['evidence', 'data', 'metrics', 'proof'])) {
        diversityMetrics.principleTypes.add('evidence-driven');
      }
      if (p.includesAny(['prevent', 'guard', 'protect'])) {
        diversityMetrics.principleTypes.add('preventive');
      }
      if (p.includesAny(['architecture', 'design', 'structure'])) {
        diversityMetrics.principleTypes.add('architectural');
      }
      if (p.includesAny(['collaborative', 'co-author', 'partnership'])) {
        diversityMetrics.principleTypes.add('collaborative');
      }
    });
    
    // Decision style analysis
    const hasPolicy = personality.decision_policy && Object.keys(personality.decision_policy).length > 0;
    if (hasPolicy) {
      const policyTypes = Object.keys(personality.decision_policy);
      policyTypes.forEach(type => diversityMetrics.decisionStyles.add(type));
    }
    
    // Communication style analysis
    const commStyle = personality.communication_style?.tone || [];
    commStyle.forEach(tone => diversityMetrics.communicationStyles.add(tone));
  });
  
  // Enhanced diversity scoring
  const roleVariety = Object.keys(diversityMetrics.roleDistribution).length;
  const principleVariety = diversityMetrics.principleTypes.size;
  const decisionVariety = diversityMetrics.decisionStyles.size;
  const commVariety = diversityMetrics.communicationStyles.size;
  
  diversityMetrics.diversityScore = Math.min(100, 
    (roleVariety * 25) + (principleVariety * 15) + (decisionVariety * 15) + (commVariety * 10)
  );
  
  // Generate recommendations based on gaps
  if (roleVariety < 2) {
    diversityMetrics.recommendations.push('Add personalities with different priority roles (lead, follow-up, advisor)');
  }
  if (principleVariety < 3) {
    diversityMetrics.recommendations.push('Expand principle diversity with different thinking styles');
  }
  if (decisionVariety < 2) {
    diversityMetrics.recommendations.push('Add varied decision-making frameworks');
  }
  
  if (!options.quiet) {
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
    
    if (diversityMetrics.recommendations.length > 0) {
      console.log('\n💡 Diversity Recommendations:');
      diversityMetrics.recommendations.forEach(rec => console.log(`   • ${rec}`));
    }
  }
  
  return diversityMetrics;
}

function detectConflictsEnhanced(personalities, options = {}) {
  if (!options.quiet) {
    console.log('\n⚠️ **ENHANCED CONFLICT DETECTION ANALYSIS**');
    console.log('=' .repeat(50));
  }
  
  const conflicts = [];
  const overlaps = [];
  const contradictions = [];
  const warnings = [];
  
  // Role overlap detection
  const roleMap = {};
  personalities.forEach(({name, personality}) => {
    const role = personality.identity?.priority;
    if (role) {
      if (roleMap[role]) {
        overlaps.push({
          type: 'role_overlap',
          severity: 'high',
          message: `Role conflict: Both ${roleMap[role]} and ${name} have '${role}' priority`,
          suggestion: `Consider changing ${name}'s priority to 'advisor' or 'specialist'`
        });
      } else {
        roleMap[role] = name;
      }
    }
  });
  
  // Enhanced semantic contradiction detection
  const allPrinciples = personalities.flatMap(({name, personality}) => 
    (personality.ideology?.principles || []).map(p => ({principle: p, owner: name}))
  );
  
  for (let i = 0; i < allPrinciples.length; i++) {
    for (let j = i + 1; j < allPrinciples.length; j++) {
      const p1 = allPrinciples[i];
      const p2 = allPrinciples[j];
      
      // Check against enhanced contradiction pairs
      CONTRADICTION_PAIRS.forEach(pair => {
        if ((p1.principle.includesAny(pair.a) && p2.principle.includesAny(pair.b)) ||
            (p2.principle.includesAny(pair.a) && p1.principle.includesAny(pair.b))) {
          
          const conflict = {
            type: 'principle_contradiction',
            severity: pair.severity,
            message: `${pair.severity.toUpperCase()} contradiction: ${p1.owner} ("${p1.principle}") vs ${p2.owner} ("${p2.principle}")`,
            suggestion: generateResolutionSuggestion(p1, p2, pair)
          };
          
          if (pair.severity === 'high') {
            contradictions.push(conflict);
          } else {
            warnings.push(conflict);
          }
        }
      });
    }
  }
  
  // Constraint conflict detection
  personalities.forEach(({name: name1, personality: p1}) => {
    personalities.forEach(({name: name2, personality: p2}) => {
      if (name1 !== name2) {
        const constraints1 = p1.constraints || [];
        const constraints2 = p2.constraints || [];
        
        constraints1.forEach(c1 => {
          constraints2.forEach(c2 => {
            if ((c1.toLowerCase().includes('never') && c2.toLowerCase().includes('always')) ||
                (c1.toLowerCase().includes('must not') && c2.toLowerCase().includes('must'))) {
              conflicts.push({
                type: 'constraint_conflict',
                severity: 'high',
                message: `Constraint conflict: ${name1} ("${c1}") vs ${name2} ("${c2}")`,
                suggestion: `Align constraints or add conditional logic to resolve conflict`
              });
            }
          });
        });
      }
    });
  });
  
  const totalConflicts = overlaps.length + contradictions.length + conflicts.length;
  const totalWarnings = warnings.length;
  
  if (!options.quiet) {
    if (totalConflicts === 0 && totalWarnings === 0) {
      console.log('✅ **NO CONFLICTS OR WARNINGS DETECTED** - Personalities work harmoniously');
    } else {
      console.log(`⚠️ **${totalConflicts} CONFLICTS, ${totalWarnings} WARNINGS DETECTED**`);
      
      if (overlaps.length > 0) {
        console.log('\n🔄 Role Overlaps:');
        overlaps.forEach(overlap => {
          console.log(`   • ${overlap.message}`);
          console.log(`     💡 Suggestion: ${overlap.suggestion}`);
        });
      }
      
      if (contradictions.length > 0) {
        console.log('\n💥 Principle Contradictions:');
        contradictions.forEach(contradiction => {
          console.log(`   • ${contradiction.message}`);
          console.log(`     💡 Suggestion: ${contradiction.suggestion}`);
        });
      }
      
      if (conflicts.length > 0) {
        console.log('\n⚔️ Constraint Conflicts:');
        conflicts.forEach(conflict => {
          console.log(`   • ${conflict.message}`);
          console.log(`     💡 Suggestion: ${conflict.suggestion}`);
        });
      }
      
      if (warnings.length > 0) {
        console.log('\n⚠️ Warnings (Low-Medium Severity):');
        warnings.forEach(warning => {
          console.log(`   • ${warning.message}`);
          console.log(`     💡 Suggestion: ${warning.suggestion}`);
        });
      }
    }
  }
  
  return {
    totalConflicts,
    totalWarnings,
    overlaps,
    contradictions,
    conflicts,
    warnings,
    overallHealth: totalConflicts === 0 ? 'excellent' : totalConflicts <= 2 ? 'good' : 'needs-attention'
  };
}

function generateResolutionSuggestion(p1, p2, pair) {
  const suggestions = {
    'manual-automated': `Consider defining clear boundaries: "${p1.owner}" handles strategic decisions, "${p2.owner}" handles operational automation`,
    'prevention-remediation': `Align on "Prevention first, remediation as backup" - both personalities can coexist with clear priorities`,
    'strict-flexible': `Define contexts: "${p1.owner}" enforces strict rules for critical areas, "${p2.owner}" allows flexibility for non-critical decisions`
  };
  
  const key = pair.a[0] + '-' + pair.b[0];
  return suggestions[key] || `Consider clarifying the context where each approach applies`;
}

function enhancePersonalityV3(personalityFile, enhancements, options = {}) {
  const isDryRun = options.dryRun || false;
  const basePath = options.basePath || __dirname;
  
  console.log(`\n🚀 **ENHANCING ${basename(personalityFile).toUpperCase()}**`);
  console.log('=' .repeat(50));
  
  if (isDryRun) {
    console.log('📝 **DRY RUN MODE** - No files will be modified');
  }
  
  const personality = loadPersonality(personalityFile, basePath);
  if (!personality) return { enhanced: false, error: 'Failed to load personality' };
  
  const originalVersion = personality.version || '1.0.0';
  const originalPersonality = JSON.parse(JSON.stringify(personality)); // Deep clone for comparison
  
  let enhanced = false;
  const changes = [];
  const plannedEnhancements = [];
  
  // Preview all planned changes first
  enhancements.forEach(enhancement => {
    switch (enhancement) {
      case 'quality-gates':
        if (personality.identity?.name?.toLowerCase() === 'hunter') {
          if (!personality.decision_policy?.gates?.accessibility) {
            plannedEnhancements.push({
              type: enhancement,
              description: 'Add comprehensive quality gates (accessibility, security, performance)',
              template: ENHANCEMENT_TEMPLATES.qualityGates
            });
          }
        }
        break;
        
      case 'collaboration':
        if (!personality.collaboration_framework) {
          plannedEnhancements.push({
            type: enhancement,
            description: 'Add explicit collaboration framework',
            template: ENHANCEMENT_TEMPLATES.collaborationFramework
          });
        }
        break;
        
      case 'math-frameworks':
        if (personality.identity?.name?.toLowerCase() === 'daedalus') {
          if (!personality.mathematical_frameworks) {
            plannedEnhancements.push({
              type: enhancement,
              description: 'Add advanced mathematical frameworks',
              template: ENHANCEMENT_TEMPLATES.mathematicalFrameworks
            });
          }
        }
        break;
    }
  });
  
  if (plannedEnhancements.length === 0) {
    console.log('ℹ️ No enhancements needed - personality already optimal');
    return { enhanced: false, changes: [], reason: 'Already optimal' };
  }
  
  // Show planned changes
  console.log('📋 **PLANNED ENHANCEMENTS:**');
  plannedEnhancements.forEach((plan, i) => {
    console.log(`   ${i + 1}. ${plan.description}`);
    console.log(`      Template: ${plan.template.description || 'Standard enhancement'}`);
  });
  
  if (isDryRun) {
    console.log('\n📝 **DRY RUN COMPLETE** - Changes would be applied in live mode');
    return { enhanced: false, changes: plannedEnhancements.map(p => p.description), dryRun: true };
  }
  
  // Apply enhancements
  plannedEnhancements.forEach(plan => {
    switch (plan.type) {
      case 'quality-gates':
        personality.decision_policy = personality.decision_policy || {};
        personality.decision_policy.gates = personality.decision_policy.gates || {};
        Object.assign(personality.decision_policy.gates, plan.template);
        changes.push('Added comprehensive quality gates');
        enhanced = true;
        break;
        
      case 'collaboration':
        personality.collaboration_framework = plan.template;
        changes.push('Added explicit collaboration framework');
        enhanced = true;
        break;
        
      case 'math-frameworks':
        personality.mathematical_frameworks = plan.template;
        changes.push('Added advanced mathematical frameworks');
        enhanced = true;
        break;
    }
  });
  
  // Version increment
  if (enhanced) {
    const [major, minor, patch] = originalVersion.split('.').map(Number);
    personality.version = `${major}.${minor}.${patch + 1}`;
    changes.push(`Version updated: ${originalVersion} → ${personality.version}`);
    
    // Add enhancement timestamp
    personality._lastEnhanced = new Date().toISOString();
    personality._enhancementHistory = personality._enhancementHistory || [];
    personality._enhancementHistory.push({
      timestamp: personality._lastEnhanced,
      version: personality.version,
      enhancements: changes,
      tool: 'evolution-engine-v3'
    });
  }
  
  if (enhanced) {
    // Create backup
    const backupFile = personalityFile.replace('.json', '.backup.json');
    writeFileSync(backupFile, JSON.stringify(originalPersonality, null, 2));
    
    // Write enhanced version
    writeFileSync(personalityFile, JSON.stringify(personality, null, 2));
    
    console.log('\n✅ **ENHANCEMENT COMPLETED**');
    changes.forEach(change => console.log(`   • ${change}`));
    console.log(`📄 Backup saved: ${backupFile}`);
    
    // Post-enhancement validation
    if (options.validate !== false) {
      console.log('\n🔍 **POST-ENHANCEMENT VALIDATION**');
      const validationResults = validateEnhancedPersonality(personality, originalPersonality);
      if (validationResults.issues.length > 0) {
        console.log('⚠️ Validation warnings:');
        validationResults.issues.forEach(issue => console.log(`   • ${issue}`));
      } else {
        console.log('✅ Enhanced personality validates successfully');
      }
    }
  }
  
  return { 
    enhanced, 
    changes, 
    newVersion: personality.version,
    backupFile: enhanced ? personalityFile.replace('.json', '.backup.json') : null
  };
}

function validateEnhancedPersonality(enhanced, original) {
  const issues = [];
  
  // Check for structural integrity
  const requiredFields = ['version', 'identity', 'ideology'];
  requiredFields.forEach(field => {
    if (!enhanced[field]) {
      issues.push(`Missing required field after enhancement: ${field}`);
    }
  });
  
  // Check version progression
  const origVersion = original.version || '1.0.0';
  const newVersion = enhanced.version;
  
  if (newVersion <= origVersion) {
    issues.push(`Version did not increment properly: ${origVersion} → ${newVersion}`);
  }
  
  // Check that core identity wasn't changed
  if (enhanced.identity?.name !== original.identity?.name) {
    issues.push('Core personality identity changed unexpectedly');
  }
  
  return { issues };
}

// Enhanced CLI with dry-run support and dynamic paths
if (import.meta.url === `file://${process.argv[1]}`) {
  const [,, command, ...args] = process.argv;
  
  // Parse options
  const options = {
    dryRun: args.includes('--dry-run'),
    quiet: args.includes('--quiet'),
    basePath: args.find(arg => arg.startsWith('--path='))?.replace('--path=', '') || __dirname,
    validate: !args.includes('--no-validate')
  };
  
  // Remove flags from args
  const cleanArgs = args.filter(arg => 
    !arg.startsWith('--') && arg !== '--dry-run' && arg !== '--quiet'
  );
  
  try {
    // Dynamic personality loading
    let personalities;
    
    const daedalusPath = resolve(options.basePath, 'daedalus.personality.json');
    const hunterPath = resolve(options.basePath, 'hunter.personality.json');
    
    if (existsSync(daedalusPath) && existsSync(hunterPath)) {
      personalities = [
        { name: 'daedalus', personality: loadPersonality(daedalusPath, options.basePath) },
        { name: 'hunter', personality: loadPersonality(hunterPath, options.basePath) }
      ].filter(p => p.personality);
    } else {
      console.error('❌ Default personalities not found. Use --path= to specify location.');
      process.exit(1);
    }
    
    switch (command) {
      case 'diversity':
        analyzeCognitiveDiversity(personalities, options);
        break;
        
      case 'conflicts':
        detectConflictsEnhanced(personalities, options);
        break;
        
      case 'enhance':
        const targetPersonality = cleanArgs[0] || 'hunter.personality.json';
        const enhancements = cleanArgs.slice(1).length ? cleanArgs.slice(1) : ['quality-gates', 'collaboration', 'math-frameworks'];
        
        const result = enhancePersonalityV3(targetPersonality, enhancements, options);
        
        if (options.validate && result.enhanced) {
          // Re-run conflict detection after enhancement
          console.log('\n🔄 **RE-ANALYZING TEAM AFTER ENHANCEMENT**');
          const updatedPersonalities = [
            { name: 'daedalus', personality: loadPersonality(daedalusPath, options.basePath) },
            { name: 'hunter', personality: loadPersonality(hunterPath, options.basePath) }
          ].filter(p => p.personality);
          
          const postConflicts = detectConflictsEnhanced(updatedPersonalities, { quiet: false });
          const postDiversity = analyzeCognitiveDiversity(updatedPersonalities, { quiet: false });
          
          console.log(`\n📊 **ENHANCEMENT IMPACT**`);
          console.log(`   Cognitive Diversity: ${postDiversity.diversityScore}/100`);
          console.log(`   Team Health: ${postConflicts.overallHealth}`);
        }
        break;
        
      case 'health-check':
        console.log('🏥 **COMPREHENSIVE PERSONALITY HEALTH CHECK**');
        console.log('=' .repeat(60));
        
        const diversity = analyzeCognitiveDiversity(personalities, options);
        const conflicts = detectConflictsEnhanced(personalities, options);
        
        const overallHealth = conflicts.totalConflicts === 0 && diversity.diversityScore >= 80 ? 'excellent' :
                             conflicts.totalConflicts <= 2 && diversity.diversityScore >= 60 ? 'good' : 'needs-attention';
        
        console.log(`\n🎯 **OVERALL HEALTH: ${overallHealth.toUpperCase()}**`);
        console.log(`   Cognitive Diversity: ${diversity.diversityScore}/100`);
        console.log(`   Conflicts: ${conflicts.totalConflicts} critical, ${conflicts.totalWarnings} warnings`);
        break;
        
      case 'report':
        const timestamp = new Date().toISOString();
        const report = {
          timestamp,
          version: '3.0.0',
          analysis: {
            personalities: personalities.length,
            cognitive_diversity: analyzeCognitiveDiversity(personalities, { quiet: true }),
            conflict_detection: detectConflictsEnhanced(personalities, { quiet: true })
          },
          recommendations: [
            "Continue monitoring personality evolution with V3 tools",
            "Consider adding specialized personalities for emerging domains",
            "Implement automated conflict resolution protocols",
            "Use --dry-run mode before applying enhancements in production"
          ]
        };
        
        const reportFile = `personality-evolution-report-v3-${timestamp.split('T')[0]}.json`;
        writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        console.log(`📊 **V3 EVOLUTION REPORT GENERATED**`);
        console.log(`   File: ${reportFile}`);
        console.log(`   Enhanced with conflict resolution and dry-run capabilities`);
        break;
        
      default:
        console.log(`
🧠 **Personality Evolution Engine V3 - Production Grade**

ENTERPRISE-READY AI ORGANIZATIONAL PSYCHOLOGY SYSTEM

Usage:
  node evolution-engine-v3.mjs <command> [options] [args]

Commands:
  diversity                    - Analyze cognitive diversity with recommendations
  conflicts                   - Enhanced conflict detection with resolution suggestions
  enhance <file> [types...]   - Enhance personality with dry-run support
  health-check                - Comprehensive personality team health assessment
  report                      - Generate detailed evolution report

Enhancement Types:
  quality-gates              - Add comprehensive quality gates (accessibility, security, performance)
  collaboration              - Add explicit collaboration frameworks with conflict resolution
  math-frameworks           - Add advanced mathematical frameworks with optimization

Options:
  --dry-run                  - Preview changes without applying (RECOMMENDED for production)
  --quiet                    - Suppress detailed output
  --path=<dir>              - Specify personality file directory (default: script location)
  --no-validate             - Skip post-enhancement validation

Examples:
  node evolution-engine-v3.mjs health-check
  node evolution-engine-v3.mjs enhance hunter.personality.json quality-gates --dry-run
  node evolution-engine-v3.mjs conflicts --quiet
  node evolution-engine-v3.mjs enhance /custom/path/daedalus.personality.json math-frameworks

Production Usage:
  1. Always use --dry-run first: node evolution-engine-v3.mjs enhance file.json --dry-run
  2. Review planned changes carefully
  3. Apply enhancements: node evolution-engine-v3.mjs enhance file.json
  4. Run health-check to validate: node evolution-engine-v3.mjs health-check

CRITICAL IMPROVEMENTS IN V3:
✅ Fixed path resolution bug
✅ Added --dry-run preview mode
✅ Enhanced semantic conflict detection with resolution suggestions
✅ Post-enhancement validation and team compatibility checking
✅ Dynamic personality path configuration
✅ Comprehensive error handling and production safety
        `);
    }
  } catch (error) {
    console.error(`💥 V3 Error: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') process.exit(1);
  }
}

export { 
  analyzeCognitiveDiversity, 
  detectConflictsEnhanced as detectConflicts, 
  enhancePersonalityV3 as enhancePersonality,
  validateEnhancedPersonality,
  loadPersonality,
  ENHANCEMENT_TEMPLATES,
  CONTRADICTION_PAIRS
};
