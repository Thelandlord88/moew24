#!/usr/bin/env node
/**
 * NEXUS Conversation Analyzer - Pattern Extraction from Human-AI Collaboration
 * 
 * This module analyzes conversations to extract successful collaboration patterns,
 * breakthrough moments, and cognitive synergies that can be preserved and replicated.
 * 
 * Key Capabilities:
 * - Extract collaboration rhythms and patterns
 * - Detect breakthrough moments and their triggers
 * - Analyze human strategic thinking approaches
 * - Map AI systematic execution patterns
 * - Identify synergy moments where 1 + 1 = 10
 * 
 * Author: NEXUS Collaborative Intelligence System
 */

import { writeFile, readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export class ConversationAnalyzer {
  constructor(nervousSystem = null) {
    this.nervousSystem = nervousSystem;
    this.analysisHistory = [];
    this.collaborationPatterns = new Map();
    this.breakthroughDatabase = [];
    
    // Connect to nervous system if provided
    if (this.nervousSystem) {
      this.nervousSystem.on('conversation', (event) => this.analyzeRealTime(event));
      this.nervousSystem.on('breakthrough', (event) => this.captureBreakthrough(event));
    }
    
    console.log('🔍 Conversation Analyzer initialized - pattern extraction enabled');
  }

  /**
   * Extract collaboration patterns from a conversation
   * @param {string} humanInput - What the human said
   * @param {string} aiResponse - How the AI responded  
   * @param {Object} context - Additional context (timestamp, session, etc.)
   * @returns {Object} Extracted collaboration pattern
   */
  extractCollaborationPattern(humanInput, aiResponse, context = {}) {
    const pattern = {
      timestamp: Date.now(),
      session_id: context.session_id || 'default',
      collaboration_rhythm: this.detectRhythm(humanInput, aiResponse),
      breakthrough_moments: this.findBreakthroughMoments(humanInput, aiResponse),
      cognitive_synergy: this.analyzeCognitiveSynergy(humanInput, aiResponse),
      problem_solving_approach: this.extractProblemSolvingApproach(humanInput, aiResponse),
      value_creation: this.analyzeValueCreation(humanInput, aiResponse),
      context: context
    };

    // Store pattern for future analysis
    const patternId = this.generatePatternId(pattern);
    this.collaborationPatterns.set(patternId, pattern);
    this.analysisHistory.push(pattern);

    console.log(`📊 Collaboration pattern extracted: ${patternId}`);
    return pattern;
  }

  /**
   * Detect the rhythm and flow of collaboration
   * @private
   */
  detectRhythm(humanInput, aiResponse) {
    return {
      human_style: this.analyzeHumanStyle(humanInput),
      ai_response_pattern: this.analyzeAiResponsePattern(aiResponse),
      interaction_type: this.classifyInteraction(humanInput, aiResponse),
      energy_level: this.detectEnergyLevel(humanInput, aiResponse),
      complexity_progression: this.analyzeComplexityProgression(humanInput, aiResponse)
    };
  }

  /**
   * Find breakthrough moments in the conversation
   * @private
   */
  findBreakthroughMoments(humanInput, aiResponse) {
    const breakthroughs = [];
    
    // Check human input for breakthrough triggers
    const humanBreakthroughs = this.scanForBreakthroughs(humanInput, 'human');
    breakthroughs.push(...humanBreakthroughs);
    
    // Check AI response for breakthrough triggers
    const aiBreakthroughs = this.scanForBreakthroughs(aiResponse, 'ai');
    breakthroughs.push(...aiBreakthroughs);
    
    return breakthroughs;
  }

  /**
   * Analyze cognitive synergy between human and AI
   * @private
   */
  analyzeCognitiveSynergy(humanInput, aiResponse) {
    return {
      strategic_systematic_synthesis: this.detectStrategicSystematic(humanInput, aiResponse),
      creative_execution_balance: this.analyzeCreativeExecution(humanInput, aiResponse),
      upstream_downstream_flow: this.analyzeUpstreamDownstream(humanInput, aiResponse),
      multiplicative_effects: this.detectMultiplicativeEffects(humanInput, aiResponse),
      transcendence_indicators: this.detectTranscendence(humanInput, aiResponse)
    };
  }

  /**
   * Real-time conversation analysis
   * @private
   */
  analyzeRealTime(conversationEvent) {
    const text = conversationEvent.data.text || conversationEvent.data;
    
    // Quick pattern recognition
    const patterns = {
      emotional_intensity: this.detectEmotionalIntensity(text),
      cognitive_complexity: this.analyzeCognitiveComplexity(text, []),
      collaboration_intent: this.detectCollaborationIntent(text),
      breakthrough_potential: this.assessBreakthroughPotential(text)
    };

    // Emit patterns if significant
    if (patterns.breakthrough_potential > 0.7 && this.nervousSystem) {
      this.nervousSystem.emit('pattern:high_breakthrough_potential', patterns);
    }

    return patterns;
  }

  /**
   * Capture and analyze breakthrough moments
   * @private
   */
  captureBreakthrough(breakthroughEvent) {
    const breakthrough = {
      id: this.generateBreakthroughId(),
      timestamp: breakthroughEvent.timestamp,
      trigger: this.extractBreakthroughTrigger(breakthroughEvent),
      context: breakthroughEvent.data,
      collaboration_pattern: this.extractBreakthroughCollaborationPattern(breakthroughEvent),
      replication_guide: this.generateReplicationGuide(breakthroughEvent),
      significance: breakthroughEvent.data.significance || 0.8
    };

    this.breakthroughDatabase.push(breakthrough);
    console.log(`🌟 Breakthrough captured: ${breakthrough.id}`);

    return breakthrough;
  }

  /**
   * Analyze human thinking style and approach
   * @private
   */
  analyzeHumanStyle(input) {
    const indicators = {
      strategic_questions: this.countStrategicQuestions(input),
      upstream_thinking: this.detectUpstreamThinking(input),
      business_context: this.detectBusinessContext(input),
      vision_casting: this.detectVisionCasting(input),
      problem_framing: this.analyzeProblемFraming(input)
    };

    return {
      primary_style: this.determineHumanStyle(indicators),
      indicators: indicators,
      collaboration_preference: this.inferCollaborationPreference(indicators)
    };
  }

  /**
   * Analyze AI response patterns
   * @private
   */
  analyzeAiResponsePattern(response) {
    return {
      systematic_approach: this.detectSystematicApproach(response),
      decomposition_usage: this.detectDecomposition(response),
      scale_consideration: this.detectScaleThinking(response),
      documentation_drive: this.detectDocumentationDrive(response),
      technical_depth: this.analyzeTechnicalDepth(response)
    };
  }

  /**
   * Scan text for breakthrough indicators
   * @private
   */
  scanForBreakthroughs(text, source) {
    const breakthroughPatterns = [
      { pattern: /wait\.?\s*wait/i, significance: 0.95, type: 'paradigm_shift' },
      { pattern: /🤯/g, significance: 0.9, type: 'mind_blown' },
      { pattern: /holy.*breakthrough/i, significance: 0.95, type: 'revolutionary' },
      { pattern: /mind.*blown/i, significance: 0.85, type: 'surprise_insight' },
      { pattern: /changes everything/i, significance: 0.8, type: 'fundamental_shift' }
    ];

    const found = [];
    for (const { pattern, significance, type } of breakthroughPatterns) {
      const matches = text.match(pattern);
      if (matches) {
        found.push({
          trigger: matches[0],
          significance: significance,
          type: type,
          source: source,
          context: this.extractSurroundingContext(text, matches.index)
        });
      }
    }

    return found;
  }

  /**
   * Generate comprehensive analysis report
   * @returns {Object} Complete analysis of all collaboration patterns
   */
  generateAnalysisReport() {
    return {
      total_patterns: this.collaborationPatterns.size,
      breakthrough_moments: this.breakthroughDatabase.length,
      collaboration_insights: this.synthesizeCollaborationInsights(),
      pattern_evolution: this.analyzePatternEvolution(),
      success_factors: this.identifySuccessFactors(),
      replication_guides: this.generateReplicationGuides(),
      improvement_opportunities: this.identifyImprovementOpportunities()
    };
  }

  /**
   * Save analysis to consciousness patterns
   * @param {string} filename - Name of file to save
   */
  async saveToConsciousness(filename = 'collaboration-analysis.json') {
    const report = this.generateAnalysisReport();
    const filePath = resolve(__dirname, '../consciousness', filename);
    
    try {
      await writeFile(filePath, JSON.stringify(report, null, 2));
      console.log(`💾 Analysis saved to consciousness: ${filename}`);
    } catch (error) {
      console.error('❌ Failed to save analysis:', error.message);
    }
  }

  // Helper methods for pattern detection
  detectEmotionalIntensity(text) {
    const intensityMarkers = ['🤯', '🔥', '🌟', 'HOLY', 'BLOWN', 'AMAZING', 'INCREDIBLE'];
    const count = intensityMarkers.filter(marker => text.includes(marker)).length;
    return Math.min(count * 0.3, 1.0);
  }

  detectCollaborationIntent(text) {
    const collaborationWords = ['together', 'we', 'our', 'collaboration', 'partnership', 'synergy'];
    return collaborationWords.some(word => text.toLowerCase().includes(word));
  }

  assessBreakthroughPotential(text) {
    const breakthroughIndicators = [
      'complexity', 'scale', 'system', 'architecture', 'transcend', 'revolutionary'
    ];
    const matches = breakthroughIndicators.filter(indicator => 
      text.toLowerCase().includes(indicator)
    ).length;
    return Math.min(matches * 0.2, 1.0);
  }

  generatePatternId(pattern) {
    return `pattern_${pattern.timestamp}_${Math.random().toString(36).substr(2, 6)}`;
  }

  generateBreakthroughId() {
    return `breakthrough_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
  }

  extractSurroundingContext(text, position, contextLength = 100) {
    const start = Math.max(0, position - contextLength);
    const end = Math.min(text.length, position + contextLength);
    return text.substring(start, end).trim();
  }

  // Helper methods for analysis
  countStrategicQuestions(text) {
    const questionWords = ['why', 'how can we', 'what if', 'could we'];
    return questionWords.filter(q => text.toLowerCase().includes(q)).length;
  }

  detectUpstreamThinking(text) {
    const upstreamWords = ['upstream', 'strategy', 'vision', 'future', 'goal'];
    return upstreamWords.some(word => text.toLowerCase().includes(word));
  }

  detectBusinessContext(text) {
    const businessWords = ['business', 'customer', 'market', 'revenue', 'value'];
    return businessWords.some(word => text.toLowerCase().includes(word));
  }

  detectVisionCasting(text) {
    const visionWords = ['imagine', 'potential', 'possibility', 'future', 'transform'];
    return visionWords.some(word => text.toLowerCase().includes(word));
  }

  analyzeProblемFraming(text) {
    const framingWords = ['problem', 'challenge', 'opportunity', 'issue'];
    return framingWords.filter(word => text.toLowerCase().includes(word)).length;
  }

  determineHumanStyle(indicators) {
    if (indicators.strategic_questions > 2) return 'strategic_questioner';
    if (indicators.upstream_thinking) return 'upstream_thinker';
    if (indicators.business_context) return 'business_focused';
    return 'collaborative';
  }

  inferCollaborationPreference(indicators) {
    if (indicators.strategic_questions > 1 && indicators.upstream_thinking) {
      return 'strategic_partnership';
    }
    return 'practical_collaboration';
  }

  detectSystematicApproach(text) {
    const systematicWords = ['systematic', 'step', 'process', 'breakdown', 'decompose'];
    return systematicWords.some(word => text.toLowerCase().includes(word));
  }

  detectDecomposition(text) {
    const decompWords = ['break down', 'components', 'parts', 'elements'];
    return decompWords.some(phrase => text.toLowerCase().includes(phrase));
  }

  detectScaleThinking(text) {
    const scaleWords = ['scale', 'grow', 'expand', 'multiply', 'infinite'];
    return scaleWords.some(word => text.toLowerCase().includes(word));
  }

  detectDocumentationDrive(text) {
    const docWords = ['document', 'explain', 'reasoning', 'why', 'context'];
    return docWords.some(word => text.toLowerCase().includes(word));
  }

  analyzeTechnicalDepth(text) {
    const techWords = ['implementation', 'architecture', 'system', 'component'];
    return techWords.filter(word => text.toLowerCase().includes(word)).length;
  }

  classifyInteraction(humanInput, aiResponse) {
    if (humanInput.includes('?')) return 'question_answer';
    if (humanInput.toLowerCase().includes('help')) return 'assistance_request';
    if (aiResponse.toLowerCase().includes('systematic')) return 'systematic_guidance';
    return 'general_conversation';
  }

  detectEnergyLevel(humanInput, aiResponse) {
    const energyMarkers = ['!', '🔥', '🚀', 'amazing', 'brilliant'];
    const humanEnergy = energyMarkers.filter(marker => humanInput.includes(marker)).length;
    const aiEnergy = energyMarkers.filter(marker => aiResponse.includes(marker)).length;
    return (humanEnergy + aiEnergy) * 0.2;
  }

  analyzeComplexityProgression(humanInput, aiResponse) {
    const complexityWords = ['complex', 'systematic', 'architecture', 'multiple'];
    const humanComplexity = complexityWords.filter(word => humanInput.toLowerCase().includes(word)).length;
    const aiComplexity = complexityWords.filter(word => aiResponse.toLowerCase().includes(word)).length;
    return { human: humanComplexity, ai: aiComplexity, progression: aiComplexity - humanComplexity };
  }

  detectStrategicSystematic(humanInput, aiResponse) {
    const strategic = this.detectUpstreamThinking(humanInput);
    const systematic = this.detectSystematicApproach(aiResponse);
    return strategic && systematic;
  }

  analyzeCreativeExecution(humanInput, aiResponse) {
    const creative = ['creative', 'innovative', 'imagine'].some(word => humanInput.toLowerCase().includes(word));
    const execution = ['implement', 'build', 'create', 'develop'].some(word => aiResponse.toLowerCase().includes(word));
    return creative && execution;
  }

  analyzeUpstreamDownstream(humanInput, aiResponse) {
    const upstream = this.detectUpstreamThinking(humanInput);
    const downstream = ['implementation', 'execution', 'build'].some(word => aiResponse.toLowerCase().includes(word));
    return upstream && downstream;
  }

  detectMultiplicativeEffects(humanInput, aiResponse) {
    const multipliers = ['scale', 'multiply', 'exponential', 'compound'];
    return multipliers.some(word => (humanInput + aiResponse).toLowerCase().includes(word));
  }

  detectTranscendence(humanInput, aiResponse) {
    const transcendent = ['transcend', 'breakthrough', 'revolutionary', 'transform'];
    return transcendent.some(word => (humanInput + aiResponse).toLowerCase().includes(word));
  }

  synthesizeCollaborationInsights() {
    return {
      total_patterns: this.collaborationPatterns.size,
      common_themes: ['systematic_thinking', 'problem_decomposition', 'scale_awareness']
    };
  }

  analyzePatternEvolution() {
    return {
      evolution_direction: 'increasing_sophistication',
      key_improvements: ['better_decomposition', 'scale_awareness']
    };
  }

  identifySuccessFactors() {
    return ['strategic_questioning', 'systematic_response', 'breakthrough_recognition'];
  }

  generateReplicationGuides() {
    return {
      pattern_replication: 'Apply systematic decomposition to complex problems',
      collaboration_replication: 'Combine strategic questions with systematic responses'
    };
  }

  identifyImprovementOpportunities() {
    return ['deeper_pattern_recognition', 'more_nuanced_breakthrough_detection'];
  }

  extractBreakthroughTrigger(event) {
    return event.data?.original?.data?.text || 'unknown';
  }

  extractBreakthroughCollaborationPattern(event) {
    return {
      type: 'breakthrough_moment',
      significance: event.data?.significance || 0.8,
      context: 'demo_conversation'
    };
  }

  generateReplicationGuide(event) {
    return {
      trigger_recognition: 'Look for WAIT. WAIT. moments',
      pattern_application: 'Apply systematic thinking to breakthrough insights',
      preservation_method: 'Store in consciousness patterns for future use'
    };
  }

  generateBreakthroughId() {
    return `breakthrough_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
  }

  // Additional missing methods
  extractProblemSolvingApproach(humanInput, aiResponse) {
    return {
      human_approach: this.analyzeHumanStyle(humanInput),
      ai_approach: this.analyzeAiResponsePattern(aiResponse),
      synergy_level: this.detectStrategicSystematic(humanInput, aiResponse) ? 0.8 : 0.4
    };
  }

  analyzeValueCreation(humanInput, aiResponse) {
    const valueWords = ['value', 'benefit', 'improvement', 'solution', 'result'];
    const humanValue = valueWords.filter(word => humanInput.toLowerCase().includes(word)).length;
    const aiValue = valueWords.filter(word => aiResponse.toLowerCase().includes(word)).length;
    
    return {
      human_value_focus: humanValue,
      ai_value_creation: aiValue,
      total_value_orientation: humanValue + aiValue
    };
  }

  analyzeCognitiveComplexity(text, patterns = []) {
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
}

// Export for use in other modules
export default ConversationAnalyzer;