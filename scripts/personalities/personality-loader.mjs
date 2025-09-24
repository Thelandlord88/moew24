#!/usr/bin/env node
/**
 * Personality Loader - Systematic Intelligence Framework
 * Loads and validates AI personalities for collaborative decision making
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const PERSONALITY_FILES = {
  daedalus: './daedalus.personality.json',
  hunter: './hunter.personality.json'
};

function loadPersonality(name) {
  const file = PERSONALITY_FILES[name.toLowerCase()];
  if (!file) {
    throw new Error(`Unknown personality: ${name}. Available: ${Object.keys(PERSONALITY_FILES).join(', ')}`);
  }
  
  try {
    const content = readFileSync(resolve(file), 'utf8');
    const personality = JSON.parse(content);
    
    // Validate required personality structure
    const required = ['version', 'identity', 'ideology', 'learning', 'decision_policy'];
    for (const field of required) {
      if (!personality[field]) {
        throw new Error(`Invalid personality: missing required field '${field}'`);
      }
    }
    
    return personality;
  } catch (error) {
    throw new Error(`Failed to load personality '${name}': ${error.message}`);
  }
}

function validatePersonalitySystem() {
  console.log('🧠 Personality System Validation');
  console.log('=====================================');
  
  const personalities = {};
  let allValid = true;
  
  for (const [name, file] of Object.entries(PERSONALITY_FILES)) {
    try {
      const personality = loadPersonality(name);
      personalities[name] = personality;
      
      console.log(`✅ ${name.toUpperCase()}: ${personality.identity.tagline}`);
      console.log(`   Priority: ${personality.identity.priority}`);
      console.log(`   Version: ${personality.version}`);
      console.log(`   Principles: ${personality.ideology.principles.length}`);
      console.log('');
      
    } catch (error) {
      console.error(`❌ ${name.toUpperCase()}: ${error.message}`);
      allValid = false;
    }
  }
  
  if (allValid) {
    console.log('🌟 All personalities loaded successfully!');
    console.log('📊 Collaborative Intelligence Framework: OPERATIONAL');
    
    // Show collaboration model
    const daedalus = personalities.daedalus;
    const hunter = personalities.hunter;
    
    console.log('\n🤝 Collaboration Model:');
    console.log(`   ${daedalus.identity.name} (${daedalus.identity.priority}): Creates systematic intelligence`);
    console.log(`   ${hunter.identity.name} (${hunter.identity.priority}): Enforces quality and evidence`);
    console.log('\n🎯 Communication Protocol: Assumptions → Evidence → Decision → Actions → Risks → Next checks');
    
  } else {
    console.error('💥 Personality system validation FAILED');
    process.exit(1);
  }
  
  return personalities;
}

function getPersonalityGuidance(name, context = {}) {
  const personality = loadPersonality(name);
  
  console.log(`\n🎯 ${personality.identity.name.toUpperCase()} GUIDANCE`);
  console.log('=====================================');
  console.log(`💭 ${personality.identity.tagline}`);
  
  console.log('\n📋 Core Principles:');
  personality.ideology.principles.forEach((principle, i) => {
    console.log(`   ${i + 1}. ${principle}`);
  });
  
  console.log('\n⚡ Default Actions:');
  personality.default_actions.forEach((action, i) => {
    console.log(`   ${i + 1}. ${action}`);
  });
  
  if (personality.constraints?.length) {
    console.log('\n🚫 Constraints:');
    personality.constraints.forEach(constraint => {
      console.log(`   • ${constraint}`);
    });
  }
  
  return personality;
}

// CLI Interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const [,, command, ...args] = process.argv;
  
  try {
    switch (command) {
      case 'validate':
        validatePersonalitySystem();
        break;
        
      case 'load':
        if (!args[0]) {
          console.error('Usage: personality-loader.mjs load <personality-name>');
          process.exit(1);
        }
        const personality = loadPersonality(args[0]);
        console.log(JSON.stringify(personality, null, 2));
        break;
        
      case 'guide':
        if (!args[0]) {
          console.error('Usage: personality-loader.mjs guide <personality-name>');
          process.exit(1);
        }
        getPersonalityGuidance(args[0]);
        break;
        
      default:
        console.log(`
🧠 Personality Loader - Systematic Intelligence Framework

Usage:
  node scripts/personalities/personality-loader.mjs validate
  node scripts/personalities/personality-loader.mjs load <personality-name>
  node scripts/personalities/personality-loader.mjs guide <personality-name>

Available personalities: ${Object.keys(PERSONALITY_FILES).join(', ')}

Examples:
  node scripts/personalities/personality-loader.mjs validate
  node scripts/personalities/personality-loader.mjs guide daedalus
  node scripts/personalities/personality-loader.mjs guide hunter
        `);
    }
  } catch (error) {
    console.error(`💥 Error: ${error.message}`);
    process.exit(1);
  }
}

export { loadPersonality, validatePersonalitySystem, getPersonalityGuidance };
