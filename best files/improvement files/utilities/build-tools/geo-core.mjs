#!/usr/bin/env node
// Strict, no-fallback core. Node >= 20, ESM, zero deps.
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

export const VERSION = '2.1.0-core-nofallback';

const must = (cond, msg) => { if (!cond) throw new Error(msg); };
export const nowISO = () => new Date().toISOString();

export const sha1 = (s) => crypto.createHash('sha1').update(s).digest('hex');
export function stable(obj) {
  if (Array.isArray(obj)) return obj.map(stable);
  if (obj && typeof obj === 'object') {
    return Object.fromEntries(Object.keys(obj).sort().map(k => [k, stable(obj[k])]))
  }
  return obj;
}
export async function writeJson(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const txt = JSON.stringify(stable(data), null, 2) + '\n';
  await fsp.writeFile(file, txt, 'utf8');
  return sha1(txt);
}
export async function readJsonStrict(p, label) {
  must(fs.existsSync(p), `[load] Required ${label} not found at ${p}`);
  try { return JSON.parse(await fsp.readFile(p, 'utf8')); }
  catch (e) { throw new Error(`[load] ${label} is not valid JSON at ${p}: ${e.message}`); }
}

// ---------- Discovery (strict) ----------
function firstExisting(root, arr) {
  for (const rel of arr) { const abs = path.join(root, rel); if (fs.existsSync(abs)) return abs; }
  return null;
}
export function discoverStrict(root) {
  const adjacency = firstExisting(root, ['src/data/adjacency.json']);
  const clusters  = firstExisting(root, ['src/data/clusters.json']);
  const suburbs   = firstExisting(root, ['src/data/suburbs_enriched.geojson']);
  const dist      = firstExisting(root, ['dist','out','.output/public']); // required only for guard/smoke
  must(adjacency, '[discover] src/data/adjacency.json is required');
  must(clusters,  '[discover] src/data/clusters.json is required');
  must(suburbs,   '[discover] src/data/suburbs_enriched.geojson is required');
  return { adjacency, clusters, suburbs, dist };
}

// ---------- Geo helpers ----------
export function asFeatures(geojson) {
  must(geojson && typeof geojson === 'object', '[geo] suburbs_enriched.geojson missing/invalid');
  must(geojson.type === 'FeatureCollection' && Array.isArray(geojson.features),
      '[geo] Must be a FeatureCollection with features[]');
  return geojson.features;
}
export function propsOf(f) { return f.properties || {}; }
export function coordOf(f) {
  const p = propsOf(f);
  if (typeof p.centroid_lat === 'number' && typeof p.centroid_lon === 'number') {
    return { lat: +p.centroid_lat, lon: +p.centroid_lon };
  }
  const lp = p.label_point;
  must(lp && typeof lp.lat === 'number' && typeof lp.lon === 'number',
      '[geo] Missing centroid_lat/centroid_lon or label_point.lat/lon');
  return { lat: +lp.lat, lon: +lp.lon };
}
const d2r = (d) => d * Math.PI / 180;
export function haversine(a, b) {
  const R = 6371;
  const dLat = d2r(b.lat - a.lat), dLon = d2r(b.lon - a.lon);
  const s1 = Math.sin(dLat/2)**2 + Math.cos(d2r(a.lat))*Math.cos(d2r(b.lat))*Math.sin(dLon/2)**2;
  return 2 * R * Math.atan2(Math.sqrt(s1), Math.sqrt(1 - s1));
}

// ---------- Doctor (strict) ----------
export async function runDoctorStrict(root, found) {
  const adj      = await readJsonStrict(found.adjacency, 'adjacency.json');
  const clusters = await readJsonStrict(found.clusters,  'clusters.json');
  const feats    = asFeatures(await readJsonStrict(found.suburbs, 'suburbs_enriched.geojson'));

  // slug index + coord validation
  const bySlug = new Map();
  for (const f of feats) {
    const p = propsOf(f); const raw = String(p.slug || '').trim();
    must(raw, '[doctor] Feature without properties.slug');
    const slug = raw.toLowerCase();
    if (bySlug.has(slug)) throw new Error(`[doctor] duplicate slug: ${slug}`);
    coordOf(f); // throws if missing
    bySlug.set(slug, { slug });
  }

  // adjacency: nodes exist + reciprocity
  const adjMap = new Map(Object.entries(adj));
  let reciprocityBreaks = 0;
  for (const [a, obj] of adjMap.entries()) {
    must(bySlug.has(a), `[doctor] adjacency node not found in geojson: ${a}`);
    must(obj && Array.isArray(obj.adjacent_suburbs), `[doctor] node missing adjacent_suburbs: ${a}`);
    for (const b of obj.adjacent_suburbs) {
      must(bySlug.has(b), `[doctor] adjacency edge to unknown suburb: ${a} -> ${b}`);
      const bj = adjMap.get(String(b));
      must(bj && Array.isArray(bj.adjacent_suburbs), `[doctor] adjacency target lacks adjacent_suburbs: ${b}`);
      if (!bj.adjacent_suburbs.includes(a)) reciprocityBreaks++;
    }
  }
  must(reciprocityBreaks === 0, `[doctor] ${reciprocityBreaks} non-reciprocal adjacency edge(s)`);

  // clusters: every member exists in geojson + adjacency
  let clusterCount = 0, memberCount = 0;
  for (const [key, meta] of Object.entries(clusters)) {
    clusterCount++;
    must(meta && Array.isArray(meta.suburbs) && meta.suburbs.length > 0,
        `[doctor] cluster ${key} missing suburbs[]`);
    for (const s of meta.suburbs) {
      const slug = String(s).toLowerCase();
      must(bySlug.has(slug), `[doctor] cluster ${key} contains unknown suburb: ${slug}`);
      must(adjMap.has(slug), `[doctor] cluster ${key} member missing in adjacency: ${slug}`);
      memberCount++;
    }
  }

  return { ok: true, counts: { suburbs: bySlug.size, adjacencyNodes: adjMap.size, clusters: clusterCount, clusterMembers: memberCount }, ts: nowISO() };
}

// ---------- Dist guard (strict) ----------
export async function runGuardStrict(root, found) {
  must(found.dist && fs.existsSync(found.dist), `[guard] dist/ not found; build your site before guard`);
  const dist = found.dist;
  const out = { dist: path.relative(root, dist).replaceAll('\\','/'), pages: [] };

  const stack = [dist], htmls = [];
  while (stack.length) {
    const d = stack.pop();
    for (const ent of await fsp.readdir(d, { withFileTypes: true })) {
      const p = path.join(d, ent.name);
      if (ent.isDirectory()) stack.push(p);
      else if (ent.isFile() && ent.name.endsWith('.html')) htmls.push(p);
    }
  }
  must(htmls.length > 0, '[guard] No HTML files found in dist/');
  for (const p of htmls) {
    const html = await fsp.readFile(p, 'utf8');
    const hasCanonical = /<link[^>]+rel=["']canonical["'][^>]*>/i.test(html);
    const hasLd       = /<script[^>]+type=["']application\/ld\+json["'][^>]*>/i.test(html);
    out.pages.push({ file: path.relative(root, p).replaceAll('\\','/'), canonical: hasCanonical, jsonld: hasLd });
  }
  return out;
}

// ---------- Seeds (strict) ----------
export async function readSeedsStrict(file) {
  must(fs.existsSync(file), `[smoke] Seeds file not found: ${file}`);
  let arr;
  try { arr = JSON.parse(await fsp.readFile(file, 'utf8')); }
  catch (e) { throw new Error(`[smoke] Seeds must be valid JSON array: ${e.message}`); }
  must(Array.isArray(arr) && arr.length > 0, '[smoke] Seeds JSON must be a non-empty array');
  return arr.map(String);
}

// ---------- Smoke (strict, seeded only) ----------
export async function runSmokeStrict(root, found, { seedsPath }) {
  must(seedsPath, '[smoke] seedsPath is required');
  const urls = await readSeedsStrict(seedsPath);
  must(found.dist && fs.existsSync(found.dist), `[smoke] dist/ not found; build your site before smoke`);
  const dist = found.dist;

  const results = [];
  for (const url of urls) {
    const file = path.join(dist, url.replace(/^\//, ''), 'index.html');
    results.push({ url, exists: fs.existsSync(file), file: path.relative(root, file).replaceAll('\\','/') });
  }
  const total = results.length, ok = results.filter(r => r.exists).length;
  must(total > 0, '[smoke] No seed URLs provided');
  return { total, ok, results };
}

// ---------- Report ----------
export async function writeReport(root, parts) {
  const lines = [];
  lines.push('# Geo Suite Report (strict, no-fallback)');
  lines.push(`Generated: ${new Date().toLocaleString()}`);
  lines.push('');
  for (const p of parts) {
    if (!p) continue;
    lines.push(`## ${p.title}`);
    for (const [k, v] of Object.entries(p.kv || {})) lines.push(`- **${k}:** ${v}`);
    if (p.path) lines.push(`- **file:** \`${p.path}\``);
    lines.push('');
  }
  const file = path.join(root, '__geo', 'REPORT.md');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  await fsp.writeFile(file, lines.join('\n'), 'utf8');
  return file;
}
