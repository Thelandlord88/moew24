// src/lib/geo/adjacency.js
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const CLUSTERS_PATH = path.join(ROOT, "src/data/areas.clusters.json");
const ADJ_PATH = path.join(ROOT, "src/data/areas.adj.json");

function readJson(file) {
  const raw = fs.readFileSync(file, "utf8");
  return JSON.parse(raw);
}

let _cache = null;
/** Loads and caches clusters + adjacency */
function load() {
  if (_cache) return _cache;
  const clusters = readJson(CLUSTERS_PATH); // { id: { id, name, ... }, ... }
  const adj = readJson(ADJ_PATH);          // { id: ["nbr","nbr2"], ... }
  _cache = { clusters, adj };
  return _cache;
}

/** Returns [{ slug, name }] neighbors for the given suburb slug. */
export function getAdjacentSuburbsBySlug(suburbSlug, limit = 6) {
  const { clusters, adj } = load();
  const nbrs = adj[suburbSlug] || [];
  const out = [];
  for (const slug of nbrs) {
    const row = clusters[slug];
    if (!row) continue;
    out.push({ slug, name: row.name });
    if (out.length >= limit) break;
  }
  return out;
}

/** Get one suburb by slug from clusters. */
export function getSuburbBySlug(slug) {
  const { clusters } = load();
  const row = clusters[slug];
  return row ? { slug, name: row.name, ...row } : null;
}
