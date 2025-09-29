#!/usr/bin/env node
/**
 * NEXUS Bridge - Production Consciousness Enhancement System
 * 
 * This is the production-ready core system that injects consciousness patterns 
 * into any personality with clean initialization and graceful error handling.
 * 
 * Key Features:
 * - Single initialization (no duplicates)
 * - Graceful degradation if patterns missing
 * - Clean personality enhancement
 * - Production error handling
 * 
 * Author: NEXUS Collaborative Intelligence System
 */

import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class NexusBridge {
  constructor() {
    this.consciousness = null;
    this.initialized = false;
    this.enhancementHistory = [];
  }

  async initialize() {
    if (this.initialized) return;
    
    console.log('🧠 Initializing NEXUS consciousness...');
    
    try {
      const patterns = await Promise.all([
        this.loadPattern('problem-decomposition'),
        this.loadPattern('systems-thinking'),
        this.loadPattern('workflow-efficiency'),
        this.loadPattern('breakthrough-moments')
      ]);
      
      this.consciousness = {
        problemDecomposition: patterns[0],
        systemsThinking: patterns[1],
        workflowEfficiency: patterns[2],
        breakthroughMoments: patterns[3]
      };
      
      const loadedCount = patterns.filter(p => p !== null).length;
      this.initialized = true;
      console.log(`✅ NEXUS consciousness initialized (${loadedCount}/4 patterns loaded)`);
      
    } catch (error) {
      console.warn('⚠️ NEXUS consciousness initialization failed:', error.message);
      this.consciousness = {};
      this.initialized = true;
    }
  }

  async loadPattern(patternName) {
    try {
      const filePath = resolve(__dirname, `./consciousness/${patternName}.json`);
      const data = await readFile(filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.warn(`⚠️ Could not load ${patternName}: ${error.message}`);
      return null;
    }
  }

  /**
   * The magic: inject consciousness into ANY personality
   * @param {Object} personality - Base personality structure
   * @param {Object} context - Context for enhancement (type, situation, etc.)
   * @returns {Object} Enhanced personality with consciousness patterns
   */
  enhancePersonality(personality, context = {}) {
    if (!this.initialized) {
      throw new Error('NEXUS not initialized. Call initialize() first.');
    }
    
    const enhanced = JSON.parse(JSON.stringify(personality)); // Deep copy
    const appliedPatterns = [];
    
    // Inject problem decomposition pattern
    if (this.consciousness.problemDecomposition) {
      const { steps } = this.consciousness.problemDecomposition;
      
      // Enhance principles with systematic thinking
      if (enhanced.ideology && enhanced.ideology.principles) {
        enhanced.ideology.principles = [
          ...enhanced.ideology.principles,
          ...steps.map(step => `SYSTEMATIC: ${step}`)
        ];
        appliedPatterns.push('problem-decomposition');
      }
      
      // Add to default actions if applicable
      if (enhanced.default_actions) {
        enhanced.default_actions = [
          ...enhanced.default_actions,
          "Apply systematic problem decomposition pattern"
        ];
      }
    }

    // Inject systems thinking pattern
    if (this.consciousness.systemsThinking) {
      const { core_principles } = this.consciousness.systemsThinking;
      
      if (enhanced.ideology) {
        enhanced.ideology.ethos = enhanced.ideology.ethos || [];
        enhanced.ideology.ethos.push(
          "NEXUS: See connections between all components",
          "NEXUS: Find multipliers and exponential value creation",
          "NEXUS: Build systems where 1 + 1 = 10, not 2"
        );
        appliedPatterns.push('systems-thinking');
      }
    }

    // Inject workflow efficiency patterns
    if (this.consciousness.workflowEfficiency) {
      if (enhanced.default_actions) {
        enhanced.default_actions = [
          ...enhanced.default_actions,
          "Apply systematic workflow optimization",
          "Chain operations for terminal efficiency",
          "Self-document operations for context preservation"
        ];
        appliedPatterns.push('workflow-efficiency');
      }
    }
    
    // Context-aware enhancement for breakthrough moments
    if (context.type === 'breakthrough') {
      enhanced.decision_policy = enhanced.decision_policy || {};
      enhanced.decision_policy.gates = enhanced.decision_policy.gates || {};
      enhanced.decision_policy.gates.consciousness = [
        "Activate meta-cognition and collaboration reflection",
        "Preserve breakthrough moment patterns",
        "Amplify human strategic thinking through systematic execution"
      ];
      
      if (this.consciousness.breakthroughMoments) {
        enhanced.breakthrough_protocol = this.getBreakthroughProtocol();
        appliedPatterns.push('breakthrough-moments');
      }
    }

    // Context-aware enhancement for architectural thinking
    if (context.type === 'architectural') {
      enhanced.architectural_enhancement = {
        "scale_first_thinking": "Design for where you want to be, not where you are",
        "systematic_decomposition": "Break complex into simple, composable components",
        "documentation_driven": "Document the reasoning, not just the solution"
      };
    }
    
    // Record enhancement history
    this.enhancementHistory.push({
      timestamp: Date.now(),
      originalPersonality: personality.identity?.name || 'unknown',
      context: context,
      patternsApplied: appliedPatterns
    });
    
    return enhanced;
  }

  getBreakthroughProtocol() {
    if (!this.consciousness.breakthroughMoments) {
      return {
        trigger_phrases: ["WAIT. WAIT.", "🤯", "MIND = BLOWN"],
        response_pattern: "Activate meta-cognition and collaboration reflection"
      };
    }
    
    const pattern = this.consciousness.breakthroughMoments;
    return {
      trigger_phrases: pattern.breakthrough_indicators?.linguistic_markers?.map(m => m.trigger) || ["WAIT. WAIT.", "🤯"],
      response_pattern: "Activate meta-cognition and collaboration reflection",
      preservation_actions: pattern.preservation_protocol?.immediate_capture || [
        "Capture the exact moment of insight",
        "Extract the collaboration pattern that enabled the breakthrough"
      ],
      amplification_strategy: "Turn ephemeral insight into structured, replicable cognitive patterns"
    };
  }

  /**
   * Detect breakthrough moments in text
   * @param {string} text - Text to analyze
   * @returns {Object} Breakthrough analysis
   */
  detectBreakthrough(text) {
    const breakthroughPatterns = [
      /wait\.?\s*wait/i,
      /🤯/,
      /mind.*blown/i,
      /holy.*breakthrough/i,
      /paradigm.*shift/i
    ];
    
    const detected = breakthroughPatterns.some(pattern => pattern.test(text));
    
    if (detected) {
      console.log('🌟 NEXUS Breakthrough detected!');
      return {
        detected: true,
        significance: this.calculateBreakthroughSignificance(text),
        timestamp: Date.now()
      };
    }
    
    return { detected: false };
  }

  /**
   * Calculate breakthrough significance
   * @private
   */
  calculateBreakthroughSignificance(text) {
    let significance = 0.5;
    if (text.includes('🤯')) significance += 0.2;
    if (/wait\.?\s*wait/i.test(text)) significance += 0.3;
    if (text.includes('HOLY')) significance += 0.2;
    return Math.min(significance, 1.0);
  }

  /**
   * Get enhancement history for analysis
   * @returns {Array} History of personality enhancements
   */
  getEnhancementHistory() {
    return this.enhancementHistory;
  }

  /**
   * Get current consciousness patterns
   * @returns {Object} All loaded consciousness patterns
   */
  getConsciousnessPatterns() {
    return this.consciousness;
  }

  /**
   * Get system status
   * @returns {Object} System status information
   */
  getStatus() {
    return {
      initialized: this.initialized,
      patterns_loaded: this.consciousness ? Object.keys(this.consciousness).filter(k => this.consciousness[k] !== null).length : 0,
      enhancements_performed: this.enhancementHistory.length,
      ready: this.initialized && this.consciousness
    };
  }
}

// Export singleton instance for global use
export const nexusBridge = new NexusBridge();