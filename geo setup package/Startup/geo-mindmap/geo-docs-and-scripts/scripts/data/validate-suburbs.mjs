#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";

const candidates = [
  "src/data/suburbs_enriched.geojson",
  "src/data/suburbs.geojson"
];

let file = null;
for (const c of candidates) {
  try {
    await fs.access(c);
    file = c; break;
  } catch {}
}

if (!file) {
  console.error("❌ No dataset found. Expected one of:\n" + candidates.map(s => "  - " + s).join("\n"));
  process.exit(1);
}

const raw = await fs.readFile(file, "utf8");
let json;
try {
  json = JSON.parse(raw);
} catch (e) {
  console.error(`❌ Invalid JSON in ${file}:`, e.message);
  process.exit(1);
}

if (json.type !== "FeatureCollection" || !Array.isArray(json.features)) {
  console.error(`❌ ${file} is not a GeoJSON FeatureCollection.`);
  process.exit(1);
}

let missing = 0;
for (const [i, f] of json.features.entries()) {
  const p = f?.properties || {};
  const name = p.name_official || p.name || p.suburb_name || p.suburb;
  const lga = p.lga_name || p.lga || p.LGA || p.council;
  if (!name || !lga) {
    missing++;
    console.warn(`⚠️  feature[${i}] missing name or lga`);
  }
}

if (missing) {
  console.error(`❌ ${missing} feature(s) incomplete.`);
  process.exit(1);
}

console.log(`✅ ${path.basename(file)} looks valid (${json.features.length} features).`);
