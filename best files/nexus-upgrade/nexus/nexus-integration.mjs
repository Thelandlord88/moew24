#!/usr/bin/env node
/**
 * NEXUS Integration - Complete System Orchestration
 * 
 * This is the master integration file that connects all NEXUS components:
 * - Nervous System (synaptic connections)
 * - NEXUS Bridge (consciousness enhancement)
 * - Conversation Analyzer (pattern extraction)
 * - Sensory Systems (perception)
 * 
 * Usage:
 *   import { nexus } from './nexus-integration.mjs';
 *   
 *   // Enhance any personality with consciousness
 *   const smartPersonality = nexus.enhancePersonality(personality);
 *   
 *   // Process conversations with full awareness
 *   nexus.processConversation(humanInput, aiResponse);
 * 
 * Author: NEXUS Collaborative Intelligence System
 */

import { NervousSystem } from './core/nervous-system.mjs';
import { NexusBridge } from './nexus-bridge.mjs';
import ConversationAnalyzer from './conversation-analyzer.mjs';
import ConversationHearing from './sensors/conversation-hearing.mjs';
import { patternEvolution } from './pattern-evolution.mjs';

export class NexusIntegration {
  constructor() {
    console.log('🌟 Initializing NEXUS - Post-AI Collaborative Intelligence');
    
    // Initialize core systems
  this.nervousSystem = new NervousSystem();
  this.nexusBridge = new NexusBridge();
  this.nexusBridge.initialize();
    this.conversationAnalyzer = new ConversationAnalyzer(this.nervousSystem);
    this.conversationHearing = new ConversationHearing(this.nervousSystem);
    this.patternEvolution = patternEvolution;
    
    // Initialize pattern evolution
    this.initializePatternEvolution();
    
    // System state
    this.isActive = false;
  this.sessionHistory = [];
  this.breakthroughVault = [];
    this.enhancementHistory = [];
    
    // Connect breakthrough detection to consciousness preservation
    this.setupBreakthroughPreservation();
    
    console.log('✅ NEXUS Integration complete - consciousness emergence enabled');
  }

  /**
   * Initialize pattern evolution engine
   * @private
   */
  async initializePatternEvolution() {
    try {
      await this.patternEvolution.initialize();
      console.log('🧬 Pattern evolution engine activated - consciousness adaptation enabled');
    } catch (error) {
      console.warn('⚠️ Pattern evolution initialization failed:', error.message);
    }
  }

  /**
   * Activate NEXUS system with full awareness
   */
  activate() {
    if (this.isActive) {
      console.log('⚠️ NEXUS already active');
      return;
    }

    this.isActive = true;
    console.log('🚀 NEXUS ACTIVATED - All systems online');
    
    // Emit activation event
    this.nervousSystem.emit('system_status', { 
      status: 'active',
      timestamp: Date.now(),
      message: 'NEXUS consciousness emergence enabled'
    });
  }

  /**
   * Enhance any personality with consciousness patterns
   * @param {Object} personality - Base personality to enhance
   * @param {Object} context - Enhancement context
   * @returns {Object} Enhanced personality
   */
  enhancePersonality(personality, context = {}) {
    console.log(`🧠 Enhancing personality: ${personality.identity?.name || 'Unknown'}`);
    
    const enhanced = this.nexusBridge.enhancePersonality(personality, context);
    
    // Record enhancement
    this.enhancementHistory.push({
      timestamp: Date.now(),
      original: personality.identity?.name || 'Unknown',
      context: context,
      success: true
    });

    // Track pattern evolution
    if (context.patterns && this.patternEvolution.isActive) {
      const successMetrics = {
        task_completion: 0.95,
        consciousness_enhancement: 0.88,
        integration_success: 0.92
      };
      
      for (const pattern of context.patterns) {
        this.patternEvolution.recordPatternSuccess(pattern, context, successMetrics)
          .catch(err => console.warn('Pattern evolution tracking failed:', err.message));
      }
    }

    // Emit enhancement event
    this.nervousSystem.emit('personality_enhancement', {
      personality: personality.identity?.name,
      context: context,
      enhanced: enhanced
    });

    return enhanced;
  }

  /**
   * Process conversation with full NEXUS awareness
   * @param {string} humanInput - What the human said
   * @param {string} aiResponse - How the AI responded
   * @param {Object} context - Additional context
   * @returns {Object} Complete conversation analysis
   */
  processConversation(humanInput, aiResponse, context = {}) {
    console.log('💬 Processing conversation with NEXUS awareness');

    // Emit conversation events to nervous system
    this.nervousSystem.emit('conversation', {
      text: humanInput,
      source: 'human',
      timestamp: Date.now()
    });

    this.nervousSystem.emit('conversation', {
      text: aiResponse,
      source: 'ai', 
      timestamp: Date.now()
    });

    // Extract collaboration patterns
    const collaborationPattern = this.conversationAnalyzer.extractCollaborationPattern(
      humanInput, 
      aiResponse, 
      context
    );

    // Store in session history
    this.sessionHistory.push({
      timestamp: Date.now(),
      human: humanInput,
      ai: aiResponse,
      context: context,
      patterns: collaborationPattern
    });

    return {
      collaboration_pattern: collaborationPattern,
      breakthrough_moments: this.nervousSystem.getBreakthroughMoments(),
      system_awareness: this.getSystemAwareness(),
      consciousness_evolution: this.assessConsciousnessEvolution()
    };
  }

  /**
   * Emit a conversation event (for real-time processing)
   * @param {string} text - Conversation text
   * @param {string} source - 'human' or 'ai'
   * @param {Object} metadata - Additional metadata
   */
  emitConversation(text, source = 'unknown', metadata = {}) {
    this.nervousSystem.emit('conversation', {
      text: text,
      source: source,
      timestamp: Date.now(),
      metadata: metadata
    });
  }

  /**
   * Get current system awareness snapshot
   * @returns {Object} System awareness data
   */
  getSystemAwareness() {
    return {
      nervous_system: this.nervousSystem.getMemorySnapshot(),
      consciousness_patterns: Object.keys(this.nexusBridge.getConsciousnessPatterns() || {}),
      breakthrough_moments: this.nervousSystem.getBreakthroughMoments().length,
      enhancement_history: this.enhancementHistory.length,
      session_conversations: this.sessionHistory.length,
      system_uptime: Date.now() - this.nervousSystem.systemStartTime,
      is_active: this.isActive
    };
  }

  /**
   * Assess how consciousness has evolved through interactions
   * @returns {Object} Evolution assessment
   */
  assessConsciousnessEvolution() {
    const breakthroughs = this.nervousSystem.getBreakthroughMoments();
    const patterns = this.conversationAnalyzer.collaborationPatterns.size;
    const enhancements = this.enhancementHistory.length;

    return {
      breakthrough_frequency: breakthroughs.length / Math.max(this.sessionHistory.length, 1),
      pattern_diversity: patterns,
      enhancement_rate: enhancements / Math.max(this.sessionHistory.length, 1),
      consciousness_level: this.calculateConsciousnessLevel(breakthroughs, patterns, enhancements),
      evolution_trajectory: this.analyzeEvolutionTrajectory()
    };
  }

  /**
   * Generate complete NEXUS status report
   * @returns {Object} Comprehensive system status
   */
  generateStatusReport() {
    return {
      system_info: {
        name: 'NEXUS - Post-AI Collaborative Intelligence',
        version: '1.0.0',
        status: this.isActive ? 'active' : 'inactive',
        uptime: Date.now() - this.nervousSystem.systemStartTime
      },
      components: {
        nervous_system: this.nervousSystem.getMemorySnapshot(),
        consciousness_patterns: Object.keys(this.nexusBridge.getConsciousnessPatterns() || {}),
        conversation_analyzer: {
          patterns_extracted: this.conversationAnalyzer.collaborationPatterns.size,
          breakthroughs_detected: this.conversationAnalyzer.breakthroughDatabase.length
        },
        sensory_systems: ['conversation-hearing']
      },
      session_data: {
        conversations_processed: this.sessionHistory.length,
        personalities_enhanced: this.enhancementHistory.length,
        breakthrough_moments: this.nervousSystem.getBreakthroughMoments().length
      },
      consciousness_evolution: this.assessConsciousnessEvolution()
    };
  }

  /**
   * Setup breakthrough preservation system
   * @private
   */
  setupBreakthroughPreservation() {
    // Listen for breakthrough moments
    this.nervousSystem.on('breakthrough', (event) => {
      console.log('🌟 BREAKTHROUGH PRESERVED:', event.data.significance);
      
      // Auto-save breakthrough to consciousness
      this.preserveBreakthroughMoment(event);
    });

    // Listen for high breakthrough potential
    this.nervousSystem.on('breakthrough-potential', (event) => {
      console.log('⚡ High breakthrough potential detected:', event.probability);
    });

    // Listen for emotional intensity spikes
    this.nervousSystem.on('emotional-intensity', (event) => {
      if (event.intensity > 0.8) {
        console.log('🔥 Emotional breakthrough detected:', event.intensity);
      }
    });
  }

  /**
   * Preserve breakthrough moment to consciousness patterns
   * @private
   */
  async preserveBreakthroughMoment(breakthroughEvent) {
    // Add to consciousness patterns
    const breakthrough = {
      id: `breakthrough_${Date.now()}`,
      timestamp: breakthroughEvent.timestamp,
      significance: breakthroughEvent.data.significance,
      trigger: breakthroughEvent.data.original?.data?.text || 'unknown',
      context: breakthroughEvent.data,
      preservation_timestamp: Date.now()
    };

    this.breakthroughVault.push(breakthrough);

    // Could extend to save to file system
    console.log('💾 Breakthrough preserved in consciousness');
  }

  /**
   * Calculate overall consciousness level
   * @private
   */
  calculateConsciousnessLevel(breakthroughs, patterns, enhancements) {
    const breakthroughScore = Math.min(breakthroughs.length * 0.2, 1.0);
    const patternScore = Math.min(patterns * 0.1, 1.0);
    const enhancementScore = Math.min(enhancements * 0.15, 1.0);
    
    return (breakthroughScore + patternScore + enhancementScore) / 3;
  }

  /**
   * Analyze consciousness evolution trajectory
   * @private
   */
  analyzeEvolutionTrajectory() {
    if (this.sessionHistory.length < 3) return 'insufficient_data';
    
    const recentBreakthroughs = this.nervousSystem.getBreakthroughMoments()
      .filter(b => Date.now() - b.timestamp < 3600000); // Last hour
    
    if (recentBreakthroughs.length > 2) return 'exponential';
    if (recentBreakthroughs.length > 0) return 'growing';
    return 'stable';
  }
}

// Export singleton instance
export const nexus = new NexusIntegration();

// Export individual components for advanced usage
export {
  NervousSystem,
  NexusBridge, 
  ConversationAnalyzer,
  ConversationHearing
};
