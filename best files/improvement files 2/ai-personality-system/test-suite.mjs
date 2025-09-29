#!/usr/bin/env node
/**
 * Personality Evolution Engine V3 - Test Suite
 * Comprehensive testing for production-grade AI personality system
 */

import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Import our V3 system for testing
import { 
  analyzeCognitiveDiversity, 
  detectConflicts, 
  enhancePersonality,
  validateEnhancedPersonality,
  loadPersonality,
  ENHANCEMENT_TEMPLATES
} from './evolution-engine-v3.mjs';

class TestRunner {
  constructor() {
    this.tests = [];
    this.passed = 0;
    this.failed = 0;
  }

  test(name, testFn) {
    this.tests.push({ name, testFn });
  }

  async run() {
    console.log('🧪 **PERSONALITY EVOLUTION ENGINE V3 - TEST SUITE**');
    console.log('=' .repeat(60));
    console.log(`Running ${this.tests.length} tests...\n`);

    for (const { name, testFn } of this.tests) {
      try {
        await testFn();
        console.log(`✅ ${name}`);
        this.passed++;
      } catch (error) {
        console.error(`❌ ${name}`);
        console.error(`   Error: ${error.message}`);
        this.failed++;
      }
    }

    console.log(`\n📊 **TEST RESULTS**`);
    console.log(`✅ Passed: ${this.passed}`);
    console.log(`❌ Failed: ${this.failed}`);
    console.log(`📈 Success Rate: ${(this.passed / this.tests.length * 100).toFixed(1)}%`);

    if (this.failed === 0) {
      console.log('🎉 **ALL TESTS PASSED** - V3 system is production-ready!');
    } else {
      console.log('⚠️ Some tests failed - review before production deployment');
    }

    return this.failed === 0;
  }

  assert(condition, message) {
    if (!condition) {
      throw new Error(message);
    }
  }

  assertEquals(actual, expected, message) {
    if (actual !== expected) {
      throw new Error(`${message}: expected ${expected}, got ${actual}`);
    }
  }

  assertGreaterThan(actual, threshold, message) {
    if (actual <= threshold) {
      throw new Error(`${message}: expected > ${threshold}, got ${actual}`);
    }
  }
}

// Test data - minimal valid personalities
const testDaedalus = {
  version: '1.0.0',
  identity: { name: 'Daedalus', priority: 'lead', tagline: 'Test architecture' },
  ideology: { 
    principles: ['Evidence over assumptions', 'Architecture should encode intent'],
    ethos: ['Upstream-curious', 'Simplicity first']
  },
  learning: {
    inputs: { geo: ['test.json'], runtime: ['logs'] },
    feedback_loops: ['Test loop']
  },
  decision_policy: {
    link_scoring: {
      weights: { weightCluster: 1.1, weightDistance: 1.3 }
    }
  }
};

const testHunter = {
  version: '1.0.0', 
  identity: { name: 'Hunter', priority: 'follow-up', tagline: 'Test quality' },
  ideology: {
    principles: ['Prevent, prove, and patrol', 'Every decision must be justified by evidence'],
    ethos: ['Consolidate knowledge']
  },
  learning: {
    inputs: { signals: ['build.log'], product: ['metrics'] },
    feedback_loops: ['Quality loop']
  },
  decision_policy: {
    gates: { build: ['schema validity'], perf: ['size budgets'] }
  },
  communication_style: { tone: ['terse', 'investigative'] }
};

// Initialize test runner
const runner = new TestRunner();

// Test 1: Load Personality Function
runner.test('Load Personality - Valid File', () => {
  // Create temporary test file
  const testFile = resolve(__dirname, 'test-personality.json');
  writeFileSync(testFile, JSON.stringify(testDaedalus, null, 2));
  
  try {
    const loaded = loadPersonality(testFile, __dirname);
    runner.assert(loaded !== null, 'Should load valid personality');
    runner.assertEquals(loaded.identity.name, 'Daedalus', 'Should preserve identity');
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

runner.test('Load Personality - Missing File', () => {
  const result = loadPersonality('nonexistent.json', __dirname);
  runner.assert(result === null, 'Should return null for missing file');
});

// Test 2: Cognitive Diversity Analysis
runner.test('Cognitive Diversity Analysis', () => {
  const personalities = [
    { name: 'daedalus', personality: testDaedalus },
    { name: 'hunter', personality: testHunter }
  ];
  
  const result = analyzeCognitiveDiversity(personalities, { quiet: true });
  
  runner.assert(result.diversityScore !== undefined, 'Should calculate diversity score');
  runner.assertGreaterThan(result.diversityScore, 0, 'Diversity score should be positive');
  runner.assert(result.principleTypes.size >= 2, 'Should identify multiple principle types');
  runner.assertEquals(Object.keys(result.roleDistribution).length, 2, 'Should detect both roles');
});

// Test 3: Conflict Detection
runner.test('Enhanced Conflict Detection - No Conflicts', () => {
  const personalities = [
    { name: 'daedalus', personality: testDaedalus },
    { name: 'hunter', personality: testHunter }
  ];
  
  const result = detectConflicts(personalities, { quiet: true });
  
  runner.assertEquals(result.totalConflicts, 0, 'Test personalities should have no conflicts');
  runner.assertEquals(result.overallHealth, 'excellent', 'Should have excellent health');
});

runner.test('Enhanced Conflict Detection - Role Conflict', () => {
  const conflictingPersonalities = [
    { name: 'daedalus1', personality: { ...testDaedalus, identity: { ...testDaedalus.identity, name: 'Daedalus1' } } },
    { name: 'daedalus2', personality: { ...testDaedalus, identity: { ...testDaedalus.identity, name: 'Daedalus2' } } }
  ];
  
  const result = detectConflicts(conflictingPersonalities, { quiet: true });
  
  runner.assertGreaterThan(result.totalConflicts, 0, 'Should detect role conflicts');
  runner.assertEquals(result.overlaps.length, 1, 'Should identify one role overlap');
});

// Test 4: Enhancement System with Dry Run
runner.test('Enhancement System - Dry Run Mode', () => {
  const testFile = resolve(__dirname, 'test-hunter.json');
  writeFileSync(testFile, JSON.stringify(testHunter, null, 2));
  
  try {
    const result = enhancePersonality(testFile, ['quality-gates'], { 
      dryRun: true, 
      basePath: __dirname 
    });
    
    runner.assertEquals(result.enhanced, false, 'Dry run should not apply changes');
    runner.assertEquals(result.dryRun, true, 'Should indicate dry run mode');
    runner.assertGreaterThan(result.changes.length, 0, 'Should plan changes');
    
    // Verify file wasn't actually modified
    const fileContent = JSON.parse(readFileSync(testFile, 'utf8'));
    runner.assertEquals(fileContent.version, '1.0.0', 'File should remain unchanged in dry run');
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

runner.test('Enhancement System - Real Enhancement', () => {
  const testFile = resolve(__dirname, 'test-hunter-real.json');
  writeFileSync(testFile, JSON.stringify(testHunter, null, 2));
  
  try {
    const result = enhancePersonality(testFile, ['quality-gates'], { 
      basePath: __dirname,
      validate: false // Skip validation for test
    });
    
    runner.assertEquals(result.enhanced, true, 'Should apply enhancements');
    runner.assertGreaterThan(result.changes.length, 0, 'Should have made changes');
    
    // Verify file was actually modified
    const enhanced = JSON.parse(readFileSync(testFile, 'utf8'));
    runner.assertEquals(enhanced.version, '1.0.1', 'Version should be incremented');
    runner.assert(enhanced.decision_policy?.gates?.accessibility, 'Should add accessibility gates');
    
    // Verify backup was created
    const backupFile = testFile.replace('.json', '.backup.json');
    runner.assert(existsSync(backupFile), 'Should create backup file');
    
    if (existsSync(backupFile)) unlinkSync(backupFile);
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

// Test 5: Post-Enhancement Validation
runner.test('Post-Enhancement Validation', () => {
  const original = { ...testHunter };
  const enhanced = { 
    ...testHunter, 
    version: '1.0.1',
    decision_policy: {
      ...testHunter.decision_policy,
      gates: {
        ...testHunter.decision_policy.gates,
        accessibility: ENHANCEMENT_TEMPLATES.qualityGates.accessibility
      }
    }
  };
  
  const validation = validateEnhancedPersonality(enhanced, original);
  runner.assertEquals(validation.issues.length, 0, 'Valid enhancement should have no issues');
});

// Test 6: Template System
runner.test('Enhancement Templates - Structure Validation', () => {
  runner.assert(ENHANCEMENT_TEMPLATES.qualityGates, 'Should have quality gates template');
  runner.assert(ENHANCEMENT_TEMPLATES.collaborationFramework, 'Should have collaboration template');
  runner.assert(ENHANCEMENT_TEMPLATES.mathematicalFrameworks, 'Should have math frameworks template');
  
  // Verify templates have descriptions
  Object.values(ENHANCEMENT_TEMPLATES).forEach(template => {
    runner.assert(template.description, 'Each template should have description');
  });
});

// Test 7: Error Handling
runner.test('Error Handling - Invalid JSON', () => {
  const testFile = resolve(__dirname, 'invalid.json');
  writeFileSync(testFile, '{ invalid json }');
  
  try {
    const result = loadPersonality(testFile, __dirname);
    runner.assertEquals(result, null, 'Should handle invalid JSON gracefully');
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

// Test 8: Path Resolution
runner.test('Path Resolution - Relative Paths', () => {
  const testFile = resolve(__dirname, 'path-test.json');
  writeFileSync(testFile, JSON.stringify(testDaedalus, null, 2));
  
  try {
    // Test with just filename (should resolve from basePath)
    const result = loadPersonality('path-test.json', __dirname);
    runner.assert(result !== null, 'Should resolve relative paths correctly');
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

// Test 9: Semantic Conflict Detection
runner.test('Semantic Conflict Detection - Contradiction Pairs', () => {
  const conflictPersonalities = [
    { 
      name: 'manual-person', 
      personality: { 
        ...testDaedalus,
        identity: { ...testDaedalus.identity, name: 'ManualPerson' },
        ideology: {
          principles: ['Manual review is essential', 'Never automate critical decisions']
        }
      }
    },
    { 
      name: 'auto-person', 
      personality: { 
        ...testHunter,
        identity: { ...testHunter.identity, name: 'AutoPerson', priority: 'advisor' },
        ideology: {
          principles: ['Automated processes are superior', 'Always use systematic automation']
        }
      }
    }
  ];
  
  const result = detectConflicts(conflictPersonalities, { quiet: true });
  
  // Should detect semantic contradictions between manual/automated approaches
  const hasContradiction = result.contradictions.length > 0 || result.warnings.length > 0;
  runner.assert(hasContradiction, 'Should detect manual vs automated contradiction');
});

// Test 10: Version Compatibility
runner.test('Version Compatibility Tracking', () => {
  const testFile = resolve(__dirname, 'version-test.json');
  const originalPersonality = { ...testHunter, version: '1.0.0' };
  writeFileSync(testFile, JSON.stringify(originalPersonality, null, 2));
  
  try {
    const result = enhancePersonality(testFile, ['quality-gates'], { 
      basePath: __dirname,
      validate: false
    });
    
    runner.assertEquals(result.enhanced, true, 'Should enhance personality');
    runner.assertEquals(result.newVersion, '1.0.1', 'Should increment version');
    
    // Check enhancement history was added
    const enhanced = JSON.parse(readFileSync(testFile, 'utf8'));
    runner.assert(enhanced._lastEnhanced, 'Should track enhancement timestamp');
    runner.assert(enhanced._enhancementHistory, 'Should maintain enhancement history');
    runner.assertGreaterThan(enhanced._enhancementHistory.length, 0, 'Should have history entries');
    
    const backupFile = testFile.replace('.json', '.backup.json');
    if (existsSync(backupFile)) unlinkSync(backupFile);
  } finally {
    if (existsSync(testFile)) unlinkSync(testFile);
  }
});

// Run all tests
if (import.meta.url === `file://${process.argv[1]}`) {
  // Set test environment
  process.env.NODE_ENV = 'test';
  
  runner.run().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('Test runner failed:', error);
    process.exit(1);
  });
}

export { TestRunner };
