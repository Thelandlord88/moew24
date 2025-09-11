#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:anchors] dist/ missing'); process.exit(0); }
const MAX_COMMERCIAL_REPEAT = 3; // same anchor text cap per page
const COMMERCIAL_WORDS = /(bond|clean|quote|bathroom|spring|service)/i;

function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const anchors=[...doc.querySelectorAll('a')].map(a=>({ text:(a.textContent||'').trim().toLowerCase(), href:a.getAttribute('href')||'' }));
  const freq=new Map(); for(const a of anchors){ if(COMMERCIAL_WORDS.test(a.text)) freq.set(a.text, (freq.get(a.text)||0)+1); }
  for(const [text,count] of freq){ if(count>MAX_COMMERCIAL_REPEAT){ console.error(`[inv:anchors] ${file}: anchor "${text}" repeats ${count}x`); issues++; } }
}
if(issues){ process.exit(1); }
console.log('[inv:anchors] OK');
