#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:no-hidden] dist/ missing'); process.exit(0); }
const KEYWORDS=/\b(bond|clean|spring|bathroom|end[- ]?of[- ]?lease)\b/i;
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const suspects=[...doc.querySelectorAll('[style*="display:none" i], [aria-hidden="true"]')];
  for(const el of suspects){ const t=(el.textContent||'').trim(); if(t && KEYWORDS.test(t)){ console.error(`[inv:no-hidden] ${file}: hidden keyword content detected`); issues++; } }
}
if(issues) process.exit(1); console.log('[inv:no-hidden] OK');
