#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:similar] dist/ missing'); process.exit(0); }
const THRESH=0.85; // block if > 85% similar
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
const svcPages=[...walk(DIST)].filter(f=>/\/services\/(spring-clean|bathroom-deep-clean)\/[^/]+\/index\.html$/.test(f));
function textOf(f){ const html=fs.readFileSync(f,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  // strip nav/footer
  const main = doc.querySelector('main') || doc.body; const t=(main.textContent||'').replace(/\s+/g,' ').toLowerCase();
  const tokens=new Set(t.split(/\W+/).filter(Boolean)); return tokens;
}
function jacc(a,b){ const A=textOf(a), B=textOf(b); const inter=[...A].filter(x=>B.has(x)).length; const union=new Set([...A,...B]).size; return union? inter/union : 0; }
let issues=0; for(let i=0;i<svcPages.length;i++){ for(let j=i+1;j<svcPages.length;j++){ const s=jacc(svcPages[i], svcPages[j]); if(s>THRESH){ console.error(`[inv:similar] High similarity (${(s*100).toFixed(1)}%) between:\n  - ${svcPages[i]}\n  - ${svcPages[j]}`); issues++; } } }
if(issues) process.exit(1); console.log('[inv:similar] OK');
