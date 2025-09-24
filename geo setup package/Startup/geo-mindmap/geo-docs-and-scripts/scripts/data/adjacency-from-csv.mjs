#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";

const [, , inCsv = "src/data/adjacency.csv", outJson = "src/data/areas.adj.json", ...flags] = process.argv;
const FORCE_SYMM = flags.includes("--symmetric");

const clustersPath = "src/data/areas.clusters.json";
const err = (...a) => (console.error(...a), process.exit(1));
const warn = (...a) => console.warn(...a);

const readJSON = async (p) => JSON.parse(await fs.readFile(p, "utf8"));
const fileExists = async (p) => fs.access(p).then(() => true).catch(() => false);

function parseCSV(str) {
  const rows = [];
  let i = 0, field = "", row = [], q = false;
  while (i < str.length) {
    const c = str[i];
    if (q) {
      if (c === '"') {
        if (str[i + 1] === '"') { field += '"'; i += 2; continue; }
        q = false; i++; continue;
      }
      field += c; i++; continue;
    }
    if (c === '"') { q = true; i++; continue; }
    if (c === ",") { row.push(field); field = ""; i++; continue; }
    if (c === "\r") { i++; continue; }
    if (c === "\n") { row.push(field); rows.push(row); field = ""; row = []; i++; continue; }
    field += c; i++;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows;
}

const slugify = (s) => s
  ?.normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
  .toLowerCase().replace(/&/g, " and ")
  .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").replace(/--+/g, "-") || "";

const headerIndex = (hdrs, names) => {
  const H = hdrs.map(h => h.trim().toLowerCase());
  for (const n of names) {
    const j = H.indexOf(n.toLowerCase());
    if (j >= 0) return j;
  }
  return -1;
};

(async () => {
  if (!await fileExists(inCsv)) err(`❌ CSV not found: ${inCsv}`);
  if (!await fileExists(clustersPath)) err(`❌ Clusters not found: ${clustersPath}. Run geo:from:geojson first.`);

  const csvText = await fs.readFile(inCsv, "utf8");
  const rows = parseCSV(csvText);
  if (!rows.length) err("❌ CSV empty");

  const header = rows[0].map(s => s.trim());
  const data = rows.slice(1).filter(r => r.length && r.some(c => c && c.trim().length));

  const iSrc = headerIndex(header, ["source","suburb_id","suburb_slug","suburb_name"]);
  const iDst = headerIndex(header, ["target","neighbor_id","neighbor_slug","neighbor_name"]);
  if (iSrc < 0 || iDst < 0) err("❌ CSV must have source/target (or suburb_*/neighbor_*) columns.");

  const clusters = await readJSON(clustersPath);

  const nameToId = new Map();
  for (const [id, v] of Object.entries(clusters)) {
    if (v?.name) nameToId.set(v.name.toLowerCase(), id);
  }

  const toId = (cell) => {
    const raw = (cell || "").trim();
    if (!raw) return "";
    if (clusters[raw]) return raw;
    const slug = slugify(raw);
    if (clusters[slug]) return slug;
    const byName = nameToId.get(raw.toLowerCase());
    if (byName) return byName;
    return "";
  };

  const graph = new Map();
  const getSet = (k) => (graph.get(k) || (graph.set(k, new Set()), graph.get(k)));

  let unknown = 0, selfLoops = 0, edges = 0;

  for (const r of data) {
    const a = toId(r[iSrc]);
    const b = toId(r[iDst]);
    if (!a || !b) { unknown++; continue; }
    if (a === b) { selfLoops++; continue; }

    getSet(a).add(b);
    if (FORCE_SYMM) getSet(b).add(a);
    edges++;
  }

  if (unknown) warn(`⚠️ Skipped ${unknown} row(s) with unknown ids/names.`);
  if (selfLoops) warn(`⚠️ Removed ${selfLoops} self-loop(s).`);

  let asym = 0;
  for (const [a, setA] of graph) {
    for (const b of setA) {
      const setB = graph.get(b) || new Set();
      if (!setB.has(a)) {
        asym++;
        if (FORCE_SYMM) setB.add(a);
        graph.set(b, setB);
      }
    }
  }
  if (asym && !FORCE_SYMM) warn(`⚠️ Found ${asym} asymmetric edge(s). Use --symmetric to auto-fix.`);

  const out = {};
  for (const [id, set] of graph) {
    out[id] = Array.from(set).sort();
  }

  await fs.mkdir(path.dirname(outJson), { recursive: true });
  await fs.writeFile(outJson, JSON.stringify(out, null, 2));
  console.log(`✅ Wrote ${Object.keys(out).length} nodes, ~${edges} edges → ${outJson}`);

  if (!Object.keys(out).length) err("❌ No adjacency produced. Check your CSV and clusters.");
})();
