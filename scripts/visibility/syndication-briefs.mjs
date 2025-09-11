#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const cfg=JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
if(!cfg.syndication?.enabled){ console.log('[syndication] disabled'); process.exit(0); }
const OUT=cfg.syndication.outDir||'__ai/syndication'; fs.mkdirSync(OUT,{recursive:true});

const site=cfg.site || 'https://example.com';
const seed = [
  { title:'Bond Cleaning: Agent Hotspots (Ipswich)', url:`${site}/blog/agent-hotspots-ipswich/`, summary:'Oven glass edges, shower screen lip, track corners. Timing & checklist.' },
  { title:'Spring Clean vs End-of-Lease', url:`${site}/blog/spring-vs-bond/`, summary:'When to choose each service and how agents inspect differently.' }
];

for (const p of seed){
  const base = p.title.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'');
  const md = `---
title: "${p.title}"
platforms: ${JSON.stringify(cfg.syndication.platforms||['linkedin'])}
disclosure: "${cfg.syndication.disclosure}"
canonical: "${p.url}"
---

> ${cfg.syndication.canonicalNote}

${p.summary}

**Read the full guide:** ${p.url}
`;
  fs.writeFileSync(path.join(OUT, `${base}.md`), md);
}
console.log(`[syndication] briefs → ${OUT}`);
