#!/usr/bin/env node
import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";

const [,, inPath, outPath] = process.argv;
if (!inPath || !outPath) {
  console.error("Usage: node scripts/data/csv-to-geojson.mjs <input.csv> <output.geojson>");
  process.exit(1);
}

const text = await fsp.readFile(inPath, "utf8");

function parseCSV(str) {
  const rows = [];
  let i = 0, field = "", row = [], inQuotes = false;
  while (i < str.length) {
    const c = str[i];
    if (inQuotes) {
      if (c === '"') {
        if (str[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
      field += c; i++; continue;
    }
    if (c === '"') { inQuotes = true; i++; continue; }
    if (c === ",") { row.push(field); field = ""; i++; continue; }
    if (c === "\r") { i++; continue; }
    if (c === "\n") { row.push(field); rows.push(row); field = ""; row = []; i++; continue; }
    field += c; i++;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows;
}

const rows = parseCSV(text);
if (rows.length === 0) {
  console.error("No rows found in CSV.");
  process.exit(1);
}

const header = rows[0].map((h) => h.trim());
const data = rows.slice(1);

function idx(nameCandidates) {
  for (const c of nameCandidates) {
    const k = header.findIndex((h) => h.toLowerCase() === c.toLowerCase());
    if (k >= 0) return k;
  }
  return -1;
}

const iName  = idx(["name_official","name","suburb_name","suburb"]);
const iLga   = idx(["lga_name","lga","LGA","council"]);
const iSlug  = idx(["suburb_slug","slug"]);
const iLgaSl = idx(["lga_slug"]);
const iLat   = idx(["centroid_lat","lat"]);
const iLon   = idx(["centroid_lon","lon"]);

if (iName < 0 || iLga < 0) {
  console.error("CSV must include a suburb name and LGA columns.");
  process.exit(1);
}

function slugify(input) {
  return input
    .normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").replace(/--+/g, "-");
}

const features = data.map((cells) => {
  const name = cells[iName]?.trim();
  const lgaName = cells[iLga]?.trim();
  if (!name || !lgaName) return null;

  const suburb_slug = iSlug >= 0 ? (cells[iSlug]?.trim() || "") : "";
  const lga_slug = iLgaSl >= 0 ? (cells[iLgaSl]?.trim() || "") : "";
  const lat = iLat >= 0 ? Number(cells[iLat]) : NaN;
  const lon = iLon >= 0 ? Number(cells[iLon]) : NaN;

  const props = {
    name_official: name,
    lga_name: lgaName,
    suburb_slug: suburb_slug || slugify(name),
    lga_slug: lga_slug || slugify(lgaName),
    centroid_lat: Number.isFinite(lat) ? lat : undefined,
    centroid_lon: Number.isFinite(lon) ? lon : undefined
  };

  const geometry =
    Number.isFinite(lat) && Number.isFinite(lon)
      ? { type: "Point", coordinates: [lon, lat] }
      : null;

  return { type: "Feature", geometry, properties: props };
}).filter(Boolean);

const fc = { type: "FeatureCollection", features };

await fsp.mkdir(path.dirname(outPath), { recursive: true });
await fsp.writeFile(outPath, JSON.stringify(fc, null, 2));
console.log(`✅ Wrote ${features.length} features to ${outPath}`);
