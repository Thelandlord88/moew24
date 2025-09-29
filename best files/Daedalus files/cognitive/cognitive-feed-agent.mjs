#!/usr/bin/env node
/**
 * Cognitive Feed Agent
 * Watches COGNITIVE_FEED.md for requests and runs full cognitive cycles
 * Designed for GitHub Codespaces integration
 */

import { readFile, writeFile, watch } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// --- PERSONALITY SIMULATIONS (Replace with real engines later) ---
// In a real system, these would import your actual personality modules
const PERSONALITIES = {
  Synthesia: {
    name: "Synthesia",
    role: "Orchestrator",
    emoji: "🧠",
    respond: (request) => ({
      markdown: `**Routing decision**:  
- Problem type: **Strategic (high novelty)**  
- Historical match: **Medium (see #2023-11-04)**  
- Engaging: **Kairos → Logos → Ethos → Chronos**  
- Mnemos: **Providing lineage**`
    })
  },
  Kairos: {
    name: "Kairos",
    role: "Strategist",
    emoji: "💡",
    respond: (request) => ({
      markdown: `**Reframing**:  
> “This isn’t ${request.toLowerCase().includes('morale') ? 'low morale' : 'the surface issue'}—it’s **unprocessed collective tension** over hidden trade-offs.”  

**Leverage point**:  
- Create a ritual for making compromises visible before they ship.`
    })
  },
  Logos: {
    name: "Logos",
    role: "Tactician",
    emoji: "🛠️",
    respond: (request) => ({
      markdown: `**Implementation**:  
\`\`\`ts
// src/rituals/compromise-transparency.ts
// [KAIROS: Leverage Point - Make trade-offs visible]
// [ETHOS: Preserves team autonomy via opt-in]
export const runTradeoffRitual = (context: ReleaseContext) => { ... }
\`\`\`

**Artifacts**:  
- \`/docs/rituals/tradeoff-transparency.md\`  
- \`/src/rituals/tradeoff-transparency.ts\``
    })
  },
  Ethos: {
    name: "Ethos",
    role: "Guardian",
    emoji: "⚖️",
    respond: (request) => ({
      markdown: `**Moral check**:  
✅ **Approved** — includes:  
- Opt-in participation (no coercion)  
- Redress path: “Log concern anonymously”  
- // ETHOS: Autonomy preserved via user sovereignty`
    })
  },
  Chronos: {
    name: "Chronos",
    role: "Steward",
    emoji: "⏳",
    respond: (request) => ({
      markdown: `**Temporal impact**:  
- **Half-life**: 3+ years (adapts to team growth)  
- **Seam**: \`ITradeoffRitual\` interface for future replacements  
- **Legacy kit**: \`/docs/future/rituals-2030.md\``
    })
  },
  Mnemos: {
    name: "Mnemos",
    role: "Historian",
    emoji: "📚",
    respond: (request) => ({
      markdown: `**Lineage**:  
- Similar to **#2023-11-04** (“Ignored UX concerns in v2.1”)  
- Outcome: 40% ↑ in psychological safety score  
- **Lesson**: Rituals > retrospectives for processing tension`
    })
  }
};

// --- COGNITIVE FEED MANAGER ---
class CognitiveFeed {
  constructor(filepath = './COGNITIVE_FEED.md') {
    this.path = resolve(filepath);
    this.lastProcessed = null;
  }

  async initialize() {
    try {
      await readFile(this.path, 'utf8');
    } catch {
      await this.#writeInitialTemplate();
      console.log(`✅ Created ${this.path}`);
    }
  }

  async #writeInitialTemplate() {
    const template = `# 🧠 Cognitive Feed

> **Last updated**: ${new Date().toISOString().split('T')[0]}  
> **Active personalities**: Kairos, Logos, Mnemos, Synthesia, Ethos, Chronos  
> **Status**: 🟢 Ready for input

---

## 📥 YOUR REQUEST
<!-- Write your request below this line. Delete this comment when done. -->

---

## 📥 YOUR REQUEST
<!-- Write your next request below this line. -->
`;
    await writeFile(this.path, template);
  }

  async read() {
    return await readFile(this.path, 'utf8');
  }

  async hasNewRequest() {
    const content = await this.read();
    const requestMatch = content.match(/## 📥 YOUR REQUEST\s*<!--.*?-->\s*(.+?)(?=\s*## 📥 YOUR REQUEST|\s*$)/s);
    const newRequest = requestMatch ? requestMatch[1].trim() : '';
    
    if (newRequest && newRequest !== this.lastProcessed) {
      this.lastProcessed = newRequest;
      return newRequest;
    }
    return null;
  }

  async appendCycle(request, responses) {
    const content = await this.read();
    const cycleId = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    
    let cycleBlock = `\n## 🔄 COGNITIVE CYCLE #${cycleId}\n\n`;
    
    // Order matters: Synthesia first, then others
    const order = ['Synthesia', 'Kairos', 'Logos', 'Ethos', 'Chronos', 'Mnemos'];
    for (const name of order) {
      if (responses[name]) {
        const p = PERSONALITIES[name];
        cycleBlock += `### ${p.emoji} ${p.name} (${p.role})\n${responses[name].markdown}\n\n`;
      }
    }

    // Replace the first request block with cycle + new clean block
    const updated = content.replace(
      /(## 📥 YOUR REQUEST\s*<!--.*?-->\s*).*?(?=\s*## 📥 YOUR REQUEST|\s*$)/s,
      `$1${cycleBlock.trim()}\n\n---\n\n## 📥 YOUR REQUEST\n<!-- Write your next request below this line. -->`
    );
    
    await writeFile(this.path, updated);
    console.log(`✅ Cognitive cycle #${cycleId} complete!`);
  }
}

// --- MAIN AGENT LOOP ---
async function main() {
  const feed = new CognitiveFeed();
  await feed.initialize();
  
  console.log('👁️  Cognitive Feed Agent is watching...');
  console.log(`📝 Edit ${feed.path} to make a request.`);
  console.log('   (Write below the first "YOUR REQUEST" header)\n');

  // Watch for file changes
  const watcher = watch(feed.path);
  for await (const event of watcher) {
    if (event.eventType === 'change') {
      const request = await feed.hasNewRequest();
      if (request) {
        console.log(`\n📥 New request detected: "${request}"`);
        console.log('🧠 Running full cognitive cycle...\n');
        
        // Run all personalities
        const responses = {};
        for (const [name, personality] of Object.entries(PERSONALITIES)) {
          try {
            responses[name] = personality.respond(request);
            console.log(`   ✅ ${name} responded`);
          } catch (e) {
            console.error(`   ❌ ${name} failed:`, e.message);
          }
        }
        
        await feed.appendCycle(request, responses);
        console.log('\n✨ Ready for your next request!\n');
      }
    }
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
