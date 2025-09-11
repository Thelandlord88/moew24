#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
if (!fs.existsSync('dist')) { console.log('[404] dist missing'); process.exit(0); }
function* walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name); if(e.isDirectory())yield*walk(f); else if(e.isFile()&&f.endsWith('.html'))yield f;}}
const links=new Set();
for (const f of walk('dist')){ const html=fs.readFileSync(f,'utf8'); const doc=new Window().document; doc.body.innerHTML=html; for (const a of doc.querySelectorAll('a[href]')) {const href=a.getAttribute('href')||''; if(/^\/[a-z0-9/_-]*$/i.test(href)) links.add(href);} }
const missing=[];
for (const href of links){ const target = path.join('dist', href.endsWith('/')?href+'index.html':href); if(!fs.existsSync(target)) missing.push(href); }
fs.mkdirSync('__ai',{recursive:true}); fs.writeFileSync('__ai/internal-404s.json', JSON.stringify({ missing }, null, 2));
console.log(`[404] ${missing.length} internal href(s) missing → __ai/internal-404s.json`);
