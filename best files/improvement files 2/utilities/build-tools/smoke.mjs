#!/usr/bin/env node
import fs from "node:fs"; import path from "node:path";
const base = process.env.GEO_BASE_DIR ? path.resolve(process.env.GEO_BASE_DIR) : process.cwd();
const cfg = JSON.parse(fs.readFileSync(path.join(base,"geo.config.json"),"utf8"));
const preview=(process.env.DEPLOY_PRIME_URL||process.env.DEPLOY_URL||process.env.VERCEL_URL||"").replace(/\/+$/,""); if(preview) console.log("[smoke] Preview origin: "+preview);
const site=(cfg.site||"").replace(/\/+$/,""); const svcs=Array.isArray(cfg.services)?cfg.services:[];
let subs=[]; try{ const geo=JSON.parse(fs.readFileSync(path.join(base,"src/data/suburbs_enriched.geojson"),"utf8")); subs=(geo.features||[]).map(f=>f.properties?.name_official||f.properties?.name||f.properties?.suburb).filter(Boolean).slice(0,3);}catch{}
console.log("[smoke] Candidate URLs:");
for(const s of svcs.slice(0,5)){ console.log(`  - ${site}/services/${encodeURIComponent(s)}/`); for(const sub of subs){ const slug=String(sub).toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,''); console.log(`  - ${site}/services/${encodeURIComponent(s)}/${slug}/`);}}
