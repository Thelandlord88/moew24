#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.GEO_BASE_DIR ? path.resolve(process.env.GEO_BASE_DIR) : process.cwd();
const read = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const outDir = process.env.GEO_REPORT_DIR || path.join(root,'__ai','reports');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

const cfg = read(path.join(root,'geo.config.json'));
const geo = read(path.join(root,'src/data/suburbs_enriched.geojson'));
const adj = read(path.join(root,'src/data/adjacency.json'));
const clusters = read(path.join(root,'src/data/clusters.json'));

const norm = (s) => s.normalize('NFKC').toLowerCase().replace(/\s+/g,' ').trim();
const features = geo.features ?? [];
const namesRaw = new Map(); // norm -> raw
for (const f of features) {
  const p = f.properties || {};
  const raw = p.name_official || p.name || p.suburb || p.title || '';
  if (raw) namesRaw.set(norm(raw), raw);
}

const allGeo = new Set(Array.from(namesRaw.keys()));
const clusterMap = new Map(); // norm suburb -> cluster name
for (const [cl, list] of Object.entries(clusters)) for (const n of list||[]) clusterMap.set(norm(n), cl);

let reciprocityErrors = 0, orphans = 0, centroidMissing = 0, geomWarn = 0;
let missingCluster = [];
let duplicates = [];

const hasCentroid = (f) => {
  const p=f.properties||{};
  const ok = ('geometry' in f && f.geometry && f.geometry.type === 'Point' && Array.isArray(f.geometry.coordinates));
  if (!ok) geomWarn++;
  const found = ('lat' in p && 'lng' in p) || ('latitude' in p && 'longitude' in p) || ('lat_deg' in p && 'lon_deg' in p);
  if (!found) centroidMissing++;
  return found;
};

for (const f of features) hasCentroid(f);

for (const [rawA, neigh] of Object.entries(adj)) {
  const A = norm(rawA);
  if (!neigh || neigh.length === 0) orphans++;
  for (const rawB of neigh) {
    const B = norm(rawB);
    const bList = adj[rawB] || adj[namesRaw.get(B)] || [];
    const back = bList.map(norm);
    if (!back.includes(A)) reciprocityErrors++;
  }
}

const seenC = new Map();
for (const [cl, list] of Object.entries(clusters)) {
  for (const n of list||[]) {
    const key = norm(n);
    if (!seenC.has(key)) seenC.set(key, []);
    seenC.get(key).push(cl);
  }
}
for (const [k, arr] of seenC.entries()) {
  if (arr.length > 1) duplicates.push([namesRaw.get(k)||k, arr]);
  if (!allGeo.has(k)) missingCluster.push(namesRaw.get(k)||k);
}

let FAIL_DUP = process.env.FAIL_DUPLICATES === '1' || process.argv.includes('--fail-duplicates');
let FAIL_MISS = process.env.FAIL_MISSING_CLUSTERS === '1' || process.argv.includes('--fail-missing-clusters');
let FAIL_ORPH = Number.isFinite(+process.env.FAIL_ORPHANS) ? +process.env.FAIL_ORPHANS
             : (process.argv.find(x=>x.startsWith('--fail-orphans=')) ? +process.argv.find(x=>x.startsWith('--fail-orphans=')).split('=')[1] : NaN);

const report = {
  summary: { features: features.length, clusters: Object.keys(clusters).length, reciprocityErrors, orphans, centroidMissing,
             duplicates: duplicates.length, missingCluster: missingCluster.length, geomWarn },
  duplicates: duplicates.map(([n,arr]) => ({ suburb:n, clusters:arr })),
  missingCluster
};
const rptJson = path.join(outDir,'doctor.json'); fs.writeFileSync(rptJson, JSON.stringify(report, null, 2));
const rptMd = path.join(outDir,'doctor.md'); fs.writeFileSync(rptMd, [
  '# Doctor Report','',
  `features: ${report.summary.features}`, `clusters: ${report.summary.clusters}`,
  `reciprocityErrors: ${report.summary.reciprocityErrors}`, `orphans: ${report.summary.orphans}`,
  `centroidMissing: ${report.summary.centroidMissing}`, `duplicates: ${report.summary.duplicates}`,
  `missingCluster: ${report.summary.missingCluster}`, `geomWarn: ${report.summary.geomWarn}`, ''
].join('\n'));

console.log(`GEODOC: features=${features.length} clusters=${Object.keys(clusters).length} reciprocity=${reciprocityErrors} orphans=${orphans} centroidMissing=${centroidMissing} duplicates=${duplicates.length} missingCluster=${missingCluster.length} geomWarn=${geomWarn}`);

if (reciprocityErrors > 0) process.exit(1);
if (!Number.isNaN(FAIL_ORPH) && orphans > FAIL_ORPH) process.exit(2);
if (FAIL_DUP && duplicates.length > 0) process.exit(3);
if (FAIL_MISS && missingCluster.length > 0) process.exit(4);
process.exit(0);
