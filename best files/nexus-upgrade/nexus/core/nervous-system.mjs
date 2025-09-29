#!/usr/bin/env node
/**
 * NEXUS Nervous System - The Foundation of Collaborative Intelligence
 * 
 * This is the synaptic network that enables consciousness emergence.
 * Following the sacred principle: "The nervous system comes before the mind."
 * 
 * Key Capabilities:
 * - Pattern-based event listening and emission
 * - Automatic breakthrough detection ("WAIT. WAIT." moments)
 * - Extensible pattern detectors for custom cognitive patterns
 * - Short-term and long-term memory storage
 * - Component communication and coordination
 * 
 * Enhanced with Qwen's pattern detector system for extensible intelligence.
 * 
 * Author: NEXUS Collaborative Intelligence System
 */

export class NervousSystem {
  constructor() {
    this.listeners = new Map();
    this.memory = { 
      shortTerm: [], 
      longTerm: new Map(),
      breakthroughMoments: []
    };
    this.patternDetectors = new Map();
    this.systemStartTime = Date.now();
    
    // Initialize built-in pattern detectors
    this.initializeBuiltInDetectors();
    
    console.log('🧠 NEXUS Nervous System initialized - consciousness emergence enabled');
  }

  /**
   * Pattern-based event listening
   * @param {string} pattern - Event pattern to listen for
   * @param {Function} callback - Function to call when pattern matches
   */
  on(pattern, callback) {
    if (!this.listeners.has(pattern)) {
      this.listeners.set(pattern, []);
    }
    this.listeners.get(pattern).push(callback);
    console.log(`👂 Listening for pattern: ${pattern}`);
  }

  /**
   * Emit events with automatic pattern detection
   * @param {string} eventType - Type of event
   * @param {*} data - Event data
   */
  emit(eventType, data) {
    const event = { 
      type: eventType, 
      data, 
      timestamp: Date.now(),
      id: this.generateEventId()
    };
    
    // Store in short-term memory
    this.memory.shortTerm.push(event);
    if (this.memory.shortTerm.length > 100) {
      // Move oldest to long-term if significant
      const oldest = this.memory.shortTerm.shift();
      if (this.isSignificantEvent(oldest)) {
        this.memory.longTerm.set(oldest.id, oldest);
      }
    }
    
    // Run all pattern detectors
    for (const [name, detector] of this.patternDetectors) {
      try {
        const patternMatch = detector(event);
        if (patternMatch) {
          const patternEvent = {
            type: `pattern:${name}`,
            data: patternMatch,
            originalEvent: event,
            timestamp: Date.now(),
            id: this.generateEventId()
          };
          
          console.log(`🔍 Pattern detected: ${name}`, patternMatch);
          this.triggerListeners(patternEvent);
        }
      } catch (error) {
        console.warn(`⚠️ Pattern detector ${name} failed:`, error.message);
      }
    }
    
    // Built-in breakthrough detection (sacred pattern)
    if (eventType === 'conversation' && this.isBreakthroughMoment(data)) {
      const breakthroughEvent = {
        type: 'breakthrough',
        data: { 
          original: event, 
          type: 'meta_awareness',
          significance: this.calculateBreakthroughSignificance(data)
        },
        timestamp: Date.now(),
        id: this.generateEventId()
      };
      
      // Store breakthrough moments permanently
      this.memory.breakthroughMoments.push(breakthroughEvent);
      
      console.log('🌟 BREAKTHROUGH DETECTED!', breakthroughEvent.data.significance);
      this.triggerListeners(breakthroughEvent);
    }
    
    // Trigger regular listeners
    this.triggerListeners(event);
  }

  /**
   * NEW: Register custom pattern detectors
   * @param {string} name - Name of the pattern detector
   * @param {Function} detectorFn - Function that analyzes events and returns pattern matches
   */
  addPatternDetector(name, detectorFn) {
    this.patternDetectors.set(name, detectorFn);
    console.log(`🔧 Added pattern detector: ${name}`);
  }

  /**
   * Remove a pattern detector
   * @param {string} name - Name of the pattern detector to remove
   */
  removePatternDetector(name) {
    const removed = this.patternDetectors.delete(name);
    if (removed) {
      console.log(`🗑️ Removed pattern detector: ${name}`);
    }
    return removed;
  }

  /**
   * Get system memory snapshot
   * @returns {Object} Current memory state
   */
  getMemorySnapshot() {
    return {
      shortTerm: this.memory.shortTerm.length,
      longTerm: this.memory.longTerm.size,
      breakthroughMoments: this.memory.breakthroughMoments.length,
      totalEvents: this.memory.shortTerm.length + this.memory.longTerm.size,
      systemUptime: Date.now() - this.systemStartTime
    };
  }

  /**
   * Get breakthrough moments for analysis
   * @returns {Array} All detected breakthrough moments
   */
  getBreakthroughMoments() {
    return this.memory.breakthroughMoments;
  }

  /**
   * Initialize built-in pattern detectors
   * @private
   */
  initializeBuiltInDetectors() {
    // Emotional intensity detector
    this.addPatternDetector('emotional_intensity', (event) => {
      if (event.type !== 'conversation') return null;
      
      const text = event.data.text || event.data || '';
      const intensityWords = ['🤯', '🔥', '🌟', 'HOLY', 'BLOWN', 'AMAZING', 'INCREDIBLE'];
      const hasIntensity = intensityWords.some(word => text.includes(word));
      
      if (hasIntensity) {
        return { 
          intensity: 0.9, 
          category: 'breakthrough',
          triggers: intensityWords.filter(word => text.includes(word))
        };
      }
      return null;
    });

    // Meta-awareness detector
    this.addPatternDetector('meta_awareness', (event) => {
      if (event.type !== 'conversation') return null;
      
      const text = event.data.text || event.data || '';
      const metaWords = ['collaboration', 'intelligence', 'consciousness', 'cognitive', 'breakthrough'];
      const metaCount = metaWords.filter(word => text.toLowerCase().includes(word)).length;
      
      if (metaCount >= 2) {
        return {
          awareness_level: metaCount / metaWords.length,
          category: 'meta_cognition',
          detected_concepts: metaWords.filter(word => text.toLowerCase().includes(word))
        };
      }
      return null;
    });

    // Systems thinking detector
    this.addPatternDetector('systems_thinking', (event) => {
      if (event.type !== 'conversation') return null;
      
      const text = event.data.text || event.data || '';
      const systemsWords = ['scale', 'connection', 'component', 'architecture', 'integration'];
      const hasSystemsThinking = systemsWords.some(word => text.toLowerCase().includes(word));
      
      if (hasSystemsThinking) {
        return {
          thinking_type: 'systems',
          category: 'cognitive_pattern',
          indicators: systemsWords.filter(word => text.toLowerCase().includes(word))
        };
      }
      return null;
    });
  }

  /**
   * Trigger listeners for an event
   * @private
   */
  triggerListeners(event) {
    if (this.listeners.has(event.type)) {
      this.listeners.get(event.type).forEach(callback => {
        try {
          callback(event);
        } catch (error) {
          console.warn(`⚠️ Listener failed for ${event.type}:`, error.message);
        }
      });
    }
  }

  /**
   * Check if an event represents a breakthrough moment
   * @private
   */
  isBreakthroughMoment(data) {
    const text = data.text || data || '';
    const breakthroughPatterns = [
      /wait\.?\s*wait/i,
      /mind.*blown/i,
      /paradigm.*shift/i,
      /breakthrough/i,
      /revolutionary/i
    ];
    
    return breakthroughPatterns.some(pattern => pattern.test(text));
  }

  /**
   * Calculate the significance of a breakthrough moment
   * @private
   */
  calculateBreakthroughSignificance(data) {
    const text = data.text || data || '';
    let significance = 0.5; // Base significance
    
    // Check for intensity indicators
    if (text.includes('🤯')) significance += 0.2;
    if (text.includes('🔥')) significance += 0.1;
    if (text.includes('HOLY')) significance += 0.2;
    if (/wait\.?\s*wait/i.test(text)) significance += 0.3;
    
    return Math.min(significance, 1.0); // Cap at 1.0
  }

  /**
   * Check if an event should be stored long-term
   * @private
   */
  isSignificantEvent(event) {
    return event.type === 'breakthrough' || 
           event.type.startsWith('pattern:') ||
           (event.type === 'conversation' && this.isBreakthroughMoment(event.data));
  }

  /**
   * Generate unique event IDs
   * @private
   */
  generateEventId() {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

// Export singleton for global nervous system
export const nervousSystem = new NervousSystem();