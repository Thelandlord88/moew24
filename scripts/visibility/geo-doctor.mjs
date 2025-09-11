#!/usr/bin/env node
import fs from 'node:fs'; import { z } from 'zod';
const guard = JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
const die=(m)=>{console.error(`[geo:doctor] ${m}`);process.exit(1);};
const readJSON=(p)=>{if(!fs.existsSync(p)) die(`Missing ${p}`); return JSON.parse(fs.readFileSync(p,'utf8'));};

for (const f of guard.geo.requiredFiles) if (!fs.existsSync(f)) die(`Missing ${f}`);

const Areas = z.object({ clusters: z.array(z.object({ slug: z.string(), suburbs: z.array(z.object({ slug: z.string(), name: z.string(), lat: z.number().optional(), lng: z.number().optional() })) })) });
const Adj   = z.record(z.string(), z.array(z.string()));
const MapZ  = z.record(z.string(), z.string());
const Cfg   = z.object({ nearby: z.object({ limit: z.number().int().positive().default(6) }) });

const areas = Areas.parse(readJSON('src/data/areas.clusters.json'));
const adj   = Adj.parse(readJSON('src/data/areas.adj.json'));
const cmap  = MapZ.parse(readJSON('src/data/cluster_map.json'));
Cfg.parse(readJSON('src/data/geo.config.json'));

const knownSuburbs = new Set(areas.clusters.flatMap(c => c.suburbs.map(s=>s.slug.toLowerCase())));
const knownClusters = new Set(areas.clusters.map(c => c.slug.toLowerCase()));
for (const s of Object.keys(cmap)) if (!knownClusters.has(s.toLowerCase())) die(`cluster_map.json references unknown cluster: ${s}`);

let missingAdj=0; for (const s of knownSuburbs) if (!adj[s]) missingAdj++;
if (missingAdj>0) console.warn(`[geo:doctor] ${missingAdj} suburb(s) missing adjacency (non-fatal)`);

// Emit service×suburb smoke paths
function slugify(s){return String(s).trim().toLowerCase().replace(/[^\p{L}\p{N}]+/gu,'-').replace(/^-+|-+$/g,'');}
const perCluster = guard.geo.smokePerCluster || 4;
const maxPaths = guard.geo.maxPathsPerService || 16;
const services = guard.geo.servicesMustExist || ['spring-clean','bathroom-deep-clean'];
const paths = [];
for (const svc of services) {
  const bag = [];
  for (const c of areas.clusters) { for (const s of c.suburbs.slice(0,perCluster)) { bag.push(`/services/${svc}/${slugify(s.slug)}/`); if (bag.length>=maxPaths) break; } if (bag.length>=maxPaths) break; }
  paths.push(...bag);
}
fs.mkdirSync('tmp',{recursive:true}); fs.writeFileSync('tmp/smoke-paths.json', JSON.stringify({ paths }, null, 2));
console.log(`[geo:doctor] OK — ${paths.length} paths → tmp/smoke-paths.json`);
