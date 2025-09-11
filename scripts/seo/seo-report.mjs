#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
if (!fs.existsSync('dist')) { console.log('[seo:snapshot] dist/ missing'); process.exit(0); }
function* walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name); if(e.isDirectory())yield*walk(f); else if(e.isFile()&&f.endsWith('.html'))yield f;}}
const rows=[];
for (const f of walk('dist')) {
  const html=fs.readFileSync(f,'utf8'); const doc=new Window().document; doc.body.innerHTML=html;
  const can=doc.querySelector('link[rel="canonical"]')?.getAttribute('href')||null;
  const jsonld=[...doc.querySelectorAll('script[type="application/ld+json"]')].map(s=>s.textContent||'');
  const errors=jsonld.map(t=>{try{JSON.parse(t);return null;}catch(e){return String(e.message||e);}}).filter(Boolean);
  rows.push({file:'/'.concat(path.relative('dist',f).split(path.sep).join('/')),canonical:can,jsonldBlocks:jsonld.length,jsonldErrors:errors.length});
}
fs.mkdirSync('__ai',{recursive:true}); fs.writeFileSync('__ai/seo-snapshot.json', JSON.stringify(rows,null,2));
console.log(`[seo:snapshot] ${rows.length} pages → __ai/seo-snapshot.json`);
