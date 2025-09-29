#!/usr/bin/env node
/**
 * page-context.mjs — builds src/gen/geoPageContext.ts + reports
 * Robust path fallbacks; deterministic outputs; respects tiers.
 */
import fs from 'node:fs';
import path from 'node:path';

const args = new Map();
for (let i=2;i<process.argv.length;i++){const a=process.argv[i];if(a.startsWith('--')){const[k,v]=a.includes('=')?a.slice(2).split('='):[a.slice(2),true];args.set(k,v===undefined?true:v);}}
const ROOT = path.resolve(args.get('root') || '.');
function read(p){ return JSON.parse(fs.readFileSync(path.join(ROOT, p),'utf8')); }
function tryRead(p){ try{ return read(p); }catch{ return null; } }
function readFirst(cands){ for(const c of cands){ try{ return read(c); }catch{} } throw new Error("Missing inputs: "+cands.join(" | ")); }

const CONFIG = readFirst(["config/geo.linking.config.json"]);
const adjacency = readFirst(["data/adjacency.json","map data/adjacency.json"]);
const clusters = readFirst(["data/areas.extended.clusters.json","map data/areas.extended.clusters.json","map data/areas.clusters.json"]);
const meta = readFirst(["src/data/suburbs.meta.json"]);
const coverage = readFirst(["data/serviceCoverage.json","map data/serviceCoverage.json"]);
const templates = tryRead(CONFIG.anchorTemplatesFile || "config/anchor.templates.json") || [];

function slugify(s){ return String(s).toLowerCase(); }
const tiersAllowed = new Set(CONFIG.allowedTiersForPages || ['core','expansion']);
const coverageSet = new Set(Object.values(coverage||{}).flat().map(slugify));
const hasPage = new Set([...coverageSet].filter(s => tiersAllowed.has((meta.nodes?.[s]?.tier)||'support')));

// Build cluster map
const clusterMap = new Map();
if (Array.isArray(clusters?.clusters)) for (const c of clusters.clusters) clusterMap.set(c.name, new Set((c.suburbs||[]).map(slugify)));
else for (const [k,v] of Object.entries(clusters||{})) clusterMap.set(k, new Set((v||[]).map(slugify)));

function clusterOf(slug){ for (const [k,set] of clusterMap.entries()) if (set.has(slug)) return k; return null; }

function seededShuffle(arr, seedStr){
  // xorshift32-like deterministic shuffle
  let seed = 0; for (let i=0;i<seedStr.length;i++) seed = (seed ^ seedStr.charCodeAt(i)) >>> 0;
  const a = arr.slice();
  for (let i=a.length-1;i>0;i--){ seed ^= seed<<13; seed ^= seed>>>17; seed ^= seed<<5; const j = (seed>>>0) % (i+1); [a[i],a[j]]=[a[j],a[i]]; }
  return a;
}

const ctx = {};
const perPage = {};
let totalPrimary = 0, totalSecondary = 0;

const primaryMax = CONFIG.links?.primaryMax ?? 8;
const secondaryMax = CONFIG.links?.secondaryMax ?? 6;
const minPrimaryPerPage = CONFIG.links?.minPrimaryPerPage ?? 3;
const preferSameCluster = !!(CONFIG.neighbor?.preferSameCluster);
const maxCrossCluster = CONFIG.neighbor?.maxCrossCluster ?? 2;

for (const slug of Object.keys(adjacency)) {
  const neighbors = (adjacency[slug]||[]).map(slugify);
  const cName = clusterOf(slug);
  const primaryRaw = neighbors.filter(n => hasPage.has(n));
  const secondaryRaw = neighbors.filter(n => !hasPage.has(n));

  // Prefer same-cluster for primary first
  let primary = primaryRaw;
  if (preferSameCluster && cName){
    const same = primaryRaw.filter(n => clusterOf(n)===cName);
    const cross = primaryRaw.filter(n => clusterOf(n)!==cName);
    primary = same.concat(cross);
  }

  // Enforce cross-cluster limit
  if (cName && maxCrossCluster >= 0){
    let crossCount = 0;
    const filtered = [];
    for (const n of primary){
      const isCross = clusterOf(n)!==cName;
      if (isCross && crossCount>=maxCrossCluster) continue;
      if (isCross) crossCount++;
      filtered.push(n);
    }
    primary = filtered;
  }

  const prim = primary.slice(0, primaryMax);
  const sec = secondaryRaw.slice(0, secondaryMax);

  // Only emit context for actual page slugs
  const willPage = hasPage.has(slug);
  if (!willPage) continue;

  ctx[slug] = { slug, tier: (meta.nodes?.[slug]?.tier)||'support', cluster: cName, neighborsPrimary: prim, neighborsSecondary: sec };

  perPage[slug] = { primary: prim.length, secondary: sec.length, crossCluster: prim.filter(n => clusterOf(n)!==cName).length };
  totalPrimary += prim.length; totalSecondary += sec.length;
}

const OUT_TS = path.join(ROOT, "src/gen/geoPageContext.ts");
const ts = `// Auto-generated\\nexport type GeoPageCtx = { slug: string; tier: string; cluster: string|null; neighborsPrimary: string[]; neighborsSecondary: string[] };\\nexport const GEO_PAGE_CTX: Record<string, GeoPageCtx> = ${JSON.stringify(ctx,null,2)} as const;\\n`;
fs.mkdirSync(path.dirname(OUT_TS), {recursive:true});
fs.writeFileSync(OUT_TS, ts);

const report = {
  generatedAt: new Date().toISOString(),
  summary: {
    pages: Object.keys(ctx).length,
    totals: { primary: totalPrimary, secondary: totalSecondary },
    perPage
  },
  config: CONFIG
};
const REPORT_JSON = path.join(ROOT, "__reports/geo-linking.summary.json");
fs.mkdirSync(path.dirname(REPORT_JSON), {recursive:true});
fs.writeFileSync(REPORT_JSON, JSON.stringify(report, null, 2));

// Optional anchors preview per page (deterministic, from templates)
if (templates.length){
  const anchors = {};
  for (const slug of Object.keys(ctx)){
    const seed = `a-${slug}`;
    const cName = ctx[slug].cluster;
    const fill = (t) => t.replace(/{suburb}/g, slug.replace(/-/g,' ')).replace(/{cluster}/g, String(cName||''));
    const variants = templates.map(t => ({ text: fill(t.text), intent: t.intent, templateId: t.id, href: `/suburbs/${slug}/` }));
    anchors[slug] = seededShuffle(variants, seed).slice(0, 8);
  }
  fs.writeFileSync(path.join(ROOT,"__reports/geo-link-anchors.json"), JSON.stringify(anchors,null,2));
}

console.log("[page-context] wrote src/gen/geoPageContext.ts and __reports/geo-linking.summary.json");
