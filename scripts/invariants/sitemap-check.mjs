#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:sitemap] dist/ missing'); process.exit(0); }
const sm = path.join(DIST,'sitemap.xml'); if(!fs.existsSync(sm)) { console.log('[inv:sitemap] sitemap.xml missing (page-based sitemap)'); process.exit(0); }
const xml=fs.readFileSync(sm,'utf8');
const urls=[...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m=>m[1]);
let issues=0;
for(const u of urls){
  const rel = u.replace(/^https?:\/\/[^/]+/,''); const f = path.join(DIST, rel.replace(/\/$/,'/index.html'));
  if(!fs.existsSync(f)) { console.error(`[inv:sitemap] ${u}: not found in dist`); issues++; continue; }
  const html=fs.readFileSync(f,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const can=doc.querySelector('link[rel="canonical"]')?.getAttribute('href')||''; if(can!==u) { console.error(`[inv:sitemap] ${u}: canonical mismatch (${can})`); issues++; }
  const anchors=[...doc.querySelectorAll('a[href]')].map(a=>a.getAttribute('href')); if(anchors.length===0) { console.error(`[inv:sitemap] ${u}: page not in internal link graph (no anchors)`); issues++; }
}
if(issues) process.exit(1); console.log('[inv:sitemap] OK');
