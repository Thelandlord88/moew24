#!/usr/bin/env node
/**
 * cluster_doctor.mjs — Geo/Cluster/Page Coverage Troubleshooter (v1.2)
 * Deterministic prints + JSON/MD reports and CI-friendly exits.
 */
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const args = new Map();
for (let i=2;i<process.argv.length;i++){const a=process.argv[i];if(a.startsWith("--")){const [k,v]=a.includes("=")?a.slice(2).split("="):[a.slice(2),true];args.set(k,v===undefined?true:v);}}
const ROOT = path.resolve(args.get("root") || process.cwd());
const WANT_JSON = !!args.get("json");
const WANT_MD = !!args.get("md");
const WANT_WRITE = !!args.get("write");
const STRICT = !!args.get("strict");
const ALLOW_WARN = !!args.get("allow-warn");

const PATHS = {
  ADJ: ["data/adjacency.json", "map data/adjacency.json"],
  CLUSTERS: ["data/areas.extended.clusters.json", "map data/areas.extended.clusters.json", "map data/areas.clusters.json"],
  COVERAGE: ["data/serviceCoverage.json", "map data/serviceCoverage.json"],
  META: ["src/data/suburbs.meta.json"],
  REPORT_DIR: "__reports"
};

function readFirst(cands, optional=false){
  for(const rel of cands){
    const p = path.join(ROOT, rel);
    try{ fs.accessSync(p); return JSON.parse(fs.readFileSync(p,"utf8")); }catch{}
  }
  if(optional) return null;
  throw new Error("Missing required: "+cands.join(" | "));
}
function sha256(p){ try{ const h=crypto.createHash("sha256"); h.update(fs.readFileSync(p)); return h.digest("hex"); }catch{ return null; } }

const adjacency = readFirst(PATHS.ADJ);
const clusters = readFirst(PATHS.CLUSTERS);
const coverage = readFirst(PATHS.COVERAGE);
const meta = readFirst(PATHS.META, true) || {nodes:{}};

// normalize
const adjNodes = new Set(Object.keys(adjacency||{}));
const clusterNodes = new Set(Array.isArray(clusters?.clusters) ? clusters.clusters.flatMap(c=>c.suburbs||[]) : Object.values(clusters||{}).flat());
const coverageNodes = new Set(Object.values(coverage||{}).flat());

const coverageNotInAdj = [...coverageNodes].filter(s=>!adjNodes.has(s)).sort();
const adjNotInClusters = [...adjNodes].filter(s=>!clusterNodes.has(s)).sort();
const adjNotInCoverage = [...adjNodes].filter(s=>!coverageNodes.has(s)).sort();
const clusteredNoPage = [...clusterNodes].filter(s=>!coverageNodes.has(s)).sort();
const hasPageNotClustered = [...coverageNodes].filter(s=>!clusterNodes.has(s)).sort();

const report = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  inputs: {
    adjacency_paths: PATHS.ADJ,
    clusters_paths: PATHS.CLUSTERS,
    coverage_paths: PATHS.COVERAGE
  },
  summary: {
    adjacencyNodes: adjNodes.size,
    clusters: clusterNodes.size,
    pages: coverageNodes.size,
    unionAll: new Set([...adjNodes, ...clusterNodes, ...coverageNodes]).size,
    coverageNotInAdjacency: coverageNotInAdj.length,
    adjacencyButNotClustered: adjNotInClusters.length,
    clusteredButNoPage: clusteredNoPage.length,
    hasPageNotClustered: hasPageNotClustered.length
  },
  sets: {
    coverageNotInAdjacency: coverageNotInAdj,
    adjacencyButNotClustered: adjNotInClusters,
    adjacencyButNotInCoverage: adjNotInCoverage,
    clusteredButNoPage: clusteredNoPage,
    hasPageButNotClustered: hasPageNotClustered
  }
};

if (WANT_JSON || WANT_WRITE){
  fs.mkdirSync(PATHS.REPORT_DIR, {recursive:true});
  fs.writeFileSync(path.join(PATHS.REPORT_DIR,"geo-page-coverage.report.json"), JSON.stringify(report,null,2));
}
if (WANT_MD || WANT_WRITE){
  const s = report.summary;
  const md = [
    "# Cluster Doctor Summary",
    `Generated: ${report.generatedAt}`,
    "",
    `Adjacency: ${s.adjacencyNodes}, Clusters: ${s.clusters}, Pages: ${s.pages}`,
    `coverageNotInAdjacency: ${s.coverageNotInAdjacency}`,
    `adjacencyButNotClustered: ${s.adjacencyButNotClustered}`,
    `clusteredButNoPage: ${s.clusteredButNoPage}`,
    `hasPageNotClustered: ${s.hasPageNotClustered}`
  ].join("\\n");
  fs.mkdirSync(PATHS.REPORT_DIR, {recursive:true});
  fs.writeFileSync(path.join(PATHS.REPORT_DIR,"geo-page-coverage.summary.md"), md);
}

// CI gate default policy
let fail = false;
if (STRICT){
  fail = report.sets.coverageNotInAdjacency.length>0 ||
         report.sets.adjacencyButNotClustered.length>0 ||
         report.sets.clusteredButNoPage.length>0 ||
         report.sets.hasPageButNotClustered.length>0;
} else {
  if (report.sets.coverageNotInAdjacency.length>0) fail = true;
  if (report.sets.adjacencyButNotClustered.length>0) fail = true;
}
if (fail && !ALLOW_WARN) process.exit(1);
console.log("[cluster_doctor] OK");
