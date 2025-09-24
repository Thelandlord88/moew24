#!/usr/bin/env node
/**
 * One‑N‑Done GEO SUITE (best‑of‑best merge from your 10 inputs)
 * Node 20+, zero external deps, idempotent. 
 *
 * Subcommands:
 *   doctor    – validate geo data (suburbs, clusters, adjacency, lat/lon)
 *   build     – compute deterministic proximity snapshot (proximity.json)
 *   guard     – scan dist/ HTML for canonical + JSON‑LD presence (lightweight)
 *   smoke     – generate and probe a small set of canonical pages
 *   report    – print latest report path
 *   all       – doctor → build → guard → smoke
 *
 * Key ideas:
 *  - Deterministic writes only (stable key sorting);
 *  - "Strict" mode for CI via --strict or CI env;
 *  - Auto‑discovery of likely data files; minimal assumptions about structure.
 *
 * Usage:
 *   node scripts/one-n-done.geo-suite.mjs all --root . --out __geo/ --strict
 *   node scripts/one-n-done.geo-suite.mjs doctor --root .
 *   node scripts/one-n-done.geo-suite.mjs build --root .
 *
 * Artifacts:
 *   <out>/geo-doctor.json        – validation summary
 *   <out>/proximity.json         – computed proximity graph
 *   <out>/guard-seo.json         – per-page SEO/JSON‑LD/canonical findings
 *   <out>/smoke.json             – quick page availability check
 *   <out>/REPORT.md              – stitched human summary
 */

import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

// ----------------- CLI  -----------------
const ARGV = new Map();
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  const next = process.argv[i + 1];
  if (a.includes('=')) { const [k, v] = a.split('='); ARGV.set(k, v); }
  else if (a.startsWith('--')) {
    if (next && !next.startsWith('--')) { ARGV.set(a, next); i++; } else { ARGV.set(a, true); }
  } else if (!ARGV.has('_cmd')) { ARGV.set('_cmd', a); }
}
const CMD = ARGV.get('_cmd') || 'all';
const ROOT = path.resolve(ARGV.get('--root') || '.');
const OUTDIR = path.resolve(ROOT, ARGV.get('--out') || '__geo');
const STRICT = ARGV.has('--strict') || process.env.CI;

function rel(p) { return path.relative(ROOT, p).replaceAll('\\', '/'); }
function sha1(s) { return crypto.createHash('sha1').update(s).digest('hex'); }
function ensureDir(p) { if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true }); }

// Stable JSON stringify (keys sorted, arrays untouched)
function stable(obj) {
  if (Array.isArray(obj)) return obj.map(stable);
  if (obj && typeof obj === 'object') {
    return Object.fromEntries(Object.keys(obj).sort().map(k => [k, stable(obj[k])]));
  }
  return obj;
}
async function writeJsonStable(file, data) {
  ensureDir(path.dirname(file));
  const txt = JSON.stringify(stable(data), null, 2) + '\n';
  await fsp.writeFile(file, txt, 'utf8');
  return sha1(txt);
}

// ----------------- Discovery  -----------------
async function tryReadJSON(p) { try { return JSON.parse(await fsp.readFile(p, 'utf8')); } catch { return null; } }
async function discover() {
  const cand = {
    config: [
      'src/content/geo.config.json',
      'src/data/geo.config.json',
      'src/geo/geo.config.json',
    ],
    suburbs: [
      'src/data/suburbs.json',
      'src/data/suburbs.geo.json',
      'src/data/suburbs.geojson',
      'src/data/suburbs_enriched.json',
      'src/data/suburbs_enriched.geojson',
    ],
    adjacency: [
      'src/data/geo.neighbors.json',
      'src/data/geo.neighbors.adj.json',
      'src/data/adjacency.json',
    ],
    clusters: [
      'src/data/areas.clusters.json',
      'src/data/clusters.json',
    ],
    dist: [
      'dist', 'out', '.output/public'
    ]
  };
  const found = {};
  for (const [k, arr] of Object.entries(cand)) {
    for (const p of arr.map(p => path.join(ROOT, p))) {
      if (fs.existsSync(p)) { found[k] = p; break; }
    }
  }
  return found;
}

// ----------------- Geo helpers  -----------------
function asFeatures(input) {
  // Accept GeoJSON or a plain array of suburb records
  if (!input) return [];
  if (input.type === 'FeatureCollection' && Array.isArray(input.features)) return input.features;
  if (Array.isArray(input)) return input.map(x => ({ type: 'Feature', properties: x, geometry: null }));
  return [];
}
function getProps(f) { return f.properties || {}; }
function coordOf(f) {
  const g = f.geometry;
  if (g && g.type === 'Point' && Array.isArray(g.coordinates) && g.coordinates.length >= 2) {
    return { lon: +g.coordinates[0], lat: +g.coordinates[1] };
  }
  const p = getProps(f);
  if (p && typeof p.centroid_lat === 'number' && typeof p.centroid_lon === 'number') {
    return { lon: p.centroid_lon, lat: p.centroid_lat };
  }
  if (p && typeof p.lat === 'number' && typeof p.lon === 'number') {
    return { lon: p.lon, lat: p.lat };
  }
  return null;
}
function haversine(a, b) {
  const toRad = (d) => d * Math.PI / 180;
  const R = 6371; // km
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const s1 = Math.sin(dLat/2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLon/2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(s1), Math.sqrt(1 - s1));
  return R * c;
}

// ----------------- Doctor  -----------------
async function runDoctor(found) {
  const summary = {
    ok: true,
    errors: [],
    warnings: [],
    counts: {},
    details: { duplicates: [], missingCoords: [], adjacencyBreaks: [], clusterGhosts: [] }
  };

  const cfg = found.config ? await tryReadJSON(found.config) : null;
  const suburbsRaw = found.suburbs ? await tryReadJSON(found.suburbs) : null;
  const features = asFeatures(suburbsRaw);
  summary.counts.suburbs = features.length;

  // Basic uniqueness by slug or name
  const byKey = new Map();
  for (const f of features) {
    const p = getProps(f);
    const key = (p.slug || p.name_official || p.name || '').trim().toLowerCase();
    if (!key) continue;
    if (byKey.has(key)) {
      summary.details.duplicates.push({ a: byKey.get(key), b: p });
      summary.ok = false;
    } else {
      byKey.set(key, p);
    }
    if (!coordOf(f)) summary.details.missingCoords.push(p.slug || p.name);
  }
  if (summary.details.missingCoords.length) {
    summary.warnings.push(`${summary.details.missingCoords.length} suburb(s) missing lat/lon`);
  }

  // Adjacency reciprocity
  if (found.adjacency) {
    const adj = await tryReadJSON(found.adjacency);
    summary.counts.adjacencyPairs = 0;
    const adjMap = new Map(Object.entries(adj || {}));
    for (const [a, list] of adjMap.entries()) {
      for (const b of list || []) {
        summary.counts.adjacencyPairs++;
        const back = (adjMap.get(String(b)) || []).includes(a);
        if (!back) {
          summary.details.adjacencyBreaks.push({ a, b });
          summary.ok = false;
        }
      }
    }
    if (summary.details.adjacencyBreaks.length) {
      summary.errors.push(`${summary.details.adjacencyBreaks.length} non‑reciprocal adjacency edge(s)`);
    }
  }

  // Cluster membership sanity
  if (found.clusters) {
    const clusters = await tryReadJSON(found.clusters);
    const allMembers = new Set();
    for (const [cluster, arr] of Object.entries(clusters || {})) {
      for (const s of arr || []) allMembers.add(String(s).toLowerCase());
    }
    for (const key of byKey.keys()) {
      if (!allMembers.has(key)) summary.details.clusterGhosts.push(key);
    }
    if (summary.details.clusterGhosts.length) summary.warnings.push(`${summary.details.clusterGhosts.length} suburb(s) not in any cluster`);
  }

  // Config sanity
  if (!cfg) summary.warnings.push('geo.config.json not found (best effort discovery).');

  summary.ok = summary.ok && summary.errors.length === 0;
  const file = path.join(OUTDIR, 'geo-doctor.json');
  const hash = await writeJsonStable(file, summary);
  return { file, hash, summary };
}

// ----------------- Build proximity  -----------------
async function runBuild(found) {
  const suburbsRaw = found.suburbs ? await tryReadJSON(found.suburbs) : null;
  const features = asFeatures(suburbsRaw);
  const list = [];
  for (const f of features) {
    const p = getProps(f);
    const c = coordOf(f);
    if (!p) continue;
    list.push({ key: (p.slug || p.name_official || p.name || '').toLowerCase(), coord: c, props: p });
  }
  // Compute nearest N for each with coords
  const N = Number(ARGV.get('--k') || 8);
  const prox = {};
  for (const a of list) {
    if (!a.coord) continue;
    const ranked = list
      .filter(b => b !== a && !!b.coord)
      .map(b => ({ key: b.key, km: haversine(a.coord, b.coord) }))
      .sort((x, y) => x.km - y.km)
      .slice(0, N);
    prox[a.key] = ranked.map(r => ({ key: r.key, km: Math.round(r.km * 10) / 10 }));
  }
  const file = path.join(OUTDIR, 'proximity.json');
  const hash = await writeJsonStable(file, prox);
  return { file, hash, count: Object.keys(prox).length };
}

// ----------------- Guard SEO (dist scan) -----------------
async function runGuard(found) {
  const dist = found.dist && fs.existsSync(found.dist) ? found.dist : null;
  const out = { dist: rel(dist || '(missing)'), pages: [], warnings: [] };
  if (!dist) { out.warnings.push('No dist/ found; run a build first.'); }
  else {
    // Walk dist and sample up to 500 HTML files
    const htmls = [];
    const stack = [dist];
    while (stack.length) {
      const d = stack.pop();
      const entries = await fsp.readdir(d, { withFileTypes: true });
      for (const e of entries) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) stack.push(p);
        else if (e.isFile() && e.name.endsWith('.html')) htmls.push(p);
      }
      if (htmls.length > 500) break;
    }
    for (const p of htmls) {
      const html = await fsp.readFile(p, 'utf8');
      const hasCanonical = /<link[^>]+rel=["']canonical["'][^>]*>/i.test(html);
      const hasLd = /<script[^>]+type=["']application\/ld\+json["'][^>]*>/i.test(html);
      out.pages.push({ file: rel(p), canonical: hasCanonical, jsonld: hasLd });
    }
    if (!out.pages.length) out.warnings.push('No HTML files found in dist/.');
  }
  const file = path.join(OUTDIR, 'guard-seo.json');
  const hash = await writeJsonStable(file, out);
  return { file, hash, count: out.pages.length };
}

// ----------------- Smoke (page availability) -----------------
async function runSmoke(found) {
  const doc = await tryReadJSON(path.join(OUTDIR, 'geo-doctor.json'));
  const prox = await tryReadJSON(path.join(OUTDIR, 'proximity.json'));
  const dist = found.dist && fs.existsSync(found.dist) ? found.dist : null;
  const sample = new Set();
  // Seeds: take first 5 keys from proximity and craft service/suburb paths
  if (prox) {
    for (const key of Object.keys(prox).slice(0, 5)) {
      sample.add(`/suburbs/${key}/`);
      sample.add(`/services/spring-clean/${key}/`);
      sample.add(`/services/bathroom-deep-clean/${key}/`);
    }
  }
  const res = [];
  for (const url of sample) {
    const file = path.join(dist || '', url.replace(/^\//, ''), 'index.html');
    const exists = !!(dist && fs.existsSync(file));
    res.push({ url, exists, file: dist ? rel(file) : '(no dist)'});
  }
  const out = { total: res.length, ok: res.filter(x => x.exists).length, results: res };
  const file = path.join(OUTDIR, 'smoke.json');
  const hash = await writeJsonStable(file, out);
  return { file, hash, count: out.ok };
}

// ----------------- REPORT  -----------------
async function writeReport(pieces) {
  const lines = [];
  lines.push('# GEO Suite Report');
  lines.push(`Root: ${rel(ROOT)}  `);
  lines.push(`Generated: ${new Date().toLocaleString()}`);
  lines.push('');
  for (const p of pieces) {
    if (!p) continue;
    lines.push(`## ${p.title}`);
    for (const k of Object.keys(p.kv || {})) lines.push(`- **${k}:** ${p.kv[k]}`);
    if (p.path) lines.push(`- **file:** \`${rel(p.path)}\``);
    if (p.extra) lines.push('', p.extra, '');
  }
  const file = path.join(OUTDIR, 'REPORT.md');
  ensureDir(path.dirname(file));
  await fsp.writeFile(file, lines.join('\n'), 'utf8');
  return file;
}

// ----------------- Main orchestration -----------------
async function main() {
  ensureDir(OUTDIR);
  const found = await discover();
  const pcs = [];

  const map = {
    async doctor() {
      const r = await runDoctor(found);
      pcs.push({ title: 'Doctor', kv: { ok: r.summary.ok, suburbs: r.summary.counts.suburbs||0 }, path: r.file });
    },
    async build() {
      const r = await runBuild(found);
      pcs.push({ title: 'Build Proximity', kv: { nodes: r.count }, path: r.file });
    },
    async guard() {
      const r = await runGuard(found);
      pcs.push({ title: 'Guard SEO', kv: { pagesScanned: r.count }, path: r.file });
    },
    async smoke() {
      const r = await runSmoke(found);
      pcs.push({ title: 'Smoke', kv: { ok: r.count }, path: r.file });
    },
    async report() { /* no-op here; handled at end */ },
    async all() { await map.doctor(); await map.build(); await map.guard(); await map.smoke(); },
  };

  if (!map[CMD]) { console.error(`Unknown command: ${CMD}`); process.exit(2); }
  await map[CMD]();

  const report = await writeReport(pcs);
  console.log(`[geo-suite] Done. Report: ${rel(report)}`);
}

main().catch((e) => { console.error('[geo-suite] Failed:', e); process.exit(1); });
