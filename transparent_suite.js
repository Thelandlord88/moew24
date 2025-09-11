#!/usr/bin/env node
/**
 * Transparent Suite (merged best-of-best) — No Grey Layer
 * Node ≥20, no external deps, idempotent, repo‑local.
 *
 * Subcommands
 *   bootstrap           – wire package.json scripts, engines, netlify.toml NODE_VERSION=20
 *   geo:doctor          – validate geo data (duplicates, coords, adjacency reciprocity, cluster ghosts)
 *   geo:build           – build deterministic proximity.json (Haversine, stable JSON)
 *   geo:guard           – scan dist/ *.html for canonical + JSON‑LD presence
 *   geo:smoke           – probe a small set of /suburbs/:slug and /services/:service/:slug pages in dist/
 *   geo:all             – doctor → build → guard → smoke → report
 *   vis:ci              – post‑build visibility pack (guard + snapshot + strict gates)
 *   report              – print path to last REPORT.md
 *
 * Usage examples
 *   node scripts/transparent-suite.mjs bootstrap --root .
 *   node scripts/transparent-suite.mjs geo:all --root . --out __geo --strict
 *   node scripts/transparent-suite.mjs vis:ci --root . --out __geo --strict
 *
 * Artifacts
 *   <out>/geo-doctor.json    – validation summary
 *   <out>/proximity.json     – computed proximity graph
 *   <out>/guard-seo.json     – canonical/JSON‑LD scan over dist/
 *   <out>/smoke.json         – basic existence checks for sampled pages
 *   <out>/REPORT.md          – stitched human report
 *   <out>/snapshot.json      – vis:ci snapshot for CI
 */

import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

// ---------- CLI ----------
const ARGV = new Map();
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  const next = process.argv[i + 1];
  if (a.includes('=')) { const [k, v] = a.split('='); ARGV.set(k, v); }
  else if (a.startsWith('--')) {
    if (next && !next.startsWith('--')) { ARGV.set(a, next); i++; } else { ARGV.set(a, true); }
  } else if (!ARGV.has('_cmd')) { ARGV.set('_cmd', a); }
}
const CMD = ARGV.get('_cmd') || 'geo:all';
const ROOT = path.resolve(ARGV.get('--root') || '.');
const OUTDIR = path.resolve(ROOT, ARGV.get('--out') || '__geo');
const STRICT = ARGV.has('--strict') || process.env.CI;

function rel(p) { return path.relative(ROOT, p).replaceAll('\\', '/'); }
function ensureDir(p) { if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true }); }
function sha1(s) { return crypto.createHash('sha1').update(s).digest('hex'); }

// Stable JSON: sort object keys only (arrays untouched)
function stable(obj) {
  if (Array.isArray(obj)) return obj.map(stable);
  if (obj && typeof obj === 'object') return Object.fromEntries(Object.keys(obj).sort().map(k => [k, stable(obj[k])]));
  return obj;
}
async function writeJson(file, data) {
  ensureDir(path.dirname(file));
  const txt = JSON.stringify(stable(data), null, 2) + '\n';
  await fsp.writeFile(file, txt, 'utf8');
  return sha1(txt);
}
async function readJson(p) { try { return JSON.parse(await fsp.readFile(p, 'utf8')); } catch { return null; } }

// ---------- Discovery ----------
async function discover() {
  const cand = {
    config: [
      'src/content/geo.config.json',
      'src/data/geo.config.json',
      'src/geo/geo.config.json',
    ],
    suburbs: [
      'src/data/suburbs_enriched.geojson',
      'src/data/suburbs.geojson',
      'src/data/suburbs_enriched.json',
      'src/data/suburbs.json',
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
    dist: [ 'dist', 'out', '.output/public' ],
  };
  const found = {};
  for (const [k, arr] of Object.entries(cand)) {
    for (const p of arr.map(x => path.join(ROOT, x))) {
      if (fs.existsSync(p)) { found[k] = p; break; }
    }
  }
  return found;
}

// ---------- Geo utils ----------
function asFeatures(input) {
  if (!input) return [];
  if (input.type === 'FeatureCollection' && Array.isArray(input.features)) return input.features;
  if (Array.isArray(input)) return input.map(x => ({ type: 'Feature', properties: x, geometry: null }));
  return [];
}
function propsOf(f) { return f.properties || {}; }
function coordOf(f) {
  const g = f.geometry;
  if (g && g.type === 'Point' && Array.isArray(g.coordinates) && g.coordinates.length >= 2) {
    return { lon: +g.coordinates[0], lat: +g.coordinates[1] };
  }
  const p = propsOf(f);
  if (typeof p.centroid_lat === 'number' && typeof p.centroid_lon === 'number') return { lon: p.centroid_lon, lat: p.centroid_lat };
  if (typeof p.lat === 'number' && typeof p.lon === 'number') return { lon: p.lon, lat: p.lat };
  return null;
}
function haversine(a, b) {
  const R = 6371, d2r = (d) => d * Math.PI / 180;
  const dLat = d2r(b.lat - a.lat), dLon = d2r(b.lon - a.lon);
  const s1 = Math.sin(dLat/2)**2 + Math.cos(d2r(a.lat))*Math.cos(d2r(b.lat))*Math.sin(dLon/2)**2;
  return 2 * R * Math.atan2(Math.sqrt(s1), Math.sqrt(1 - s1));
}

// ---------- Doctor ----------
async function runDoctor(found) {
  const summary = { ok: true, errors: [], warnings: [], counts: {}, details: { duplicates: [], missingCoords: [], adjacencyBreaks: [], clusterGhosts: [] } };
  const cfg = found.config ? await readJson(found.config) : null;
  const raw = found.suburbs ? await readJson(found.suburbs) : null;
  const feats = asFeatures(raw);
  summary.counts.suburbs = feats.length;

  const byKey = new Map();
  for (const f of feats) {
    const p = propsOf(f);
    const key = (p.slug || p.name_official || p.name || '').trim().toLowerCase();
    if (!key) continue;
    if (byKey.has(key)) { summary.details.duplicates.push({ a: byKey.get(key), b: p }); summary.ok = false; }
    else byKey.set(key, p);
    if (!coordOf(f)) summary.details.missingCoords.push(key);
  }
  if (summary.details.missingCoords.length) summary.warnings.push(`${summary.details.missingCoords.length} suburb(s) missing lat/lon`);

  if (found.adjacency) {
    const adj = await readJson(found.adjacency) || {};
    const adjMap = new Map(Object.entries(adj));
    let breaks = 0, pairs = 0;
    for (const [a, list] of adjMap.entries()) {
      for (const b of list || []) { pairs++; if (!((adjMap.get(String(b)) || []).includes(a))) { summary.details.adjacencyBreaks.push({ a, b }); breaks++; } }
    }
    summary.counts.adjacencyPairs = pairs;
    if (breaks) { summary.errors.push(`${breaks} non‑reciprocal adjacency edge(s)`); summary.ok = false; }
  }

  if (found.clusters) {
    const clusters = await readJson(found.clusters) || {};
    const members = new Set();
    for (const arr of Object.values(clusters)) for (const m of (arr || [])) members.add(String(m).toLowerCase());
    for (const key of byKey.keys()) if (!members.has(key)) summary.details.clusterGhosts.push(key);
    if (summary.details.clusterGhosts.length) summary.warnings.push(`${summary.details.clusterGhosts.length} suburb(s) not in any cluster`);
  }
  if (!cfg) summary.warnings.push('geo.config.json not found');

  summary.ok = summary.ok && summary.errors.length === 0;
  const file = path.join(OUTDIR, 'geo-doctor.json');
  const hash = await writeJson(file, summary);
  return { file, hash, summary };
}

// ---------- Build proximity ----------
async function runBuild(found) {
  const raw = found.suburbs ? await readJson(found.suburbs) : null;
  const feats = asFeatures(raw);
  const list = [];
  for (const f of feats) {
    const p = propsOf(f), c = coordOf(f);
    const key = (p.slug || p.name_official || p.name || '').toLowerCase();
    if (!key) continue; list.push({ key, coord: c });
  }
  const N = Number(ARGV.get('--k') || 8);
  const prox = {};
  for (const a of list) {
    if (!a.coord) continue;
    const ranked = list.filter(b => b !== a && b.coord)
      .map(b => ({ key: b.key, km: haversine(a.coord, b.coord) }))
      .sort((x, y) => x.km - y.km).slice(0, N)
      .map(r => ({ key: r.key, km: Math.round(r.km * 10) / 10 }));
    prox[a.key] = ranked;
  }
  const file = path.join(OUTDIR, 'proximity.json');
  const hash = await writeJson(file, prox);
  return { file, hash, count: Object.keys(prox).length };
}

// ---------- Guard SEO (dist scan) ----------
async function runGuard(found) {
  const dist = found.dist && fs.existsSync(found.dist) ? found.dist : null;
  const out = { dist: rel(dist || '(missing)'), pages: [], warnings: [] };
  if (!dist) { out.warnings.push('No dist/ found; run a build first.'); }
  else {
    const htmls = [];
    const stack = [dist];
    while (stack.length) {
      const d = stack.pop();
      const ents = await fsp.readdir(d, { withFileTypes: true });
      for (const e of ents) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) stack.push(p);
        else if (e.isFile() && e.name.endsWith('.html')) htmls.push(p);
      }
      if (htmls.length > 800) break; // cap
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
  const hash = await writeJson(file, out);
  return { file, hash, count: out.pages.length };
}

// ---------- Smoke ----------
async function runSmoke(found) {
  const prox = await readJson(path.join(OUTDIR, 'proximity.json'));
  const dist = found.dist && fs.existsSync(found.dist) ? found.dist : null;
  const sample = new Set();
  if (prox) {
    for (const key of Object.keys(prox).slice(0, 8)) {
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
  const hash = await writeJson(file, out);
  return { file, hash, count: out.ok };
}

// ---------- REPORT ----------
async function writeReport(parts) {
  const lines = [];
  lines.push('# Transparent Suite Report');
  lines.push(`Root: ${rel(ROOT)}`);
  lines.push(`Generated: ${new Date().toLocaleString()}`);
  lines.push('');
  for (const p of parts) {
    if (!p) continue;
    lines.push(`## ${p.title}`);
    for (const [k, v] of Object.entries(p.kv || {})) lines.push(`- **${k}:** ${v}`);
    if (p.path) lines.push(`- **file:** \`${rel(p.path)}\``);
    if (p.extra) lines.push('', p.extra, '');
    lines.push('');
  }
  const file = path.join(OUTDIR, 'REPORT.md');
  ensureDir(path.dirname(file));
  await fsp.writeFile(file, lines.join('\n'), 'utf8');
  return file;
}

// ---------- Bootstrap ----------
async function bootstrap() {
  const pkgPath = path.join(ROOT, 'package.json');
  let raw = '{}'; try { raw = await fsp.readFile(pkgPath, 'utf8'); } catch {}
  const pkg = JSON.parse(raw);
  pkg.engines = pkg.engines || {}; pkg.engines.node = '>=20 <21';
  pkg.scripts = pkg.scripts || {};
  const add = (k, v) => { if (pkg.scripts[k] !== v) pkg.scripts[k] = v; };
  add('geo:doctor', 'node scripts/transparent-suite.mjs geo:doctor');
  add('geo:build',  'node scripts/transparent-suite.mjs geo:build');
  add('geo:guard',  'node scripts/transparent-suite.mjs geo:guard');
  add('geo:smoke',  'node scripts/transparent-suite.mjs geo:smoke');
  add('geo:all',    'node scripts/transparent-suite.mjs geo:all --strict');
  add('vis:ci',     'node scripts/transparent-suite.mjs vis:ci --strict');
  const next = JSON.stringify(pkg, null, 2) + '\n';
  if (next !== raw) { ensureDir(path.dirname(pkgPath)); await fsp.writeFile(pkgPath, next, 'utf8'); }

  // netlify.toml NODE_VERSION=20
  const nt = path.join(ROOT, 'netlify.toml');
  let nraw = ''; try { nraw = await fsp.readFile(nt, 'utf8'); } catch {}
  if (!/\[build\.environment\]/.test(nraw)) nraw += `\n[build.environment]\n  NODE_VERSION = "20"\n`;
  else if (!/NODE_VERSION\s*=/.test(nraw)) nraw = nraw.replace(/\[build\.environment\]/, `[build.environment]\n  NODE_VERSION = "20"`);
  else nraw = nraw.replace(/NODE_VERSION\s*=\s*"[^"]*"/, 'NODE_VERSION = "20"');
  await fsp.writeFile(nt, nraw, 'utf8');

  console.log('[bootstrap] package.json scripts and netlify.toml updated for Node 20');
}

// ---------- vis:ci ----------
async function visCI(found) {
  const parts = [];
  const guard = await runGuard(found); parts.push({ title: 'Guard SEO', kv: { pagesScanned: guard.count }, path: guard.file });

  const guardData = await readJson(guard.file) || { pages: [] };
  const total = guardData.pages.length;
  const noCanon = guardData.pages.filter(p => !p.canonical).length;
  const noLd = guardData.pages.filter(p => !p.jsonld).length;

  const snapshot = { total, missingCanonical: noCanon, missingJSONLD: noLd, ts: new Date().toISOString() };
  const snapFile = path.join(OUTDIR, 'snapshot.json');
  await writeJson(snapFile, snapshot);
  parts.push({ title: 'Visibility Snapshot', kv: snapshot, path: snapFile });

  const rep = await writeReport(parts);
  console.log(`[vis:ci] Snapshot written: ${rel(snapFile)} | Report: ${rel(rep)}`);

  if (STRICT) {
    const maxMissing = Number(ARGV.get('--max-missing') || 0);
    if (noCanon > maxMissing || noLd > maxMissing) {
      console.error(`[vis:ci] STRICT failed: missingCanonical=${noCanon}, missingJSONLD=${noLd} (allowed ${maxMissing})`);
      process.exit(2);
    }
  }
}

// ---------- Orchestration ----------
async function main() {
  ensureDir(OUTDIR);
  const found = await discover();

  const map = {
    async 'bootstrap'() { await bootstrap(); },
    async 'geo:doctor'() { const r = await runDoctor(found); console.log(`[doctor] ok=${r.summary.ok} suburbs=${r.summary.counts.suburbs||0} → ${rel(r.file)}`); },
    async 'geo:build'()  { const r = await runBuild(found);  console.log(`[build] nodes=${r.count} → ${rel(r.file)}`); },
    async 'geo:guard'()  { const r = await runGuard(found);  console.log(`[guard] pages=${r.count} → ${rel(r.file)}`); },
    async 'geo:smoke'()  { const r = await runSmoke(found);  console.log(`[smoke] ok=${r.count} → ${rel(r.file)}`); },
    async 'geo:all'()    {
      const parts = [];
      const d = await runDoctor(found); parts.push({ title: 'Doctor', kv: { ok: d.summary.ok, suburbs: d.summary.counts.suburbs||0 }, path: d.file });
      const b = await runBuild(found);  parts.push({ title: 'Build Proximity', kv: { nodes: b.count }, path: b.file });
      const g = await runGuard(found);  parts.push({ title: 'Guard SEO', kv: { pagesScanned: g.count }, path: g.file });
      const s = await runSmoke(found);  parts.push({ title: 'Smoke', kv: { ok: s.count }, path: s.file });
      const rep = await writeReport(parts);
      console.log(`[geo:all] Report: ${rel(rep)}`);
      if (STRICT && !d.summary.ok) { console.error('[geo:all] STRICT failed: doctor.ok=false'); process.exit(2); }
    },
    async 'vis:ci'()     { await visCI(found); },
    async 'report'()     { console.log(path.join(OUTDIR, 'REPORT.md')); },
  };

  if (!map[CMD]) { console.error(`Unknown command: ${CMD}`); process.exit(2); }
  await map[CMD]();
}

main().catch((e) => { console.error('[suite] Failed:', e); process.exit(1); });
