#!/usr/bin/env node
/**
 * Personality Enhancement: Hunter Quality Gates Expansion
 * Adds accessibility, security, and performance gates for complete coverage
 */

import { readFileSync, writeFileSync } from 'node:fs';

function enhanceHunterQualityGates() {
  console.log('🔧 ENHANCING HUNTER QUALITY GATES');
  console.log('=================================');
  
  const hunter = JSON.parse(readFileSync('./hunter.personality.json', 'utf8'));
  
  console.log('📊 Current Gates:', Object.keys(hunter.decision_policy.gates));
  
  // Add enhanced quality gates
  hunter.decision_policy.gates.accessibility = [
    'WCAG 2.1 AA compliance',
    'alt text present on images',
    'semantic HTML structure',
    'keyboard navigation functional'
  ];
  
  hunter.decision_policy.gates.security = [
    'no hardcoded secrets',
    'XSS vulnerability scan clean',
    'dependency vulnerability scan clean',
    'HTTPS enforcement verified'
  ];
  
  hunter.decision_policy.gates.performance = [
    'Lighthouse performance score > 85',
    'Core Web Vitals within targets',
    'bundle size within budget',
    'image optimization verified'
  ];
  
  // Add monitoring capabilities
  hunter.learning.inputs.monitoring = [
    'Core Web Vitals reports',
    'accessibility audit results', 
    'security scan outputs',
    'performance budgets'
  ];
  
  // Enhanced success metrics
  hunter.success_metrics.quality_coverage = 'All gate categories (build, perf, seo, accessibility, security) operational';
  hunter.success_metrics.human_machine_optimization = 'Both human usability and machine readability verified';
  
  // Write enhanced personality back
  writeFileSync('./hunter.personality.json', JSON.stringify(hunter, null, 2));
  
  console.log('✅ Enhanced Gates:', Object.keys(hunter.decision_policy.gates));
  console.log('🌟 Hunter personality enhanced for complete quality coverage!');
  
  return hunter;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  enhanceHunterQualityGates();
}

export { enhanceHunterQualityGates };
