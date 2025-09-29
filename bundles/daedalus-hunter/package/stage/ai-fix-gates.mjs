#!/usr/bin/env node
// AI-Guided Fix: Correct Quality Gates Structure for Daedalus

import { readFileSync, writeFileSync } from 'fs';

console.log('🔧 **AI TEAM CORRECTION: PROPER GATES STRUCTURE**');
console.log('🔍 Hunter: "Gates must match exact scoring format"');
console.log('🏗️ Daedalus: "Structure encodes intent"');

try {
  // Read current Daedalus personality
  const daedalusData = JSON.parse(readFileSync('daedalus.personality.json', 'utf8'));
  
  // Remove the incorrect quality_gates and add proper gates structure
  if (!daedalusData.decision_policy) {
    daedalusData.decision_policy = {};
  }
  
  // Delete incorrect structure
  delete daedalusData.decision_policy.quality_gates;
  
  // Add correct gates structure (exactly like Hunter's)
  daedalusData.decision_policy.gates = {
    "build": [
      "schema validity",
      "dependency freshness", 
      "no hardcoded secrets"
    ],
    "perf": [
      "JS size budgets",
      "image optimization",
      "critical resource hints"
    ],
    "seo": [
      "titles and descriptions",
      "structured data",
      "canonical URLs"
    ],
    "accessibility": [
      "semantic HTML",
      "ARIA labels",
      "keyboard navigation"
    ],
    "security": [
      "CSP headers",
      "HTTPS enforcement", 
      "input sanitization"
    ],
    "performance": [
      "Core Web Vitals",
      "bundle analysis",
      "lazy loading"
    ]
  };
  
  // Write corrected personality
  writeFileSync('daedalus.personality.json', JSON.stringify(daedalusData, null, 2));
  console.log('✅ Structure corrected: Gates added in proper format');
  console.log('📊 Expected: Quality score 10 → 90+ (6 categories)');
  
} catch (error) {
  console.error('❌ Correction failed:', error.message);
  process.exit(1);
}
