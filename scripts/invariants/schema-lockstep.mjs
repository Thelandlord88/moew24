#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:lockstep] dist/ missing'); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const section=doc.querySelector('[data-invariant="nearby"]'); if(!section) continue;
  const ui=[...section.querySelectorAll('[data-role="nearby-ui"] a')].map(a=>a.getAttribute('href')).filter(Boolean);
  const ldNode=section.querySelector('script[type="application/ld+json"][data-role="nearby-ld"]');
  if(!ldNode){ console.error(`[inv:lockstep] ${file}: missing nearby JSON-LD`); issues++; continue; }
  let ld; try{ ld=JSON.parse(ldNode.textContent||'{}'); }catch{ console.error(`[inv:lockstep] ${file}: invalid nearby JSON-LD`); issues++; continue; }
  const ldUrls=(ld?.itemListElement||[]).map((x)=>x?.url).filter(Boolean);
  if(ldUrls.length!==ui.length || ldUrls.some((u,i)=>u!==ui[i])){ console.error(`[inv:lockstep] ${file}: nearby UI and JSON-LD differ`); issues++; }
  if(ui.length>6){ console.error(`[inv:lockstep] ${file}: nearby list exceeds cap (6)`); issues++; }
}
if(issues){ process.exit(1); }
console.log('[inv:lockstep] OK');
