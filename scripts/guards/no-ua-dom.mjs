#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const DIST = path.join(ROOT, 'dist');

if (!fs.existsSync(DIST)) {
  console.error('[guard:ua] dist/ not found');
  process.exit(2);
}

function* walk(dir) {
  const ents = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of ents) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (e.isFile() && e.name.endsWith('.html')) yield p;
  }
}

const bad = [];
for (const file of walk(DIST)) {
  const code = fs.readFileSync(file, 'utf8');
  if (/navigator\.userAgent|userAgentData/.test(code)) bad.push(file);
}

if (bad.length) {
  console.error('[guard:ua] user-agent based DOM branching detected in:', bad.map(p => path.relative(ROOT, p)));
  process.exit(2);
}
console.log('[guard:ua] ok');
