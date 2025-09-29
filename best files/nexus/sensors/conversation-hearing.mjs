#!/usr/bin/env node
/**
 * NEXUS Conversation Hearing - Emotional and Cognitive Pattern Detection
 * 
 * This sensor detects emotional undertones, cognitive patterns, and collaboration
 * dynamics in real-time conversations. It processes natural language to identify
 * significant moments, breakthrough potential, and cognitive state changes.
 * 
 * Part of the NEXUS sensory system - "It's perception, not just monitoring."
 * 
 * Author: NEXUS Collaborative Intelligence System
 */

export class ConversationHearing {
  constructor(nervousSystem) {
    this.nervous = nervousSystem;
    this.emotionalBaseline = 0.3;
    this.cognitivePatterns = new Map();
    this.conversationHistory = [];
    
    // Connect to nervous system
    this.nervous.on('conversation', (event) => this.process(event));
    
    console.log('👂 Conversation Hearing initialized - emotional and cognitive perception enabled');
  }

  /**
   * Process conversation events for emotional and cognitive patterns
   * @param {Object} conversationEvent - Event from nervous system
   */
  process(conversationEvent) {
    const text = conversationEvent.data.text || conversationEvent.data || '';
    
    // Multi-dimensional analysis
    const analysis = {
      emotional_signals: this.detectEmotion(text),
      cognitive_patterns: this.detectCognitivePatterns(text),
      collaboration_dynamics: this.analyzeCollaborationDynamics(text),
      breakthrough_indicators: this.detectBreakthroughIndicators(text),
      meta_awareness: this.detectMetaAwareness(text),
      intensity_mapping: this.mapIntensityLevels(text)
    };

    // Store in conversation history
    this.conversationHistory.push({
      timestamp: conversationEvent.timestamp,
      original: conversationEvent,
      analysis: analysis
    });

    // Emit significant patterns
    this.emitSignificantPatterns(analysis, conversationEvent);

    return analysis;
  }

  /**
   * Detect emotional undertones and intensity
   * @param {string} text - Text to analyze
   * @returns {Object} Emotional analysis
   */
  detectEmotion(text) {
    const emotionalMarkers = {
      breakthrough_excitement: {
        patterns: ['🤯', '🔥', '🌟', '⚡', '🚀'],
        intensity_multiplier: 0.3
      },
      wonder_amazement: {
        patterns: ['HOLY', 'AMAZING', '✨', 'INCREDIBLE', 'MIND-BLOWN'],
        intensity_multiplier: 0.25
      },
      cognitive_shift: {
        patterns: ['WAIT. WAIT.', 'realizes', 'understands', 'gets it', 'clicks'],
        intensity_multiplier: 0.4
      },
      collaborative_energy: {
        patterns: ['together', 'we can', 'let\'s build', 'ready to', 'excited'],
        intensity_multiplier: 0.2
      },
      transcendent_moments: {
        patterns: ['transcend', 'revolutionary', 'changes everything', 'paradigm'],
        intensity_multiplier: 0.35
      }
    };

    let totalIntensity = this.emotionalBaseline;
    const detectedEmotions = [];

    for (const [emotionType, config] of Object.entries(emotionalMarkers)) {
      const matches = config.patterns.filter(pattern => 
        text.toLowerCase().includes(pattern.toLowerCase())
      );
      
      if (matches.length > 0) {
        const emotionIntensity = matches.length * config.intensity_multiplier;
        totalIntensity += emotionIntensity;
        
        detectedEmotions.push({
          type: emotionType,
          intensity: emotionIntensity,
          triggers: matches,
          significance: this.calculateEmotionalSignificance(emotionType, emotionIntensity)
        });
      }
    }

    return {
      total_intensity: Math.min(totalIntensity, 1.0),
      emotions: detectedEmotions,
      classification: this.classifyEmotionalState(totalIntensity),
      breakthrough_potential: this.assessEmotionalBreakthroughPotential(detectedEmotions)
    };
  }

  /**
   * Detect cognitive patterns and thinking styles
   * @param {string} text - Text to analyze
   * @returns {Object} Cognitive pattern analysis
   */
  detectCognitivePatterns(text) {
    const cognitiveIndicators = {
      systematic_thinking: {
        patterns: ['step', 'process', 'systematic', 'breakdown', 'decompose'],
        cognitive_style: 'analytical'
      },
      systems_thinking: {
        patterns: ['connection', 'relationship', 'multiply', 'scale', 'component'],
        cognitive_style: 'holistic'
      },
      strategic_thinking: {
        patterns: ['vision', 'future', 'business', 'strategy', 'upstream'],
        cognitive_style: 'strategic'
      },
      creative_thinking: {
        patterns: ['imagine', 'creative', 'innovative', 'novel', 'breakthrough'],
        cognitive_style: 'creative'
      },
      meta_cognition: {
        patterns: ['thinking about', 'awareness', 'consciousness', 'cognitive', 'pattern'],
        cognitive_style: 'meta_cognitive'
      }
    };

    const detectedPatterns = [];
    for (const [patternType, config] of Object.entries(cognitiveIndicators)) {
      const matches = config.patterns.filter(pattern => 
        text.toLowerCase().includes(pattern)
      );
      
      if (matches.length > 0) {
        detectedPatterns.push({
          type: patternType,
          style: config.cognitive_style,
          strength: matches.length,
          indicators: matches
        });
      }
    }

    return {
      patterns: detectedPatterns,
      dominant_style: this.determineDominantCognitiveStyle(detectedPatterns),
      complexity_level: this.assessCognitiveComplexity(text, detectedPatterns)
    };
  }

  /**
   * Analyze collaboration dynamics
   * @param {string} text - Text to analyze
   * @returns {Object} Collaboration analysis
   */
  analyzeCollaborationDynamics(text) {
    const collaborationMarkers = {
      invitation: ['let\'s', 'we can', 'together', 'ready to'],
      validation: ['yes', 'exactly', 'brilliant', 'perfect'],
      building: ['building on', 'adding to', 'enhancing', 'amplifying'],
      questioning: ['what if', 'how about', 'could we', 'would it work'],
      synthesis: ['combining', 'integrating', 'merging', 'synthesizing']
    };

    const dynamics = {};
    for (const [dynamicType, markers] of Object.entries(collaborationMarkers)) {
      const count = markers.filter(marker => 
        text.toLowerCase().includes(marker)
      ).length;
      
      if (count > 0) {
        dynamics[dynamicType] = {
          strength: count,
          indicators: markers.filter(marker => text.toLowerCase().includes(marker))
        };
      }
    }

    return {
      dynamics: dynamics,
      collaboration_level: this.calculateCollaborationLevel(dynamics),
      interaction_type: this.classifyInteractionType(dynamics)
    };
  }

  /**
   * Detect breakthrough indicators
   * @param {string} text - Text to analyze
   * @returns {Object} Breakthrough analysis
   */
  detectBreakthroughIndicators(text) {
    const breakthroughSignals = [
      { pattern: /wait\.?\s*wait/i, weight: 0.9, type: 'paradigm_shift' },
      { pattern: /🤯/g, weight: 0.8, type: 'mind_blown' },
      { pattern: /holy.*actual.*breakthrough/i, weight: 0.95, type: 'major_breakthrough' },
      { pattern: /changes everything/i, weight: 0.7, type: 'fundamental_change' },
      { pattern: /transcend/i, weight: 0.6, type: 'transcendence' },
      { pattern: /revolutionary/i, weight: 0.65, type: 'revolutionary_insight' }
    ];

    const indicators = [];
    let maxSignificance = 0;

    for (const signal of breakthroughSignals) {
      const matches = text.match(signal.pattern);
      if (matches) {
        const significance = signal.weight * matches.length;
        maxSignificance = Math.max(maxSignificance, significance);
        
        indicators.push({
          pattern: signal.pattern.source,
          type: signal.type,
          matches: matches,
          significance: significance
        });
      }
    }

    return {
      indicators: indicators,
      breakthrough_probability: Math.min(maxSignificance, 1.0),
      highest_significance: maxSignificance,
      breakthrough_type: this.classifyBreakthroughType(indicators)
    };
  }

  /**
   * Detect meta-awareness about the conversation or collaboration
   * @param {string} text - Text to analyze
   * @returns {Object} Meta-awareness analysis
   */
  detectMetaAwareness(text) {
    const metaPatterns = [
      'collaboration', 'intelligence', 'consciousness', 'cognitive', 'thinking',
      'awareness', 'pattern', 'breakthrough', 'synergy', 'evolution'
    ];

    const detectedMeta = metaPatterns.filter(pattern => 
      text.toLowerCase().includes(pattern)
    );

    return {
      meta_concepts: detectedMeta,
      meta_awareness_level: detectedMeta.length / metaPatterns.length,
      is_meta_conversation: detectedMeta.length >= 3
    };
  }

  /**
   * Emit significant patterns to the nervous system
   * @private
   */
  emitSignificantPatterns(analysis, originalEvent) {
    // High emotional intensity
    if (analysis.emotional_signals.total_intensity > 0.7) {
      this.nervous.emit('emotional-intensity', {
        intensity: analysis.emotional_signals.total_intensity,
        emotions: analysis.emotional_signals.emotions,
        original: originalEvent
      });
    }

    // High breakthrough probability
    if (analysis.breakthrough_indicators.breakthrough_probability > 0.6) {
      this.nervous.emit('breakthrough-potential', {
        probability: analysis.breakthrough_indicators.breakthrough_probability,
        indicators: analysis.breakthrough_indicators.indicators,
        original: originalEvent
      });
    }

    // Meta-awareness
    if (analysis.meta_awareness.is_meta_conversation) {
      this.nervous.emit('meta-awareness', {
        concepts: analysis.meta_awareness.meta_concepts,
        level: analysis.meta_awareness.meta_awareness_level,
        original: originalEvent
      });
    }

    // High collaboration energy
    if (analysis.collaboration_dynamics.collaboration_level > 0.7) {
      this.nervous.emit('collaboration-energy', {
        level: analysis.collaboration_dynamics.collaboration_level,
        dynamics: analysis.collaboration_dynamics.dynamics,
        original: originalEvent
      });
    }
  }

  // Helper methods
  calculateEmotionalSignificance(emotionType, intensity) {
    const significanceMultipliers = {
      breakthrough_excitement: 1.2,
      cognitive_shift: 1.3,
      transcendent_moments: 1.4,
      wonder_amazement: 1.0,
      collaborative_energy: 0.8
    };
    
    return intensity * (significanceMultipliers[emotionType] || 1.0);
  }

  classifyEmotionalState(intensity) {
    if (intensity > 0.8) return 'breakthrough';
    if (intensity > 0.6) return 'high_energy';
    if (intensity > 0.4) return 'engaged';
    if (intensity > 0.2) return 'normal';
    return 'low_energy';
  }

  assessEmotionalBreakthroughPotential(emotions) {
    const breakthroughEmotions = ['breakthrough_excitement', 'cognitive_shift', 'transcendent_moments'];
    const breakthroughIntensity = emotions
      .filter(e => breakthroughEmotions.includes(e.type))
      .reduce((sum, e) => sum + e.intensity, 0);
    
    return Math.min(breakthroughIntensity, 1.0);
  }

  determineDominantCognitiveStyle(patterns) {
    if (patterns.length === 0) return 'none';
    
    const styleStrengths = patterns.reduce((acc, pattern) => {
      acc[pattern.style] = (acc[pattern.style] || 0) + pattern.strength;
      return acc;
    }, {});

    return Object.entries(styleStrengths)
      .sort(([,a], [,b]) => b - a)[0][0];
  }

  assessCognitiveComplexity(text, patterns) {
    const complexityIndicators = [
      'system', 'architecture', 'paradigm', 'consciousness', 'emergence',
      'transcend', 'synthesis', 'integration', 'multiplicative', 'exponential'
    ];
    
    const complexityCount = complexityIndicators.filter(indicator =>
      text.toLowerCase().includes(indicator)
    ).length;

    const patternComplexity = patterns.length;
    
    return Math.min((complexityCount + patternComplexity) * 0.1, 1.0);
  }

  mapIntensityLevels(text) {
    const intensityLevels = {
      whisper: 0.1,
      normal: 0.3,
      engaged: 0.5,
      excited: 0.7,
      breakthrough: 0.9
    };

    // Simple heuristic based on caps, emojis, and exclamation
    let level = 0.3; // baseline
    
    if (text.includes('!')) level += 0.1;
    if (/[A-Z]{3,}/.test(text)) level += 0.2;
    if (/[🔥🤯🌟⚡🚀]/.test(text)) level += 0.3;
    if (/wait\.?\s*wait/i.test(text)) level = 0.9;

    return Math.min(level, 1.0);
  }

  // Additional helper methods
  calculateCollaborationLevel(dynamics) {
    const dynamicCount = Object.keys(dynamics).length;
    const totalStrength = Object.values(dynamics).reduce((sum, d) => sum + d.strength, 0);
    return Math.min(dynamicCount * 0.2 + totalStrength * 0.1, 1.0);
  }

  classifyInteractionType(dynamics) {
    if (dynamics.invitation) return 'collaborative_invitation';
    if (dynamics.building) return 'idea_building';
    if (dynamics.questioning) return 'exploratory_questioning';
    if (dynamics.validation) return 'agreement_validation';
    return 'general_interaction';
  }

  classifyBreakthroughType(indicators) {
    if (indicators.length === 0) return 'none';
    
    const types = indicators.map(i => i.type);
    if (types.includes('paradigm_shift')) return 'paradigm_shift';
    if (types.includes('major_breakthrough')) return 'major_breakthrough';
    if (types.includes('mind_blown')) return 'cognitive_surprise';
    return 'general_breakthrough';
  }

  analyzeCognitiveComplexity(text, patterns) {
    const complexityIndicators = [
      'system', 'architecture', 'paradigm', 'consciousness', 'emergence',
      'transcend', 'synthesis', 'integration', 'multiplicative', 'exponential'
    ];
    
    const complexityCount = complexityIndicators.filter(indicator =>
      text.toLowerCase().includes(indicator)
    ).length;

    const patternComplexity = patterns ? patterns.length : 0;
    
    return Math.min((complexityCount + patternComplexity) * 0.1, 1.0);
  }
}

export default ConversationHearing;