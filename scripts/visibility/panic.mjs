#!/usr/bin/env node
import fs from 'node:fs';
const p='__ai/visibility-flags.json';
const cfg=JSON.parse(fs.readFileSync(p,'utf8'));
cfg.syndication.enabled=false;
cfg.similarity.enabled=true; // keep guardrails ON
cfg.ethics.blockHiddenKeywordBlocks=true;
cfg.ethics.blockUAConditionals=true;
fs.writeFileSync(p, JSON.stringify(cfg,null,2));
console.log('🛑 Panic mode: optional add-ons disabled; guardrails hardened. Commit & redeploy.');
