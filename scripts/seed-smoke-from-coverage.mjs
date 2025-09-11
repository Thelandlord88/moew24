#!/usr/bin/env node
/**
 * seed-smoke-from-coverage.mjs
 * Generates __geo/smoke.seeds.json from live coverage config.
 * Looks for (in order):
 *   - src/data/serviceCoverage.json  (Object<serviceId, string[] suburbSlugs>)
 *   - src/data/areas.clusters.json + src/data/suburbs*.{json,geojson}
 * Fallback services: ['spring-clean','bathroom-deep-clean']
 */
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.argv[2] || '.';
const OUTDIR = path.join(ROOT, '__geo');
const ensure = (p)=>{fs.mkdirSync(p,{recursive:true})};
const rel = (p)=>path.relative(ROOT,p).replaceAll('\\','/');

async function readJson(p){ try { return JSON.parse(await fsp.readFile(p,'utf8')); } catch { return null; } }
function asFeatures(input){ if(!input) return []; if(input.type==='FeatureCollection') return input.features||[]; if(Array.isArray(input)) return input.map(x=>({type:'Feature',properties:x,geometry:null})); return []; }
function propsOf(f){ return f.properties||{}; }

async function findFirst(paths){ for (const p of paths){ const abs=path.join(ROOT,p); if (fs.existsSync(abs)) return abs; } return null; }

const svcCoveragePath = await findFirst(['src/data/serviceCoverage.json']);
const clustersPath = await findFirst(['src/data/areas.clusters.json','src/data/clusters.json']);
const suburbsPath = await findFirst(['src/data/suburbs_enriched.geojson','src/data/suburbs.geojson','src/data/suburbs_enriched.json','src/data/suburbs.json']);

const servicesDefault = ['spring-clean','bathroom-deep-clean'];

const seeds = new Set();
if (svcCoveragePath) {
  const cov = await readJson(svcCoveragePath);
  for (const [svc, arr] of Object.entries(cov||{})) {
    for (const sub of (arr||[])) {
      const s = String(sub).toLowerCase();
      seeds.add(`/services/${svc}/${s}/`);
      seeds.add(`/suburbs/${s}/`);
    }
  }
} else {
  // Build from clusters + suburb list
  const clusters = clustersPath ? (await readJson(clustersPath)) : {};
  const features = suburbsPath ? asFeatures(await readJson(suburbsPath)) : [];
  const allSubs = new Set();
  for (const f of features) {
    const p = propsOf(f); const key = (p.slug||p.name_official||p.name||'').toLowerCase().trim();
    if (key) allSubs.add(key);
  }
  const sampleSubs = Array.from(allSubs).slice(0, 50); // cap
  for (const svc of servicesDefault) {
    for (const s of sampleSubs) {
      seeds.add(`/services/${svc}/${s}/`);
    }
  }
  for (const s of sampleSubs) seeds.add(`/suburbs/${s}/`);
}

ensure(OUTDIR);
const outFile = path.join(OUTDIR,'smoke.seeds.json');
await fsp.writeFile(outFile, JSON.stringify(Array.from(seeds).sort(), null, 2)+'\n','utf8');
console.log(rel(outFile));
