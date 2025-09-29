#!/usr/bin/env node
/**
 * Doctor++: structural checks across datasets.
 * - GeoJSON shape / centroid keys
 * - Adjacency reciprocity (A->B implies B->A)
 * - Cluster coverage
 * - Name reconciliation (case/trim), duplicates, orphan threshold
 * Exit codes:
 *   0  ok (or warnings only)
 *   1  reciprocity errors present
 *   2  orphans exceed threshold
 *   3  duplicates across clusters (if toggled)
 *   4  missing cluster coverage (if toggled)
 */
import fs from "node:fs";
import { P, readJSON, norm, centroidPresent } from "./_shared.js";

const argv = process.argv.slice(2);
let FAIL_ORPHANS = Number.isFinite(+process.env.FAIL_ORPHANS) ? +process.env.FAIL_ORPHANS : NaN;
let FAIL_DUPLICATES = process.env.FAIL_DUPLICATES === "1";
let FAIL_MISSING_CLUSTERS = process.env.FAIL_MISSING_CLUSTERS === "1";
for (const a of argv) {
  if (a.startsWith("--fail-orphans=")) FAIL_ORPHANS = +a.split("=")[1];
  if (a === "--fail-duplicates") FAIL_DUPLICATES = true;
  if (a === "--fail-missing-clusters") FAIL_MISSING_CLUSTERS = true;
}

const geo = readJSON(P.suburbs);
const adj = readJSON(P.adjacency);
const clusters = readJSON(P.clusters);

if (geo.type !== "FeatureCollection" || !Array.isArray(geo.features) || geo.features.length === 0) {
  throw new Error("suburbs_enriched.geojson must be a non-empty FeatureCollection");
}

// Names from geo for reconciliation
const geoNamesRaw = geo.features.map(f => (f.properties?.name_official || f.properties?.name || f.properties?.suburb || "").toString().trim()).filter(Boolean);
const geoNormToRaw = new Map(); for (const name of geoNamesRaw) geoNormToRaw.set(norm(name), name);

// Centroid presence
let centroidMissing = 0;
for (const f of geo.features) if (!centroidPresent(f.properties)) centroidMissing++;
if (centroidMissing > 0) console.warn(`[doctor] WARN: ${centroidMissing} features missing centroid lat/lon`);

// Adjacency reciprocity & orphans
let reciprocityErrors = 0;
let orphans = 0;
const adjNorm = {};
for (const [k,v] of Object.entries(adj)) adjNorm[norm(k)] = Array.isArray(v) ? v.map(norm) : [];
for (const [suburbNorm, neighborsNorm] of Object.entries(adjNorm)) {
  if (neighborsNorm.length === 0) orphans++;
  for (const n of neighborsNorm) {
    const back = adjNorm[n] || [];
    if (!back.includes(suburbNorm)) {
      reciprocityErrors++;
      console.error(`[doctor] Missing reciprocity: ${geoNormToRaw.get(suburbNorm) || suburbNorm} -> ${geoNormToRaw.get(n) || n} but not ${geoNormToRaw.get(n) || n} -> ${geoNormToRaw.get(suburbNorm) || suburbNorm}`);
    }
  }
}

// Cluster coverage & duplicates
const clustersNorm = {};
for (const [cluster, arr] of Object.entries(clusters)) {
  clustersNorm[norm(cluster)] = (Array.isArray(arr) ? arr : []).map(norm);
}
const clustered = new Set(Object.values(clustersNorm).flat());
const missingCluster = [...geoNormToRaw.keys()].filter(n => !clustered.has(n));
if (missingCluster.length > 0) {
  console.warn(`[doctor] WARN: ${missingCluster.length} suburbs not listed in clusters.json (top 5): ${missingCluster.slice(0,5).map(n=>geoNormToRaw.get(n)||n).join(", ")}`);
}

// Detect duplicate assignments
const seenInCluster = new Map();
for (const [cluster, arr] of Object.entries(clustersNorm)) {
  for (const n of arr) {
    const list = seenInCluster.get(n) || [];
    list.push(cluster);
    seenInCluster.set(n, list);
  }
}
const duplicates = [...seenInCluster.entries()].filter(([,list]) => list.length > 1);
if (duplicates.length > 0) {
  console.warn(`[doctor] WARN: ${duplicates.length} suburbs appear in multiple clusters (top 5): ` +
    duplicates.slice(0,5).map(([n, list]) => `${geoNormToRaw.get(n)||n} -> [${list.join(", ")}]`).join("; "));
}

// Optional CI artifacts
try {
  const outJson = process.env.GEO_REPORT_JSON;
  const outMd   = process.env.GEO_REPORT_MD;
  if (outJson || outMd) {
    const report = {
      summary: {
        features: geo.features.length,
        clusters: Object.keys(clusters).length,
        reciprocityErrors,
        orphans,
        centroidMissing
      },
      duplicates: duplicates.slice(0, 200).map(([n, list]) => ({ suburb: geoNormToRaw.get(n)||n, clusters: list })),
      missingCluster
    };
    if (outJson) fs.writeFileSync(outJson, JSON.stringify(report, null, 2));
    if (outMd) {
      const md = [
        "# Doctor Report",
        `features: ${report.summary.features}`,
        `clusters: ${report.summary.clusters}`,
        `reciprocityErrors: ${report.summary.reciprocityErrors}`,
        `orphans: ${report.summary.orphans}`,
        `centroidMissing: ${report.summary.centroidMissing}`,
        report.duplicates.length ? `\n**Duplicates (first 200):**\n- ` + report.duplicates.map(d=>`${d.suburb} -> [${d.clusters.join(', ')}]`).join("\n- ") : ""
      ].join("\n");
      fs.writeFileSync(outMd, md + "\n");
    }
  }
} catch {}

console.log(`[doctor] OK: features=${geo.features.length}, clusters=${Object.keys(clusters).length}, reciprocityErrors=${reciprocityErrors}, orphans=${orphans}, centroidMissing=${centroidMissing}`);

if (reciprocityErrors > 0) process.exit(1);
if (!Number.isNaN(FAIL_ORPHANS) && orphans > FAIL_ORPHANS) process.exit(2);
if (FAIL_DUPLICATES && duplicates.length > 0) process.exit(3);
if (FAIL_MISSING_CLUSTERS && missingCluster.length > 0) process.exit(4);
