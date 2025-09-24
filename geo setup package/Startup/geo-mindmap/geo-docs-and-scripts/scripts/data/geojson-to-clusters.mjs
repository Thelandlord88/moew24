#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";

const inPath = process.argv[2] || "src/data/suburbs_enriched.geojson";
const outClusters = "src/data/areas.clusters.json";
const regionMapPath = "src/data/region-map.json";

const slugify = (s) => s.normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
  .toLowerCase().replace(/&/g, " and ").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").replace(/--+/g, "-");

const tryReadJson = async (p) => {
  try { return JSON.parse(await fs.readFile(p, "utf8")); } catch { return null; }
};

const geo = await tryReadJson(inPath);
if (!geo || geo.type !== "FeatureCollection" || !Array.isArray(geo.features)) {
  console.error(`❌ ${inPath} is not a GeoJSON FeatureCollection`); process.exit(1);
}

const regionMap = await tryReadJson(regionMapPath) || {};
const clusters = {};

for (const f of geo.features) {
  const p = f?.properties || {};
  const name = p.name_official || p.suburb_name || p.name || p.suburb;
  const lgaName = p.lga_name || p.lga || p.LGA || p.council;
  if (!name || !lgaName) continue;

  const id = (p.suburb_slug || p.slug || slugify(name));
  const region = (p.region || regionMap[lgaName] || "brisbane").toLowerCase();
  const postcode = p.postcode || p.post_code || "";
  const lat = p.centroid_lat ?? p.lat;
  const lon = p.centroid_lon ?? p.lon;

  const coords =
    Number.isFinite(lat) && Number.isFinite(lon) ? { lat: Number(lat), lng: Number(lon) } :
    (f?.geometry?.type === "Point" &&
     Array.isArray(f.geometry.coordinates) &&
     Number.isFinite(f.geometry.coordinates[0]) &&
     Number.isFinite(f.geometry.coordinates[1])) ?
       { lat: f.geometry.coordinates[1], lng: f.geometry.coordinates[0] } : undefined;

  clusters[id] = {
    id,
    name,
    region,
    postcode: String(postcode || ""),
    coordinates: coords,
    population: p.population ? Number(p.population) : undefined,
    description: p.description || p.summary || undefined
  };
}

await fs.mkdir(path.dirname(outClusters), { recursive: true });
await fs.writeFile(outClusters, JSON.stringify(clusters, null, 2));
console.log(`✅ Wrote ${Object.keys(clusters).length} suburbs → ${outClusters}`);
