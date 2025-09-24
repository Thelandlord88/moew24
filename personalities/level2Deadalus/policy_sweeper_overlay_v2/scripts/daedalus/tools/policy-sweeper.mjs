#!/usr/bin/env node
/**
 * Daedalus Policy Sweeper (tiny) — v2
 * Now with: --service, --top, and **HTML report**.
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
  return (n + 1 - 2*area/sum) / n;
}
async function loadJSON(p){ return JSON.parse(await readFile(p, 'utf8')); }
function clone(x){ return JSON.parse(JSON.stringify(x)); }

function parseArgs(argv){
  const args = {};
  for (const a of argv) {
    const [k, v] = a.includes('=') ? a.split('=') : [a, true];
    args[k] = v;
  }
  return args;
}

async function createContext(serviceOverride) {
  const root = process.cwd();
  const cfg = await loadJSON(path.join(root, 'daedalus.config.json'));
  const clusters = await loadJSON(path.join(root, 'src/data/areas.clusters.json'));
  const adj = await loadJSON(path.join(root, 'src/data/areas.adj.json'));
  let meta = {};
  try { meta = await loadJSON(path.join(root, 'src/data/suburbs.meta.json')); } catch {}
  const suburbKeys = clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters);
  const clusterOf = clusters.clusterOf || {};
  const services = cfg.services || [];
  const serviceId = serviceOverride || services[0]?.id || 'bond-cleaning';
  const targets = suburbKeys.map(s => ({ service: serviceId, suburb: s }));
  return { root, cfg, clusters, clusterOf, adj, meta, services, serviceId, targets };
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
  const combo1 = clone(w); combo1.weightDistance = Number((w.weightDistance*1.1).toFixed(4)); combo1.weightHubDamping = Number((w.weightHubDamping*1.1).toFixed(4));
  out.push({ kind:'combo:distance+hub', weights:combo1 });
  const combo2 = clone(w); combo2.weightCluster = Number((w.weightCluster*1.1).toFixed(4)); combo2.distanceScaleKm = Math.max(1, Math.round(w.distanceScaleKm-2));
  out.push({ kind:'combo:cluster+local', weights:combo2 });
  out.unshift({ kind:'baseline', weights:w });
  const seen = new Set();
  return out.filter(v => { const sig = JSON.stringify(v.weights); if (seen.has(sig)) return false; seen.add(sig); return true; });
}

async function runInternalLinks(ctx, weights){
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
  fakeCtx.config.policies = fakeCtx.config.policies || {};
  fakeCtx.config.policies.scoring = clone(weights);
  fakeCtx.config.policies.neighborsMax = fakeCtx.config.policies.neighborsMax ?? 6;
  fakeCtx.config.policies.neighborsMin = fakeCtx.config.policies.neighborsMin ?? Math.min(3, fakeCtx.config.policies.neighborsMax);
  fakeCtx.config.policies.globalInboundCap = fakeCtx.config.policies.globalInboundCap ?? Infinity;
  fakeCtx.config.policies.enforceReciprocity = fakeCtx.config.policies.enforceReciprocity ?? false;
  if (plugin.beforeAll) await plugin.beforeAll(fakeCtx);
  if (plugin.eachNode) for (const node of fakeCtx.targets) await plugin.eachNode(fakeCtx, node);
  if (plugin.afterAll) await plugin.afterAll(fakeCtx);
  return fakeCtx;
}

function computeMetrics(ctx, selected){
  const clusterOf = ctx.clusterOf || {};
  const meta = ctx.meta || {};
  const inbound = {};
  let distSum = 0, distCount = 0;
  let sameCluster = 0, totalLinks = 0;

  for (const { suburb, neighbors } of selected) {
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

function escapeHtml(s){
  return String(s).replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}

async function main(){
  const args = parseArgs(process.argv.slice(2));
  const variantMode = (args['--variants'] || 'small');
  const printJson = ('--json' in args);
  const topN = Number(args['--top'] || 10);
  const serviceOverride = args['--service'];

  const ctx = await createContext(serviceOverride);
  const variants = variantsFrom(ctx.cfg, variantMode);

  const results = [];
  for (const v of variants) {
    const run = await runInternalLinks(ctx, v.weights);
    const metrics = computeMetrics(ctx, run.reports.links || []);
    results.push({ kind: v.kind, weights: describe(v.weights), metrics });
  }

  results.sort((a,b) => {
    const g = a.metrics.gini - b.metrics.gini;
    if (g !== 0) return g;
    const da = a.metrics.avgKm==null ? 1e9 : a.metrics.avgKm;
    const db = b.metrics.avgKm==null ? 1e9 : b.metrics.avgKm;
    if (da !== db) return da - db;
    return b.metrics.clusterPurity - a.metrics.clusterPurity;
  });

  const payload = { generatedAt: new Date().toISOString(), service: ctx.serviceId, variantsTried: results.length, ranking: results };
  await mkdir('__reports/daedalus', { recursive: true });
  await writeFile('__reports/daedalus/policy.sweep.json', JSON.stringify(payload, null, 2));

  const top = results.slice(0, topN);
  const md = ['# Policy Sweeper (Tiny) — Results', '', `Service: **${ctx.serviceId}**`, `Variants tried: **${results.length}**`, '', '## Top Suggestions'];
  md.push('| Rank | Kind | weightCluster | weightDistance | distanceScaleKm | weightReciprocalEdge | weightHubDamping | Gini (↓) | Avg km (↓) | Purity (↑) |');
  md.push('|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|');
  top.forEach((r, i) => {
    const w = r.weights, m = r.metrics;
    md.push(`| ${i+1} | ${r.kind} | ${w.weightCluster} | ${w.weightDistance} | ${w.distanceScaleKm} | ${w.weightReciprocalEdge} | ${w.weightHubDamping} | ${m.gini} | ${m.avgKm ?? 'n/a'} | ${m.clusterPurity} |`);
  });
  await writeFile('__reports/daedalus/policy.sweep.md', md.join('\n'));

  // HTML report
  const rows = top.map((r, i) => {
    const w = r.weights, m = r.metrics;
    return `<tr>
      <td>${i+1}</td>
      <td>${escapeHtml(r.kind)}</td>
      <td>${w.weightCluster}</td>
      <td>${w.weightDistance}</td>
      <td>${w.distanceScaleKm}</td>
      <td>${w.weightReciprocalEdge}</td>
      <td>${w.weightHubDamping}</td>
      <td>${m.gini}</td>
      <td>${m.avgKm ?? 'n/a'}</td>
      <td>${m.clusterPurity}</td>
    </tr>`;
  }).join('\n');

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Policy Sweeper — Top Suggestions</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body{font-family: ui-sans-serif, system-ui; margin: 24px; color:#0b1220}
  h1{font-size: 20px; margin-bottom: 8px}
  .meta{opacity:.75; margin-bottom:16px}
  table{border-collapse: collapse; width:100%}
  th, td{border:1px solid rgba(2,6,23,.1); padding:8px 10px; font-size:14px}
  th{background:#f8fafc; text-align:left}
  tr:hover{background:#f1f5f9}
  .badge{display:inline-block; padding:2px 8px; border-radius:999px; background:#e2e8f0; font-size:12px}
</style>
</head>
<body>
  <h1>Policy Sweeper — Top Suggestions</h1>
  <div class="meta">
    Service: <span class="badge">${escapeHtml(ctx.serviceId)}</span> ·
    Variants tried: <span class="badge">${results.length}</span> ·
    Generated: <span class="badge">${escapeHtml(new Date().toISOString())}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th>#</th><th>Kind</th>
        <th>weightCluster</th><th>weightDistance</th><th>distanceScaleKm</th>
        <th>weightReciprocalEdge</th><th>weightHubDamping</th>
        <th>Gini (↓)</th><th>Avg km (↓)</th><th>Purity (↑)</th>
      </tr>
    </thead>
    <tbody>
      ${rows}
    </tbody>
  </table>
  <p class="meta">Fairness prioritised (Gini), then locality (Avg km), then cluster purity.</p>
</body>
</html>`;
  await writeFile('__reports/daedalus/policy.sweep.html', html, 'utf8');

  if (printJson) {
    process.stdout.write(JSON.stringify(payload, null, 2) + '\n');
  } else {
    console.log('Wrote __reports/daedalus/policy.sweep.json, .md, and .html');
  }
}

main().catch(e => { console.error(e); process.exit(1); });
