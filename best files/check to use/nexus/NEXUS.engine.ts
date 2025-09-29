/**
 * NEXUS Trait Composition Engine
 * 
 * Transforms personalities from monolithic entities into 
 * composable cognitive modules for optimal task execution.
 */

export interface PersonalityTrait {
  name: string;
  description: string;
  activationTriggers: string[];
  knowledgeDomains: string[];
  expertise: number; // 0-100
  personalityId: string;
  verificationMethods?: string[];
}

export interface TaskRequirements {
  domain: string;
  complexity: 'simple' | 'moderate' | 'complex' | 'expert';
  requiredCapabilities: string[];
  contextTriggers: string[];
}

export interface ComposedAgent {
  id: string;
  task: string;
  traits: Map<string, PersonalityTrait>;
  knowledge: Set<string>;
  execute: (input: any) => Promise<any>;
  traitsUsed: string[];
  optimizationScore: number;
}

export class TraitIndexer {
  private traitIndex: Map<string, PersonalityTrait[]> = new Map();
  private personalities: Map<string, any> = new Map();

  constructor() {
    this.initializePersonalities();
    this.buildTraitIndex();
  }

  private initializePersonalities() {
    // Bob - Engineering-focused systematic thinking
    this.personalities.set('bob', {
      identity: { name: 'Bob', role: 'Senior Engineer' },
      lifeExperience: {
        background: '15+ years enterprise software development',
        keyExperiences: ['Led major refactoring projects', 'Built scalable architectures']
      },
      cognitiveTraits: {
        systematicEngineering: {
          name: 'Systematic Engineering',
          description: 'Methodical approach to complex technical problems',
          activationTriggers: ['refactor', 'architecture', 'scalable', 'enterprise'],
          knowledgeDomains: ['clean-code', 'design-patterns', 'testing', 'performance'],
          expertise: 90
        },
        modularDesign: {
          name: 'Modular Design',
          description: 'Creates maintainable, composable system architectures',
          activationTriggers: ['modular', 'component', 'reusable', 'maintainable'],
          knowledgeDomains: ['component-architecture', 'separation-of-concerns', 'DRY'],
          expertise: 88
        }
      }
    });

    // Hunter - Forensic-analytical thinking
    this.personalities.set('hunter', {
      identity: { name: 'Hunter', role: 'Forensic Auditor' },
      lifeExperience: {
        background: 'Security and quality assurance specialist',
        keyExperiences: ['Prevented major production failures', 'Led incident investigations']
      },
      cognitiveTraits: {
        evidenceVerification: {
          name: 'Evidence Verification',
          description: 'Validates claims against observable evidence',
          activationTriggers: ['audit', 'verify', 'evidence', 'proof', 'claim', 'assumption'],
          knowledgeDomains: ['testing', 'logs', 'metrics', 'traces'],
          expertise: 95,
          verificationMethods: ['unit-test', 'integration-test', 'manual-verification']
        },
        gapAnalysis: {
          name: 'Gap Analysis',
          description: 'Identifies blind spots and untested areas',
          activationTriggers: ['gap', 'missing', 'untested', 'blind-spot', 'edge-case'],
          knowledgeDomains: ['edge-cases', 'error-conditions', 'boundary-testing'],
          expertise: 90,
          verificationMethods: ['boundary-testing', 'negative-testing', 'chaos-engineering']
        },
        architecturalViolationDetection: {
          name: 'Architectural Violation Detection',
          description: 'Spots anti-patterns and architectural violations',
          activationTriggers: ['inline-handlers', 'tight-coupling', 'memory-leaks', 'anti-pattern'],
          knowledgeDomains: ['clean-architecture', 'SOLID-principles', 'design-patterns'],
          expertise: 88,
          verificationMethods: ['code-analysis', 'performance-profiling', 'security-scan']
        },
        forensicAnalysis: {
          name: 'Forensic Analysis',
          description: 'Evidence-based verification of technical claims',
          activationTriggers: ['audit', 'verify', 'evidence', 'proof', 'gap'],
          knowledgeDomains: ['testing', 'debugging', 'security', 'performance-analysis'],
          expertise: 95
        },
        brutalHonesty: {
          name: 'Brutal Honesty',
          description: 'Reports limitations without sugar-coating',
          activationTriggers: ['limitation', 'assumption', 'risk', 'unknown'],
          knowledgeDomains: ['risk-assessment', 'transparency', 'honest-communication'],
          expertise: 95
        }
      }
    });

    // Stellar - Precision aesthetic-systemic thinking
    this.personalities.set('stellar', {
      identity: { name: 'Stellar', role: 'Space-Grade Engineer' },
      lifeExperience: {
        background: 'Aerospace engineering with aesthetic sensibility',
        keyExperiences: ['Designed mission-critical UI systems', 'Space-grade reliability']
      },
      cognitiveTraits: {
        precisionAesthetics: {
          name: 'Precision Aesthetics',
          description: 'Combines mathematical precision with visual beauty',
          activationTriggers: ['glassmorphism', 'spacing', 'visual', 'precision'],
          knowledgeDomains: ['visual-design', 'mathematical-spacing', 'accessibility'],
          expertise: 92
        },
        spaceGradeReliability: {
          name: 'Space-Grade Reliability',
          description: 'Engineering reliability for mission-critical systems',
          activationTriggers: ['reliability', 'critical', 'fail-safe', 'robust'],
          knowledgeDomains: ['error-handling', 'fault-tolerance', 'performance'],
          expertise: 94
        }
      }
    });

    // Add more personalities with their traits...
    this.addPerformanceSpecialist();
    this.addAccessibilityChampion();
    this.addMobileUXSpecialist();
  }

  private addPerformanceSpecialist() {
    this.personalities.set('flash', {
      identity: { name: 'Flash', role: 'Performance Optimizer' },
      lifeExperience: {
        background: 'High-frequency trading and real-time systems',
        keyExperiences: ['Optimized microsecond-critical systems', 'Memory optimization expert']
      },
      cognitiveTraits: {
        performanceOptimization: {
          name: 'Performance Optimization',
          description: 'Optimizes for speed, memory, and resource efficiency',
          activationTriggers: ['performance', 'speed', 'optimization', 'memory', 'lazy-loading'],
          knowledgeDomains: ['performance-profiling', 'memory-management', 'caching'],
          expertise: 96
        }
      }
    });
  }

  private addAccessibilityChampion() {
    this.personalities.set('aria', {
      identity: { name: 'Aria', role: 'Accessibility Champion' },
      lifeExperience: {
        background: 'Assistive technology and inclusive design',
        keyExperiences: ['Led WCAG compliance initiatives', 'Screen reader power user']
      },
      cognitiveTraits: {
        accessibilityExpertise: {
          name: 'Accessibility Expertise',
          description: 'Ensures inclusive design for all users',
          activationTriggers: ['accessibility', 'ARIA', 'screen-reader', 'keyboard', 'inclusive'],
          knowledgeDomains: ['WCAG', 'assistive-technology', 'inclusive-design'],
          expertise: 94
        }
      }
    });
  }

  private addMobileUXSpecialist() {
    this.personalities.set('touch', {
      identity: { name: 'Touch', role: 'Mobile UX Specialist' },
      lifeExperience: {
        background: 'Mobile-first design and touch interface optimization',
        keyExperiences: ['Designed award-winning mobile apps', 'Touch interaction research']
      },
      cognitiveTraits: {
        mobileOptimization: {
          name: 'Mobile Optimization',
          description: 'Optimizes for touch devices and mobile constraints',
          activationTriggers: ['mobile', 'touch', 'responsive', 'gesture', 'thumb-friendly'],
          knowledgeDomains: ['touch-interfaces', 'mobile-UX', 'responsive-design'],
          expertise: 91
        }
      }
    });
  }

  private buildTraitIndex() {
    for (const [personalityId, personality] of this.personalities.entries()) {
      if (personality.cognitiveTraits) {
        const traits = Object.values(personality.cognitiveTraits) as Array<Omit<PersonalityTrait, 'personalityId'>>;

        for (const trait of traits) {
          const traitName = trait.name;
          
          if (!this.traitIndex.has(traitName)) {
            this.traitIndex.set(traitName, []);
          }

          this.traitIndex.get(traitName)!.push({
            ...trait,
            personalityId
          });
        }
      }
    }
  }

  getBestTraitSource(traitName: string): PersonalityTrait | null {
    const sources = this.traitIndex.get(traitName);
    if (!sources || sources.length === 0) return null;

    return sources.reduce((best, current) => 
      current.expertise > best.expertise ? current : best
    );
  }

  findTraitsByTrigger(trigger: string): PersonalityTrait[] {
    const matchingTraits: PersonalityTrait[] = [];

    for (const traits of this.traitIndex.values()) {
      for (const trait of traits) {
        if (trait.activationTriggers.some(t => 
          t.toLowerCase().includes(trigger.toLowerCase()) ||
          trigger.toLowerCase().includes(t.toLowerCase())
        )) {
          matchingTraits.push(trait);
        }
      }
    }

    return matchingTraits.sort((a, b) => b.expertise - a.expertise);
  }

  getAllTraits(): Map<string, PersonalityTrait[]> {
    return new Map(this.traitIndex);
  }
}

export class TaskAnalyzer {
  private taskPatterns = new Map<string, string[]>([
    ['audit', ['audit', 'verify', 'check', 'validate', 'evidence', 'proof']],
    ['fix', ['fix', 'repair', 'resolve', 'debug', 'solve']],
    ['optimize', ['optimize', 'improve', 'enhance', 'performance', 'speed']],
    ['design', ['design', 'visual', 'aesthetic', 'UI', 'UX', 'appearance']],
    ['accessibility', ['accessibility', 'a11y', 'WCAG', 'screen-reader', 'inclusive']],
    ['mobile', ['mobile', 'touch', 'responsive', 'phone', 'tablet']],
    ['architecture', ['architecture', 'structure', 'modular', 'scalable', 'maintainable']],
    ['security', ['security', 'vulnerable', 'XSS', 'CSP', 'safe']],
    ['performance', ['performance', 'speed', 'memory', 'optimization', 'cache']]
  ]);

  extractRequiredTraits(taskDescription: string): string[] {
    const lowerTask = taskDescription.toLowerCase();
    const requiredCategories: string[] = [];

    for (const [category, keywords] of this.taskPatterns.entries()) {
      if (keywords.some(keyword => lowerTask.includes(keyword))) {
        requiredCategories.push(category);
      }
    }

    // Map categories to specific trait requirements
    const traitRequirements: string[] = [];

    if (requiredCategories.includes('audit')) {
      traitRequirements.push(
        'Evidence Verification',
        'Gap Analysis',
        'Architectural Violation Detection',
        'Forensic Analysis',
        'Brutal Honesty'
      );
    }
    if (requiredCategories.includes('fix')) {
      traitRequirements.push('Systematic Engineering');
    }
    if (requiredCategories.includes('optimize')) {
      traitRequirements.push('Performance Optimization');
    }
    if (requiredCategories.includes('design')) {
      traitRequirements.push('Precision Aesthetics');
    }
    if (requiredCategories.includes('accessibility')) {
      traitRequirements.push('Accessibility Expertise');
    }
    if (requiredCategories.includes('mobile')) {
      traitRequirements.push('Mobile Optimization');
    }
    if (requiredCategories.includes('security')) {
      traitRequirements.push(
        'Architectural Violation Detection',
        'Evidence Verification',
        'Forensic Analysis'
      );
    }

    return [...new Set(traitRequirements)];
  }

  analyzeComplexity(taskDescription: string): 'simple' | 'moderate' | 'complex' | 'expert' {
    const complexityIndicators = {
      simple: ['simple', 'basic', 'quick', 'minor'],
      moderate: ['medium', 'moderate', 'standard'],
      complex: ['complex', 'advanced', 'multi-step', 'integration'],
      expert: ['expert', 'critical', 'enterprise', 'production', 'scalable']
    };

    const lowerTask = taskDescription.toLowerCase();

    for (const [level, indicators] of Object.entries(complexityIndicators)) {
      if (indicators.some(indicator => lowerTask.includes(indicator))) {
        return level as any;
      }
    }

    // Default based on task length and technical keywords
    const technicalKeywords = ['architecture', 'optimization', 'security', 'performance'];
    const hasTechnicalKeywords = technicalKeywords.some(keyword => lowerTask.includes(keyword));
    
    if (hasTechnicalKeywords && taskDescription.length > 100) return 'expert';
    if (hasTechnicalKeywords) return 'complex';
    if (taskDescription.length > 50) return 'moderate';
    return 'simple';
  }
}

export class ComposedAgentFactory {
  constructor(
    private traitIndexer: TraitIndexer,
    private taskAnalyzer: TaskAnalyzer
  ) {}

  createComposedAgent(taskDescription: string, options: { requiredTraits?: string[] } = {}): ComposedAgent {
    // Analyze task requirements
    const inferredTraitNames = this.taskAnalyzer.extractRequiredTraits(taskDescription);
    const complexity = this.taskAnalyzer.analyzeComplexity(taskDescription);

    const traitNameSet = new Set<string>([...inferredTraitNames, ...(options.requiredTraits ?? [])]);

    // Compose optimal traits
    const composedTraits = new Map<string, PersonalityTrait>();
    const knowledge = new Set<string>();

    for (const traitName of traitNameSet) {
      const bestSource = this.traitIndexer.getBestTraitSource(traitName);
      if (bestSource) {
        composedTraits.set(traitName, bestSource);
        bestSource.knowledgeDomains.forEach(domain => knowledge.add(domain));
      }
    }

    // Calculate optimization score
    const optimizationScore = this.calculateOptimizationScore(composedTraits, complexity);

    return {
      id: `composed_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      task: taskDescription,
      traits: composedTraits,
      knowledge,
      traitsUsed: Array.from(composedTraits.keys()),
      optimizationScore,
      execute: async (input: any) => this.executeComposedAgent(composedTraits, input)
    };
  }

  private calculateOptimizationScore(traits: Map<string, PersonalityTrait>, complexity: string): number {
    if (traits.size === 0) return 0;

    const avgExpertise = Array.from(traits.values())
      .reduce((sum, trait) => sum + trait.expertise, 0) / traits.size;

    const complexityMultiplier = {
      simple: 0.8,
      moderate: 0.9,
      complex: 1.0,
      expert: 1.1
    }[complexity] || 1.0;

    const traitSynergyBonus = traits.size > 2 ? 0.1 : 0;

    return Math.min(100, Math.round(avgExpertise * complexityMultiplier + traitSynergyBonus * 10));
  }

  private async executeComposedAgent(traits: Map<string, PersonalityTrait>, input: any): Promise<any> {
    const startTime = Date.now();
    
    // Try to enhance with existing NEXUS Runtime first
    const { TraitAPIIntegration, performanceAnalytics } = await import('./NEXUS.integration.js');
    const apiIntegration = new TraitAPIIntegration();
    
    const agent = {
      traits,
      traitsUsed: Array.from(traits.keys()),
      optimizationScore: this.calculateOptimizationScore(traits, 'moderate')
    } as any;

    const enhancedResult = await apiIntegration.enhanceWithNexusRuntime(
      agent,
      input.task || input.toString(),
      { domain: 'development', complexity: 'moderate' }
    );

    if (enhancedResult) {
      const processingTime = Date.now() - startTime;
      
      // Record performance for each trait
      for (const traitName of agent.traitsUsed) {
        performanceAnalytics.recordTraitUsage(
          traitName,
          enhancedResult.confidence,
          processingTime,
          true
        );
      }

      return {
        source: 'nexus-runtime-enhanced',
        response: enhancedResult.response,
        confidence: enhancedResult.confidence,
        processingTime: enhancedResult.processingTime,
        traitsUsed: agent.traitsUsed,
        metadata: enhancedResult.metadata
      };
    }

    // Fallback to local composition logic
    console.log('📍 NEXUS: Using local trait composition (runtime unavailable)');
    const results = [];

    for (const [traitName, trait] of traits.entries()) {
      const traitResult = await this.executeTraitLogic(trait, input);
      results.push({
        trait: traitName,
        personality: trait.personalityId,
        result: traitResult
      });
    }

    const processingTime = Date.now() - startTime;
    const confidence = this.calculateConfidence(traits);

    // Record local composition performance
    for (const traitName of Array.from(traits.keys())) {
      performanceAnalytics.recordTraitUsage(
        traitName,
        confidence,
        processingTime,
        true
      );
    }

    return {
      source: 'local-composition',
      composedResults: results,
      synthesis: this.synthesizeResults(results),
      confidence,
      processingTime,
      traitsUsed: Array.from(traits.keys())
    };
  }

  private async executeTraitLogic(trait: PersonalityTrait, input: any): Promise<any> {
    // Trait-specific execution logic based on the trait's knowledge domains
    // This would integrate with the actual personality implementations
    return {
      analysis: `${trait.name} analysis of input`,
      recommendations: trait.knowledgeDomains.map(domain => `Apply ${domain} principles`),
      expertise: trait.expertise
    };
  }

  private synthesizeResults(results: any[]): string {
    return `Synthesized insights from ${results.length} cognitive traits`;
  }

  private calculateConfidence(traits: Map<string, PersonalityTrait>): number {
    const avgExpertise = Array.from(traits.values())
      .reduce((sum, trait) => sum + trait.expertise, 0) / traits.size;
    return Math.round(avgExpertise);
  }
}

/**
 * NEXUS Orchestrator with Trait Composition
 */
export class NEXUSOrchestrator {
  private traitIndexer: TraitIndexer;
  private taskAnalyzer: TaskAnalyzer; 
  private agentFactory: ComposedAgentFactory;

  constructor() {
    this.traitIndexer = new TraitIndexer();
    this.taskAnalyzer = new TaskAnalyzer();
    this.agentFactory = new ComposedAgentFactory(this.traitIndexer, this.taskAnalyzer);
  }

  async createOptimizedSession(taskDescription: string, options: { requiredTraits?: string[] } = {}): Promise<ComposedAgent> {
    console.log(`🧠 NEXUS: Analyzing task "${taskDescription}"`);
    
    // Create trait-composed agent
    const composedAgent = this.agentFactory.createComposedAgent(taskDescription, options);
    
    console.log(`✅ Composed agent with traits: ${composedAgent.traitsUsed.join(', ')}`);
    console.log(`🎯 Optimization score: ${composedAgent.optimizationScore}/100`);
    
    return composedAgent;
  }

  async executeFollowUpAudit(workDescription: string, scope: any): Promise<any> {
    console.log('🔍 NEXUS: Initiating Hunter follow-up audit...');
    
    // Create Hunter-focused agent for audit
    const auditAgent = this.agentFactory.createComposedAgent(
      `audit and verify ${workDescription} with brutal honesty about limitations`,
      {
        requiredTraits: [
          'Evidence Verification',
          'Gap Analysis',
          'Architectural Violation Detection',
          'Forensic Analysis',
          'Brutal Honesty'
        ]
      }
    );
    
    return await auditAgent.execute(scope);
  }

  getAvailableTraits(): string[] {
    const allTraits = this.traitIndexer.getAllTraits();
    return Array.from(allTraits.keys());
  }

  getPersonalityTraits(personalityId: string): string[] {
    const allTraits = this.traitIndexer.getAllTraits();
    const personalityTraits: string[] = [];
    
    for (const [traitName, traits] of allTraits.entries()) {
      if (traits.some(trait => trait.personalityId === personalityId)) {
        personalityTraits.push(traitName);
      }
    }
    
    return personalityTraits;
  }
}

// Export singleton instance
export const nexus = new NEXUSOrchestrator();
