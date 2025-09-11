#!/usr/bin/env node
import fs from "node:fs"; import path from "node:path"; import { Window } from "happy-dom";
const DIST="dist", OUT="__ai"; if (!fs.existsSync(DIST)) { console.log("[seo] dist/ not found; run build."); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith(".html")) yield full; } }
const pages=[]; for(const file of walk(DIST)){ const html=fs.readFileSync(file,"utf8"); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const canonical=doc.querySelector('link[rel="canonical"]')?.getAttribute('href') || null;
  const ld=[...doc.querySelectorAll('script[type="application/ld+json"]')].map(s=>s.textContent||'').map(t=>{try{return JSON.parse(t);}catch(e){return {__parseError:String(e.message||e), raw:t.slice(0,500)};}});
  const rel="/"+path.relative(DIST,file).split(path.sep).join("/");
  pages.push({ page:rel, canonical, jsonld: ld });
}
fs.mkdirSync(OUT,{recursive:true}); fs.writeFileSync(path.join(OUT,"hardcoded-seo.json"), JSON.stringify(pages,null,2));
const summary={ pages:pages.length, withoutCanonical: pages.filter(p=>!p.canonical).length, jsonldBlocks: pages.reduce((n,p)=>n+p.jsonld.length,0), jsonldErrors: pages.reduce((n,p)=> n+ p.jsonld.filter(x=>x.__parseError).length,0) };
fs.writeFileSync(path.join(OUT,"hardcoded-seo-summary.json"), JSON.stringify(summary,null,2));
console.log(`[seo] pages=${summary.pages} canonicals-missing=${summary.withoutCanonical} jsonld-errors=${summary.jsonldErrors}`);
process.exit(0);
