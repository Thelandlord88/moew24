#!/usr/bin/env node
/**
 * Daedalus Policy Sweeper (tiny)
 * Evaluates ± deltas on current weights, ranks by fairness (inbound Gini),
 * locality (avg linked distance), and cluster-purity (intra-cluster %).
 *
 * Usage:
 *   node scripts/daedalus/tools/policy-sweeper.mjs
 *   node scripts/daedalus/tools/policy-sweeper.mjs --variants=small  # (default) ±5%, ±15%, distance ±2/±5km
 *   node scripts/daedalus/tools/policy-sweeper.mjs --variants=medium # ±5/10/20%, distance ±2/±5/±8km
 *   node scripts/daedalus/tools/policy-sweeper.mjs --json            # print JSON to stdout
 *
 * Outputs:
 *   __reports/daedalus/policy.sweep.json
 *   __reports/daedalus/policy.sweep.md (top picks)
 */
import path from 'node:path';
import { readFile, writeFile, mkdir } from 'node:fs/promises';

function toRad(d){ return d * Math.PI / 180; }
function haversineKm(a, b){
  if (!a || !b) return null;
  const R = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat), lat2 = toRad(b.lat);
  const s1 = Math.sin(dLat/2), s2 = Math.sin(dLon/2);
  const h = s1*s1 + Math.cos(lat1)*Math.cos(lat2)*s2*s2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}
function gini(values){
  const arr = values.map(v => Number(v) || 0).filter(v => v>=0).sort((a,b)=>a-b);
  const n = arr.length;
  if (!n) return 0;
  const sum = arr.reduce((a,b)=>a+b,0);
  if (sum === 0) return 0;
  let cum = 0, area = 0;
  for (let i=0;i<n;i++){
    cum += arr[i];
    area += cum;
  }
  // Gini = (n+1 - 2*area/sum)/n
  return (n + 1 - 2*area/sum) / n;
}

async function loadJSON(p){ return JSON.parse(await readFile(p, 'utf8')); }

function clone(x){ return JSON.parse(JSON.stringify(x)); }

// Load existing project context
async function createContext() {
  const root = process.cwd();
  const cfg = await loadJSON(path.join(root, 'daedalus.config.json'));
  const clusters = await loadJSON(path.join(root, 'src/data/areas.clusters.json'));
  const adj = await loadJSON(path.join(root, 'src/data/areas.adj.json'));
  let meta = {};
  try { meta = await loadJSON(path.join(root, 'src/data/suburbs.meta.json')); } catch {}
  const suburbKeys = clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters);
  const clusterOf = clusters.clusterOf || {};
  // Build targets (service×suburb) for the first (or all) services to keep runtime tiny
  const services = cfg.services || [];
  const primarySvc = services[0]?.id || 'bond-cleaning';
  const targets = suburbKeys.map(s => ({ service: primarySvc, suburb: s }));
  return { root, cfg, clusters, clusterOf, adj, meta, services, primarySvc, targets };
}

function variantsFrom(cfg, mode='small'){
  const base = cfg.policies?.scoring || {};
  const dScale = base.distanceScaleKm ?? 10;
  const w = {
    weightCluster: base.weightCluster ?? 1.0,
    weightDistance: base.weightDistance ?? 1.0,
    weightReciprocalEdge: base.weightReciprocalEdge ?? 0.5,
    weightHubDamping: base.weightHubDamping ?? 0.5,
    distanceScaleKm: dScale
  };
  const scales = mode==='medium' ? [0.8, 0.9, 1.0, 1.1, 1.2] : [0.85, 0.95, 1.0, 1.05, 1.15];
  const dVariants = mode==='medium' ? [-8,-5,-2,0,2,5,8] : [-5,-2,0,2,5];
  const out = [];
  for (const k of ['weightCluster','weightDistance','weightReciprocalEdge','weightHubDamping']){
    for (const s of scales){
      const v = clone(w);
      v[k] = Number((w[k]*s).toFixed(4));
      out.push({ kind:`tweak:${k}`, weights:v });
    }
  }
  for (const d of dVariants){
    const v = clone(w);
    v.distanceScaleKm = Math.max(1, Math.round(w.distanceScaleKm + d));
    out.push({ kind:`tweak:distanceScaleKm`, weights:v });
  }
  // A couple combos
  const combo1 = clone(w); combo1.weightDistance = Number((w.weightDistance*1.1).toFixed(4)); combo1.weightHubDamping = Number((w.weightHubDamping*1.1).toFixed(4));
  out.push({ kind:'combo:distance+hub', weights:combo1 });
  const combo2 = clone(w); combo2.weightCluster = Number((w.weightCluster*1.1).toFixed(4)); combo2.distanceScaleKm = Math.max(1, Math.round(w.distanceScaleKm-2));
  out.push({ kind:'combo:cluster+local', weights:combo2 });
  // Always include baseline
  out.unshift({ kind:'baseline', weights:w });
  // Dedup by signature
  const seen = new Set();
  return out.filter(v => {
    const sig = JSON.stringify(v.weights);
    if (seen.has(sig)) return false;
    seen.add(sig); return true;
  });
}

async function runInternalLinks(ctx, weights){
  // Dynamically import the policy engine plugin
  const pluginPath = path.join(ctx.root, 'scripts/daedalus/plugins/05-internal-links.mjs');
  const plugin = (await import(pluginPath)).default;
  const fakeCtx = {
    root: ctx.root,
    config: clone(ctx.cfg),
    datasets: { clusters: ctx.clusters, adj: ctx.adj, meta: ctx.meta, services: ctx.services },
    targets: ctx.targets,
    reports: { links: [] },
    args: {}
  };
  // Inject weights
  fakeCtx.config.policies = fakeCtx.config.policies || {};
  fakeCtx.config.policies.scoring = clone(weights);
  fakeCtx.config.policies.neighborsMax = fakeCtx.config.policies.neighborsMax ?? 6;
  fakeCtx.config.policies.neighborsMin = fakeCtx.config.policies.neighborsMin ?? Math.min(3, fakeCtx.config.policies.neighborsMax);
  fakeCtx.config.policies.globalInboundCap = fakeCtx.config.policies.globalInboundCap ?? Infinity;
  fakeCtx.config.policies.enforceReciprocity = fakeCtx.config.policies.enforceReciprocity ?? false;

  // Execute plugin
  if (plugin.beforeAll) await plugin.beforeAll(fakeCtx);
  if (plugin.eachNode) {
    for (const node of fakeCtx.targets) await plugin.eachNode(fakeCtx, node);
  }
  if (plugin.afterAll) await plugin.afterAll(fakeCtx);
  return fakeCtx;
}

function computeMetrics(ctx, selected){
  const clusters = ctx.clusters;
  const clusterOf = ctx.clusterOf || {};
  const meta = ctx.meta || {};
  const inbound = {}; // neighbor suburb -> inbound count
  let distSum = 0, distCount = 0;
  let sameCluster = 0, totalLinks = 0;

  for (const { service, suburb, neighbors } of selected) {
    for (const n of neighbors || []) {
      inbound[n] = (inbound[n] || 0) + 1;
      totalLinks++;
      const a = meta[suburb]?.coordinates;
      const b = meta[n]?.coordinates;
      const d = haversineKm(a, b);
      if (d != null) { distSum += d; distCount++; }
      if ((clusterOf[suburb] || '') === (clusterOf[n] || '')) sameCluster++;
    }
  }
  const giniVal = gini(Object.values(inbound));
  const avgKm = distCount ? (distSum / distCount) : null;
  const purity = totalLinks ? (sameCluster / totalLinks) : 0;
  return { gini: Number(giniVal.toFixed(4)), avgKm: avgKm==null? null : Number(avgKm.toFixed(2)), clusterPurity: Number(purity.toFixed(4)), totalLinks };
}

function describe(weights){
  return Object.fromEntries(Object.entries(weights).map(([k,v]) => [k, Number(v)]));
}

async function main(){
  const args = Object.fromEntries(process.argv.slice(2).map(a => a.split('=')));
  const variantMode = (args['--variants'] || 'small');
  const printJson = ('--json' in args);
  const ctx = await createContext();
  const variants = variantsFrom(ctx.cfg, variantMode);

  const results = [];
  for (const v of variants) {
    const run = await runInternalLinks(ctx, v.weights);
    const metrics = computeMetrics(ctx, run.reports.links || []);
    results.push({
      kind: v.kind,
      weights: describe(v.weights),
      metrics
    });
  }

  // Rank: fairness asc, avgKm asc (null last), clusterPurity desc
  results.sort((a,b) => {
    const g = a.metrics.gini - b.metrics.gini;
    if (g !== 0) return g;
    const da = a.metrics.avgKm==null ? 1e9 : a.metrics.avgKm;
    const db = b.metrics.avgKm==null ? 1e9 : b.metrics.avgKm;
    if (da !== db) return da - db;
    return b.metrics.clusterPurity - a.metrics.clusterPurity;
  });

  const top = results.slice(0, 10);
  const payload = {
    generatedAt: new Date().toISOString(),
    service: ctx.primarySvc,
    variantsTried: results.length,
    ranking: results
  };

  await mkdir('__reports/daedalus', { recursive: true });
  await writeFile('__reports/daedalus/policy.sweep.json', JSON.stringify(payload, null, 2));

  const md = ['# Policy Sweeper (Tiny) — Results', '', `Service: **${ctx.primarySvc}**`, `Variants tried: **${results.length}**`, '', '## Top Suggestions'];
  md.push('| Rank | Kind | weightCluster | weightDistance | distanceScaleKm | weightReciprocalEdge | weightHubDamping | Gini (↓) | Avg km (↓) | Purity (↑) |');
  md.push('|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|');
  top.forEach((r, i) => {
    const w = r.weights, m = r.metrics;
    md.push(`| ${i+1} | ${r.kind} | ${w.weightCluster} | ${w.weightDistance} | ${w.distanceScaleKm} | ${w.weightReciprocalEdge} | ${w.weightHubDamping} | ${m.gini} | ${m.avgKm ?? 'n/a'} | ${m.clusterPurity} |`);
  });
  await writeFile('__reports/daedalus/policy.sweep.md', md.join('\n'));

  if (printJson) {
    process.stdout.write(JSON.stringify(payload, null, 2) + '\n');
  } else {
    console.log('Wrote __reports/daedalus/policy.sweep.json and policy.sweep.md');
  }
}

main().catch(e => { console.error(e); process.exit(1); });
