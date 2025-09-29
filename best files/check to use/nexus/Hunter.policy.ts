import type { PersonalityTrait } from './NEXUS.engine.js';
import { readFile as fsReadFile } from 'fs/promises';
import { resolve } from 'path';

/**
 * Hunter's Forensic Policy Framework
 * 
 * Implements evidence-based auditing with trait composition
 * for systematic follow-up on all development work.
 */

export interface ForensicEvidence {
  type: 'violation' | 'gap' | 'assumption' | 'untested' | 'missing';
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  evidence: string[];
  impact: string;
  recommendation: string;
  testable: boolean;
}

export interface CognitiveTrait extends PersonalityTrait {
  verificationMethods: string[];
}

export interface AuditScope {
  codeFiles: string[];
  testFiles: string[];
  configFiles: string[];
  dependencies: string[];
  buildOutputs: string[];
}

export class HunterPolicy {
  private readonly traits: Map<string, CognitiveTrait> = new Map();
  private readonly evidenceChain: ForensicEvidence[] = [];
  private readonly tokenDefinitions: Set<string> = new Set();
  private tokenScopeSignature: string | null = null;
  
  constructor() {
    this.initializeTraits();
  }

  private initializeTraits() {
    // Hunter's Core forensic-analytical traits
    this.traits.set('evidenceVerification', {
      name: 'Evidence Verification',
      description: 'Validates claims against observable evidence',
      activationTriggers: ['claim', 'assumption', 'works-on-my-machine'],
      knowledgeDomains: ['testing', 'logs', 'metrics', 'traces'],
      expertise: 95,
      personalityId: 'hunter',
      verificationMethods: ['unit-test', 'integration-test', 'manual-verification']
    });

    this.traits.set('gapAnalysis', {
      name: 'Gap Analysis', 
      description: 'Identifies what hasn\'t been tested or considered',
      activationTriggers: ['blind-spot', 'edge-case', 'untested'],
      knowledgeDomains: ['edge-cases', 'error-conditions', 'boundary-testing'],
      expertise: 90,
      personalityId: 'hunter',
      verificationMethods: ['boundary-testing', 'negative-testing', 'chaos-engineering']
    });

    this.traits.set('architecturalViolationDetection', {
      name: 'Architectural Violation Detection',
      description: 'Spots anti-patterns and architectural violations',
      activationTriggers: ['inline-handlers', 'tight-coupling', 'memory-leaks'],
      knowledgeDomains: ['clean-architecture', 'SOLID-principles', 'design-patterns'],
      expertise: 88,
      personalityId: 'hunter',
      verificationMethods: ['code-analysis', 'performance-profiling', 'security-scan']
    });

    this.traits.set('brutalHonesty', {
      name: 'Brutal Honesty Assessment',
      description: 'Reports limitations and unknowns without sugar-coating',
      activationTriggers: ['limitation', 'unknown', 'assumption'],
      knowledgeDomains: ['risk-assessment', 'impact-analysis', 'root-cause'],
      expertise: 95,
      personalityId: 'hunter',
      verificationMethods: ['stakeholder-review', 'peer-review', 'user-testing']
    });
  }

  /**
   * POLICY 1: Immediate Evidence Verification
   * Every claim must be backed by verifiable evidence
   */
  async verifyEvidence(claim: string, scope: AuditScope): Promise<ForensicEvidence[]> {
    const findings: ForensicEvidence[] = [];
    // Scan for inline event handlers (critical violation)
    const inlineHandlerPattern = /on(click|mouse|focus|blur|change)="[^"]*"/gi;
    
    for (const file of scope.codeFiles) {
      try {
        const content = await this.readFile(file);
        const violations = content.match(inlineHandlerPattern) || [];
        
        if (violations.length > 0) {
          findings.push({
            type: 'violation',
            severity: 'critical',
            description: `Inline event handlers detected in ${file}`,
            evidence: violations,
            impact: 'CSP violations, memory leaks, untestable interactions, XSS surface',
            recommendation: 'Replace with event delegation in controller',
            testable: true
          });
        }
      } catch (error) {
        findings.push({
          type: 'gap',
          severity: 'medium', 
          description: `Could not verify file ${file}`,
          evidence: [`Error: ${error}`],
          impact: 'Unverified code in production',
          recommendation: 'Ensure file accessibility for auditing',
          testable: false
        });
      }
    }

    return findings;
  }

  /**
   * POLICY 2: Gap Analysis Protocol
   * Identify what hasn't been tested or considered
   */
  async analyzeGaps(scope: AuditScope): Promise<ForensicEvidence[]> {
    const findings: ForensicEvidence[] = [];
    // Check for missing test coverage
    const codeFiles = scope.codeFiles.length;
    const testFiles = scope.testFiles.length;
    const testCoverageRatio = testFiles / codeFiles;

    if (testCoverageRatio < 0.8) {
      findings.push({
        type: 'gap',
        severity: 'high',
        description: 'Insufficient test coverage detected',
        evidence: [`${testFiles} test files for ${codeFiles} code files`],
        impact: 'Untested code paths, regression risk',
        recommendation: 'Achieve minimum 80% test file coverage',
        testable: true
      });
    }

    // Check for undefined CSS tokens
    await this.ensureTokenDefinitions(scope.configFiles);

    for (const file of scope.codeFiles) {
      const content = await this.readFile(file);
      const tokenPattern = /var\(--[^)]+\)/g;
      const tokens = content.match(tokenPattern) || [];
      
      for (const token of tokens) {
        const tokenName = token.match(/--([^)]+)/)?.[1];
        if (tokenName && !this.isTokenDefined(tokenName)) {
          findings.push({
            type: 'violation',
            severity: 'high',
            description: `Undefined CSS token: ${token}`,
            evidence: [token],
            impact: 'Visual inconsistency, fallback to browser defaults',
            recommendation: `Define ${token} in CSS token system`,
            testable: true
          });
        }
      }
    }

    return findings;
  }

  /**
   * POLICY 3: Architectural Violation Detection
   * Spot patterns that violate clean architecture principles
   */
  async detectArchitecturalViolations(scope: AuditScope): Promise<ForensicEvidence[]> {
    const findings: ForensicEvidence[] = [];
    for (const file of scope.codeFiles) {
      const content = await this.readFile(file);
      
      // Detect repeated inline logic (DRY violation)
      const inlineStylePattern = /style="[^"]*"/g;
      const inlineStyles = content.match(inlineStylePattern) || [];
      const duplicateStyles = this.findDuplicatePatterns(inlineStyles);
      
      if (duplicateStyles.length > 0) {
        findings.push({
          type: 'violation',
          severity: 'medium',
          description: 'Repeated inline styles detected - DRY violation',
          evidence: duplicateStyles,
          impact: 'Maintenance burden, inconsistent styling',
          recommendation: 'Extract to CSS classes or CSS-in-JS',
          testable: true
        });
      }

      // Detect mixing of concerns (presentation + logic)
      const mixedConcernPattern = /onmouse\w+="[^"]*var\(--[^"]*"/g;
      const mixedConcerns = content.match(mixedConcernPattern) || [];
      
      if (mixedConcerns.length > 0) {
        findings.push({
          type: 'violation',
          severity: 'high',
          description: 'Mixed concerns: CSS tokens in event handlers',
          evidence: mixedConcerns,
          impact: 'Tight coupling, difficult testing, CSP issues',
          recommendation: 'Separate presentation from interaction logic',
          testable: true
        });
      }
    }

    return findings;
  }

  /**
   * POLICY 4: Brutal Honesty Assessment
   * Document what we don't know and can't verify
   */
  async assessLimitations(scope: AuditScope): Promise<ForensicEvidence[]> {
    const findings: ForensicEvidence[] = [];
    // What we CAN'T verify without running tests
    findings.push({
      type: 'untested',
      severity: 'medium',
      description: 'Runtime behavior unverified',
      evidence: ['No execution traces available', 'Static analysis only'],
      impact: 'Unknown runtime failures, performance characteristics unclear',
      recommendation: 'Run integration tests and collect performance metrics',
      testable: true
    });

    // Browser compatibility assumptions
    findings.push({
      type: 'assumption',
      severity: 'medium',
      description: 'CSS token browser support assumed',
      evidence: ['CSS custom properties used', 'No polyfill detected'],
      impact: 'Potential visual breakage in older browsers',
      recommendation: 'Test in target browser matrix or add polyfill',
      testable: true
    });

    // Touch device interactions
    findings.push({
      type: 'gap',
      severity: 'medium',
      description: 'Touch device interactions not explicitly handled',
      evidence: ['Mouse events only', 'No touch event handlers'],
      impact: 'Poor mobile UX, accessibility issues',
      recommendation: 'Add touch event handling and test on real devices',
      testable: true
    });

    return findings;
  }

  /**
   * Generate comprehensive audit report
   */
  async auditComponent(scope: AuditScope): Promise<{
    findings: ForensicEvidence[];
    summary: {
      critical: number;
      high: number;
      medium: number;
      low: number;
    };
    productionReady: boolean;
    recommendations: string[];
  }> {
    const allFindings: ForensicEvidence[] = [];
    
  await this.ensureTokenDefinitions(scope.configFiles);

  // Run all audit policies
    allFindings.push(...await this.verifyEvidence('CSS token integration complete', scope));
    allFindings.push(...await this.analyzeGaps(scope));
    allFindings.push(...await this.detectArchitecturalViolations(scope));
    allFindings.push(...await this.assessLimitations(scope));

    // Categorize by severity
    const summary = {
      critical: allFindings.filter(f => f.severity === 'critical').length,
      high: allFindings.filter(f => f.severity === 'high').length,
      medium: allFindings.filter(f => f.severity === 'medium').length,
      low: allFindings.filter(f => f.severity === 'low').length
    };

    // Production readiness assessment
    const productionReady = summary.critical === 0 && summary.high <= 2;

    // Prioritized recommendations
    const recommendations = allFindings
      .filter(f => f.severity === 'critical' || f.severity === 'high')
      .map(f => f.recommendation);

    return {
      findings: allFindings,
      summary,
      productionReady,
      recommendations
    };
  }

  // Utility methods
  private async readFile(path: string): Promise<string> {
    const absolute = path.startsWith('/') ? path : resolve(process.cwd(), path);
    return await fsReadFile(absolute, 'utf-8');
  }

  private async ensureTokenDefinitions(configFiles: string[]): Promise<void> {
    const signature = configFiles.join('|');
    if (this.tokenScopeSignature === signature && this.tokenDefinitions.size > 0) {
      return;
    }

    this.tokenDefinitions.clear();
    this.tokenScopeSignature = signature;

    const tokenDeclarationPattern = /--([a-z0-9-]+)\s*:/gi;

    for (const file of configFiles) {
      try {
        const content = await this.readFile(file);
        let match: RegExpExecArray | null;
        while ((match = tokenDeclarationPattern.exec(content)) !== null) {
          this.tokenDefinitions.add(match[1]);
        }
      } catch (error) {
        // If config file can't be read, continue; missing tokens will be reported elsewhere
      }
    }
  }

  private isTokenDefined(tokenName: string): boolean {
    return this.tokenDefinitions.has(tokenName);
  }

  private findDuplicatePatterns(items: string[]): string[] {
    const counts = new Map();
    items.forEach(item => counts.set(item, (counts.get(item) || 0) + 1));
    return Array.from(counts.entries())
      .filter(([_, count]) => count > 1)
      .map(([item, count]) => `${item} (${count} times)`);
  }
}

/**
 * NEXUS Integration: Hunter's Trait Composition
 */
export const hunterTraits = {
  forensicAnalysis: {
    description: 'Evidence-based verification of technical claims',
    activationTriggers: ['audit', 'verify', 'evidence', 'proof'],
    knowledgeDomains: ['testing', 'debugging', 'performance-analysis'],
    expertise: 95
  },
  
  gapDetection: {
    description: 'Identifies blind spots and untested areas',
    activationTriggers: ['gap', 'missing', 'untested', 'blind-spot'],
    knowledgeDomains: ['edge-cases', 'boundary-conditions', 'error-states'],
    expertise: 90
  },
  
  brutalHonesty: {
    description: 'Reports limitations without sugar-coating',
    activationTriggers: ['limitation', 'assumption', 'unknown', 'risk'],
    knowledgeDomains: ['risk-assessment', 'honesty', 'transparency'],
    expertise: 95
  }
};
