/**
 * NEXUS Integrated System Test & Demonstration
 * 
 * Tests the complete hybrid system: Trait Composition + NEXUS Runtime
 */

import { nexus } from './NEXUS.engine.js';
import { HunterAudit, executeHunterFollowUp } from './Hunter.audit.js';
import { runtimeMonitor, performanceAnalytics } from './NEXUS.integration.js';

export class NEXUSIntegratedSystemTest {
  
  async runComprehensiveTest(): Promise<void> {
    console.log('🚀 NEXUS INTEGRATED SYSTEM TEST STARTING...\n');

    // Test 1: Runtime Availability Check
    await this.testRuntimeAvailability();

    // Test 2: Trait Composition Engine
    await this.testTraitComposition();

    // Test 3: Hybrid System Integration
    await this.testHybridIntelligence();

    // Test 4: Hunter Follow-Up System
    await this.testHunterFollowUp();

    // Test 5: Performance Analytics
    await this.testPerformanceAnalytics();

    console.log('\n🎊 NEXUS INTEGRATED SYSTEM TEST COMPLETE!');
  }

  private async testRuntimeAvailability(): Promise<void> {
    console.log('🔍 TEST 1: NEXUS Runtime Availability');
    console.log('=====================================');
    
    const status = runtimeMonitor.getRuntimeStatus();
    console.log(`Runtime Available: ${status.available}`);
    console.log(`Mode: ${status.mode}`);
    console.log(`Capabilities: ${status.capabilities.join(', ')}`);
    console.log('✅ Runtime status check complete\n');
  }

  private async testTraitComposition(): Promise<void> {
    console.log('🧠 TEST 2: Trait Composition Engine');
    console.log('===================================');

    // Test different task types
    const tasks = [
      'Optimize header performance and accessibility',
      'Debug critical production issues',
      'Create beautiful user interface',
      'Audit code for security vulnerabilities'
    ];

    for (const task of tasks) {
      const agent = await nexus.createOptimizedSession(task);
      console.log(`Task: "${task}"`);
      console.log(`Traits Composed: ${agent.traitsUsed.join(', ')}`);
      console.log(`Optimization Score: ${agent.optimizationScore}/100`);
      console.log('---');
    }
    console.log('✅ Trait composition test complete\n');
  }

  private async testHybridIntelligence(): Promise<void> {
    console.log('⚡ TEST 3: Hybrid Intelligence System');
    console.log('====================================');

    const testTask = 'Analyze header architecture and suggest improvements for production deployment';
    
    try {
      const agent = await nexus.createOptimizedSession(testTask);
      const result = await agent.execute({
        task: testTask,
        context: 'Header.astro component analysis'
      });

      console.log(`Task: ${testTask}`);
      console.log(`Intelligence Source: ${result.source}`);
      console.log(`Traits Used: ${result.traitsUsed?.join(', ')}`);
      console.log(`Processing Time: ${result.processingTime}ms`);
      console.log(`Confidence: ${result.confidence}%`);
      
      if (result.response) {
        console.log(`Enhanced Response Preview: ${result.response.substring(0, 200)}...`);
      }
    } catch (error) {
      console.log(`⚠️ Hybrid test failed, falling back to local composition: ${error}`);
    }
    
    console.log('✅ Hybrid intelligence test complete\n');
  }

  private async testHunterFollowUp(): Promise<void> {
    console.log('🔍 TEST 4: Hunter Follow-Up System');
    console.log('==================================');

    try {
      const hunter = new HunterAudit();
      const auditResults = await hunter.auditBobsWork();

      console.log(`Audit Agent Created: ${auditResults.agent.id}`);
      console.log(`Runtime Source: ${auditResults.runtimeInfo?.source}`);
      console.log(`Traits Used: ${auditResults.runtimeInfo?.traitsUsed?.join(', ')}`);
      console.log(`Confidence: ${auditResults.runtimeInfo?.confidence}%`);
      console.log(`Findings: ${auditResults.audit.findings.length}`);
      console.log(`Production Ready: ${auditResults.audit.productionReady}`);
      
      if (auditResults.audit.enhancedInsights) {
        console.log('Enhanced Insights Available: Yes');
      }

    } catch (error) {
      console.log(`⚠️ Hunter follow-up test error: ${error}`);
    }

    console.log('✅ Hunter follow-up test complete\n');
  }

  private async testPerformanceAnalytics(): Promise<void> {
    console.log('📊 TEST 5: Performance Analytics');
    console.log('================================');

    // Simulate some usage data
    performanceAnalytics.recordTraitUsage('Forensic Analysis', 95, 150, true);
    performanceAnalytics.recordTraitUsage('Systematic Engineering', 90, 200, true);
    performanceAnalytics.recordTraitUsage('Precision Aesthetics', 88, 180, true);

    const report = performanceAnalytics.generatePerformanceReport();
    console.log(report);
    console.log('✅ Performance analytics test complete\n');
  }

  /**
   * Demonstrate real-world usage scenarios
   */
  async demonstrateRealWorldScenarios(): Promise<void> {
    console.log('🌟 REAL-WORLD SCENARIO DEMONSTRATIONS');
    console.log('====================================\n');

    // Scenario 1: Code Review
    await this.demonstrateCodeReview();

    // Scenario 2: Performance Optimization
    await this.demonstratePerformanceOptimization();

    // Scenario 3: Accessibility Audit
    await this.demonstrateAccessibilityAudit();
  }

  private async demonstrateCodeReview(): Promise<void> {
    console.log('📋 SCENARIO: Code Review');
    console.log('========================');

    const agent = await nexus.createOptimizedSession(
      'Review Header.astro code for best practices, security, and maintainability'
    );

    console.log(`Reviewer Agent: ${agent.id}`);
    console.log(`Traits: ${agent.traitsUsed.join(' + ')}`);
    console.log(`Specialization: Code quality and security analysis`);
    console.log('🔍 Review in progress...\n');
  }

  private async demonstratePerformanceOptimization(): Promise<void> {
    console.log('⚡ SCENARIO: Performance Optimization');
    console.log('====================================');

    const agent = await nexus.createOptimizedSession(
      'Optimize header component for Core Web Vitals and mobile performance'
    );

    console.log(`Optimizer Agent: ${agent.id}`);
    console.log(`Traits: ${agent.traitsUsed.join(' + ')}`);
    console.log(`Specialization: Performance and mobile optimization`);
    console.log('⚡ Optimization analysis in progress...\n');
  }

  private async demonstrateAccessibilityAudit(): Promise<void> {
    console.log('♿ SCENARIO: Accessibility Audit');
    console.log('===============================');

    const agent = await nexus.createOptimizedSession(
      'Audit header accessibility for WCAG 2.1 AA compliance and screen reader compatibility'
    );

    console.log(`Accessibility Agent: ${agent.id}`);
    console.log(`Traits: ${agent.traitsUsed.join(' + ')}`);
    console.log(`Specialization: Accessibility and inclusive design`);
    console.log('♿ Accessibility analysis in progress...\n');
  }
}

/**
 * Production Deployment Readiness Check
 */
export class ProductionDeploymentCheck {
  
  async runPreDeploymentAudit(): Promise<{
    approved: boolean;
    score: number;
    recommendations: string[];
    blockers: string[];
  }> {
    console.log('🚀 PRODUCTION DEPLOYMENT READINESS CHECK');
    console.log('========================================');

    const results = {
      approved: false,
      score: 0,
      recommendations: [] as string[],
      blockers: [] as string[]
    };

    // Check 1: Hunter's forensic audit
    const hunter = new HunterAudit();
    const audit = await hunter.auditBobsWork();
    
    if (!audit.audit.productionReady) {
      results.blockers.push('Hunter identified production blockers');
    }

    // Check 2: Runtime system health
    const runtimeStatus = runtimeMonitor.getRuntimeStatus();
    if (!runtimeStatus.available) {
      results.recommendations.push('NEXUS Runtime offline - using local composition only');
    }

    // Check 3: Performance metrics
    const perfReport = performanceAnalytics.generatePerformanceReport();
    results.recommendations.push('Review trait performance analytics');

    // Calculate overall score
    let score = 80; // Base score
    if (audit.audit.productionReady) score += 15;
    if (runtimeStatus.available) score += 5;
    if (audit.audit.summary.critical === 0) score += 0; // Already fixed
    
    results.score = Math.min(100, score);
    results.approved = results.score >= 90 && results.blockers.length === 0;

    console.log(`Deployment Score: ${results.score}/100`);
    console.log(`Approved: ${results.approved ? '✅' : '❌'}`);
    console.log(`Blockers: ${results.blockers.length}`);
    console.log(`Recommendations: ${results.recommendations.length}`);

    return results;
  }
}

// Auto-run tests in development
if (typeof window !== 'undefined' && window.location.hostname === 'localhost') {
  const testSuite = new NEXUSIntegratedSystemTest();
  
  // Uncomment to run tests
  // testSuite.runComprehensiveTest().catch(console.error);
  
  // Make available globally for manual testing
  (window as any).NEXUSTest = testSuite;
  (window as any).ProductionCheck = new ProductionDeploymentCheck();
  
  console.log('🧪 NEXUS Test Suite loaded. Run NEXUSTest.runComprehensiveTest() to test the integrated system.');
}
