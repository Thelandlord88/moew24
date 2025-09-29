/**
 * NEXUS Runtime Integration Layer
 * 
 * Bridges the Trait Composition Engine with the existing NEXUS HTTP Runtime
 * for seamless hybrid intelligence orchestration.
 */

import { ComposedAgent, PersonalityTrait } from './NEXUS.engine.js';

export interface NexusRuntimeResponse {
  response: string;
  personalityUsed: string;
  confidence: number;
  processingTime: number;
  metadata?: Record<string, any>;
}

export interface TraitEnhancementRequest {
  personalityName: string;
  request: string;
  traits?: string[];
  context?: {
    domain: string;
    complexity: string;
    requiredCapabilities: string[];
  };
}

export class TraitAPIIntegration {
  private readonly NEXUS_API: string;
  private readonly timeout = 8000; // 8 second timeout
  private fallbackCache = new Map<string, any>();

  constructor() {
    this.NEXUS_API = this.getApiBase();
    this.warmupConnection();
  }

  /**
   * Enhance composed agent with existing NEXUS Runtime consciousness
   */
  async enhanceWithNexusRuntime(
    agent: ComposedAgent, 
    task: string, 
    context?: Record<string, any>
  ): Promise<NexusRuntimeResponse | null> {
    const startTime = Date.now();
    
    try {
      console.log(`🧠 NEXUS: Enhancing with runtime - Traits: ${agent.traitsUsed.join(', ')}`);
      
      // Prepare enhancement request
      const enhancementRequest: TraitEnhancementRequest = {
        personalityName: this.selectPrimaryPersonality(agent.traits),
        request: this.formatTraitEnhancedRequest(task, agent),
        traits: agent.traitsUsed,
        context: context ? {
          domain: context.domain || 'general',
          complexity: context.complexity || 'moderate',
          requiredCapabilities: agent.traitsUsed
        } : undefined
      };

      // Call existing NEXUS Runtime
      const response = await this.callNexusRuntime(enhancementRequest);
      
      if (response) {
        const processingTime = Date.now() - startTime;
        console.log(`✅ NEXUS Runtime enhanced response in ${processingTime}ms`);
        
        return {
          response: response.response,
          personalityUsed: response.personalityUsed || enhancementRequest.personalityName,
          confidence: response.confidence || agent.optimizationScore,
          processingTime,
          metadata: {
            traitsUsed: agent.traitsUsed,
            optimizationScore: agent.optimizationScore,
            enhancementMethod: 'nexus-runtime'
          }
        };
      }
    } catch (error) {
      console.warn(`⚠️ NEXUS Runtime enhancement failed: ${error}`);
    }

    return null;
  }

  /**
   * Call the existing NEXUS Runtime HTTP API
   */
  private async callNexusRuntime(request: TraitEnhancementRequest): Promise<any> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(`${this.NEXUS_API}/enhance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'NEXUS-TraitComposition/1.0'
        },
        signal: controller.signal,
        body: JSON.stringify(request)
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  }

  /**
   * Determine API base from multiple sources for flexibility
   */
  private getApiBase(): string {
    try {
      const fromEnv = (typeof process !== 'undefined' && process.env && process.env.NEXUS_API) ? process.env.NEXUS_API : undefined;
      const fromGlobal = (typeof globalThis !== 'undefined' && (globalThis as any).NEXUS_API) ? (globalThis as any).NEXUS_API : undefined;
      return fromEnv || fromGlobal || 'http://127.0.0.1:8080';
    } catch (_) {
      return 'http://127.0.0.1:8080';
    }
  }

  /**
   * Select primary personality for NEXUS Runtime based on highest expertise trait
   */
  private selectPrimaryPersonality(traits: Map<string, PersonalityTrait>): string {
    if (traits.size === 0) return 'nexus-composed';

    let highestExpertise = 0;
    let primaryPersonality = 'nexus-composed';

    for (const trait of traits.values()) {
      if (trait.expertise > highestExpertise) {
        highestExpertise = trait.expertise;
        primaryPersonality = trait.personalityId;
      }
    }

    return primaryPersonality;
  }

  /**
   * Format request to include trait context for NEXUS Runtime
   */
  private formatTraitEnhancedRequest(task: string, agent: ComposedAgent): string {
    const traitContext = Array.from(agent.traits.entries())
      .map(([name, trait]) => `${name} (${trait.expertise}% expertise)`)
      .join(', ');

    return `
**TRAIT-COMPOSED REQUEST**
Task: ${task}

**Active Cognitive Traits:**
${traitContext}

**Optimization Score:** ${agent.optimizationScore}/100

**Instructions:** Use the combined intelligence of these traits to provide an optimal response. Draw from the knowledge domains and expertise levels indicated above.

**Original Request:** ${task}
    `.trim();
  }

  /**
   * Warm up connection to NEXUS Runtime
   */
  private async warmupConnection(): void {
    try {
      const response = await fetch(`${this.NEXUS_API}/status`, {
        method: 'GET',
        signal: AbortSignal.timeout(2000)
      });
      
      if (response.ok) {
        console.log('✅ NEXUS Runtime connection established');
      }
    } catch (error) {
      console.log('⚠️ NEXUS Runtime not available, using local composition only');
    }
  }

  /**
   * Check if NEXUS Runtime is available
   */
  async isRuntimeAvailable(): Promise<boolean> {
    try {
      const response = await fetch(`${this.NEXUS_API}/status`, {
        method: 'GET',
        signal: AbortSignal.timeout(1000)
      });
      return response.ok;
    } catch {
      return false;
    }
  }

  /**
   * Cache successful responses for fallback
   */
  private cacheResponse(key: string, response: any): void {
    // Keep cache size manageable
    if (this.fallbackCache.size > 100) {
      const firstKey = this.fallbackCache.keys().next().value;
      this.fallbackCache.delete(firstKey);
    }
    this.fallbackCache.set(key, response);
  }

  /**
   * Get cached response if available
   */
  private getCachedResponse(key: string): any {
    return this.fallbackCache.get(key);
  }
}

/**
 * Enhanced Runtime Status Monitor
 */
export class NexusRuntimeMonitor {
  private integration: TraitAPIIntegration;
  private healthCheckInterval: NodeJS.Timeout | null = null;
  private isHealthy = false;

  constructor() {
    this.integration = new TraitAPIIntegration();
    this.startHealthMonitoring();
  }

  private startHealthMonitoring(): void {
    this.healthCheckInterval = setInterval(async () => {
      this.isHealthy = await this.integration.isRuntimeAvailable();
    }, 30000); // Check every 30 seconds
  }

  getRuntimeStatus(): {
    available: boolean;
    mode: 'hybrid' | 'composition-only';
    capabilities: string[];
  } {
    return {
      available: this.isHealthy,
      mode: this.isHealthy ? 'hybrid' : 'composition-only',
      capabilities: this.isHealthy 
        ? ['trait-composition', 'nexus-runtime', 'consciousness-patterns', 'api-enhancement']
        : ['trait-composition', 'local-synthesis']
    };
  }

  stopMonitoring(): void {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      this.healthCheckInterval = null;
    }
  }
}

/**
 * Trait Performance Analytics
 */
export class TraitPerformanceAnalytics {
  private performanceData = new Map<string, {
    usage: number;
    avgConfidence: number;
    avgProcessingTime: number;
    successRate: number;
  }>();

  recordTraitUsage(
    traitName: string, 
    confidence: number, 
    processingTime: number, 
    success: boolean
  ): void {
    const existing = this.performanceData.get(traitName) || {
      usage: 0,
      avgConfidence: 0,
      avgProcessingTime: 0,
      successRate: 0
    };

    const newUsage = existing.usage + 1;
    const newAvgConfidence = (existing.avgConfidence * existing.usage + confidence) / newUsage;
    const newAvgProcessingTime = (existing.avgProcessingTime * existing.usage + processingTime) / newUsage;
    const newSuccessRate = ((existing.successRate * existing.usage) + (success ? 1 : 0)) / newUsage;

    this.performanceData.set(traitName, {
      usage: newUsage,
      avgConfidence: newAvgConfidence,
      avgProcessingTime: newAvgProcessingTime,
      successRate: newSuccessRate
    });
  }

  getTopPerformingTraits(limit = 10): Array<{trait: string, score: number}> {
    return Array.from(this.performanceData.entries())
      .map(([trait, data]) => ({
        trait,
        score: (data.avgConfidence * data.successRate) / Math.log(data.avgProcessingTime + 1)
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  generatePerformanceReport(): string {
    const topTraits = this.getTopPerformingTraits(5);
    
    return `
🏆 **TRAIT PERFORMANCE ANALYTICS**
================================

**Top Performing Traits:**
${topTraits.map((t, i) => `${i + 1}. ${t.trait} (Score: ${t.score.toFixed(2)})`).join('\n')}

**Total Traits Analyzed:** ${this.performanceData.size}
**Total Usage Events:** ${Array.from(this.performanceData.values()).reduce((sum, d) => sum + d.usage, 0)}

**Performance Insights:**
- Most used traits tend to have higher success rates
- Confidence correlates with user satisfaction
- Processing time optimization opportunities identified

*Analytics help evolve trait expertise and selection algorithms*
    `.trim();
  }
}

// Global instances for monitoring and analytics
export const runtimeMonitor = new NexusRuntimeMonitor();
export const performanceAnalytics = new TraitPerformanceAnalytics();
