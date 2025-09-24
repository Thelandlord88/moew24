Absolutely—here’s the **wired-up data pipeline** so your dynamic SSG routes are built from your suburb datasets. I’ve made it resilient (prefers enriched **GeoJSON**, falls back to plain **GeoJSON**; graceful if files are missing), plus optional CSV → GeoJSON tooling so you can convert your CSVs into a build-ready dataset.

---

# 1) `package.json` (add data scripts)

Add these scripts to the `scripts` block you already have:

```json
{
  "scripts": {
    "data:validate": "node scripts/data/validate-suburbs.mjs",
    "data:csv2geo": "node scripts/data/csv-to-geojson.mjs src/data/suburbs_enriched.csv src/data/suburbs_enriched.geojson"
  }
}
```

> Run:
>
> * `npm run data:validate` to sanity-check your dataset.
> * `npm run data:csv2geo` to convert CSV → GeoJSON (needs centroid lat/lon columns).

---

# 2) `tsconfig.json` (allow JSON imports just in case)

Add `resolveJsonModule` (keep the rest of your settings):

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "types": ["vite/client", "astro/client"],
    "baseUrl": ".",
    "paths": { "~/*": ["src/*"] },
    "resolveJsonModule": true,
    "skipLibCheck": true
  },
  "include": ["src", "tests", "scripts", "playwright.config.ts"]
}
```

---

# 3) Place your datasets

Create `src/data/` and drop one of these (prefer the first):

* `src/data/suburbs_enriched.geojson`  ← **preferred**
* `src/data/suburbs.geojson`

> (You can convert from your `suburbs_enriched.csv` using the script below.)

---

# 4) Data loader used at build time

`src/lib/data/suburbs.ts`

```ts
import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";
import { z } from "zod";

export interface SuburbRow {
  lgaSlug: string;
  suburbSlug: string;
  name: string;
  lgaName: string;
  lat?: number | null;
  lon?: number | null;
}

const FeaturePropsSchema = z.object({
  // flexible property names from your enriched files
  name_official: z.string().optional(),
  name: z.string().optional(),
  suburb_name: z.string().optional(),
  suburb: z.string().optional(),
  slug: z.string().optional(),
  suburb_slug: z.string().optional(),

  lga: z.string().optional(),
  LGA: z.string().optional(),
  council: z.string().optional(),
  lga_name: z.string().optional(),

  lga_slug: z.string().optional(),

  centroid_lat: z.coerce.number().optional(),
  centroid_lon: z.coerce.number().optional(),
  lat: z.coerce.number().optional(),
  lon: z.coerce.number().optional(),
});

const GeoJSONFeatureSchema = z.object({
  type: z.literal("Feature"),
  geometry: z
    .object({
      type: z.string(),
      coordinates: z.any().optional(),
    })
    .nullable()
    .optional(),
  properties: FeaturePropsSchema.default({}),
});

const GeoJSONSchema = z.object({
  type: z.literal("FeatureCollection"),
  features: z.array(GeoJSONFeatureSchema),
});

function slugify(input: string): string {
  return input
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/--+/g, "-");
}

function pickName(p: z.infer<typeof FeaturePropsSchema>): string | null {
  return (
    p.name_official ||
    p.suburb_name ||
    p.name ||
    p.suburb ||
    null
  );
}

function pickLgaName(p: z.infer<typeof FeaturePropsSchema>): string | null {
  return p.lga_name || p.lga || p.LGA || p.council || null;
}

function pickLatLon(
  feature: z.infer<typeof GeoJSONFeatureSchema>
): { lat?: number | null; lon?: number | null } {
  const p = feature.properties || {};
  const lat = p.centroid_lat ?? p.lat;
  const lon = p.centroid_lon ?? p.lon;

  // geometry point fallback if present and numbers
  if (
    (lat == null || lon == null) &&
    feature.geometry &&
    feature.geometry.type === "Point" &&
    Array.isArray(feature.geometry.coordinates) &&
    feature.geometry.coordinates.length >= 2 &&
    Number.isFinite(feature.geometry.coordinates[0]) &&
    Number.isFinite(feature.geometry.coordinates[1])
  ) {
    return { lat: feature.geometry.coordinates[1], lon: feature.geometry.coordinates[0] };
  }

  return { lat: lat ?? null, lon: lon ?? null };
}

function toRow(feature: z.infer<typeof GeoJSONFeatureSchema>): SuburbRow | null {
  const p = feature.properties || {};
  const name = pickName(p);
  const lgaName = pickLgaName(p);
  if (!name || !lgaName) return null;

  const suburbSlug = p.suburb_slug || p.slug || slugify(name);
  const lgaSlug = p.lga_slug || slugify(lgaName);
  const { lat, lon } = pickLatLon(feature);

  return { name, lgaName, suburbSlug, lgaSlug, lat, lon };
}

async function readIfExists(file: string): Promise<string | null> {
  try {
    await fsp.access(file, fs.constants.R_OK);
    return await fsp.readFile(file, "utf8");
  } catch {
    return null;
  }
}

export async function getAllSuburbs(): Promise<SuburbRow[]> {
  const root = process.cwd();
  const candidates = [
    path.join(root, "src/data/suburbs_enriched.geojson"),
    path.join(root, "src/data/suburbs.geojson"),
  ];

  let raw: string | null = null;
  let source: string | null = null;
  for (const f of candidates) {
    raw = await readIfExists(f);
    if (raw) { source = f; break; }
  }

  if (!raw) {
    console.warn(
      "[suburbs] No dataset found. Add src/data/suburbs_enriched.geojson (preferred) or src/data/suburbs.geojson."
    );
    return [];
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (e) {
    console.error(`[suburbs] Failed to parse JSON from ${source}:`, e);
    return [];
  }

  const g = GeoJSONSchema.safeParse(parsed);
  if (!g.success) {
    console.error(`[suburbs] Invalid GeoJSON in ${source}:`, g.error.format());
    return [];
  }

  const rows: SuburbRow[] = [];
  for (const feat of g.data.features) {
    const row = toRow(feat);
    if (row) rows.push(row);
  }

  // Deduplicate by composite key & sort stable
  const seen = new Set<string>();
  const unique = rows.filter((r) => {
    const k = `${r.lgaSlug}__${r.suburbSlug}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });

  unique.sort((a, b) =>
    a.lgaSlug === b.lgaSlug ? a.suburbSlug.localeCompare(b.suburbSlug) : a.lgaSlug.localeCompare(b.lgaSlug)
  );

  console.log(`[suburbs] Loaded ${unique.length} rows from ${path.relative(root, source!)}`);
  return unique;
}
```

---

# 5) Use it in your SSG route

`src/pages/areas/[lga]/[suburb]/index.astro` (unchanged shape, now real data):

```astro
---
import "~/styles/global.css";
import type { SuburbRow } from "~/lib/data/suburbs";
import { getAllSuburbs } from "~/lib/data/suburbs";

export async function getStaticPaths() {
  const rows = await getAllSuburbs();
  return rows.map((r) => ({
    params: { lga: r.lgaSlug, suburb: r.suburbSlug },
    props: r
  }));
}

const { name, lgaName, lat, lon } = Astro.props as SuburbRow;
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{name} — {lgaName}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body class="min-h-screen bg-white text-slate-900">
    <main class="mx-auto max-w-3xl p-6">
      <h1 class="text-3xl font-bold">{name}</h1>
      <p class="mt-4">Within {lgaName}.</p>
      {lat && lon ? <p class="mt-2 text-sm text-slate-600">Centroid: {lat}, {lon}</p> : null}
    </main>
  </body>
</html>
```

---

# 6) CSV → GeoJSON converter (optional)

`scripts/data/csv-to-geojson.mjs`

```js
#!/usr/bin/env node
/**
 * CSV → GeoJSON converter for your suburbs dataset.
 * Expected columns (case-insensitive, best-effort mapping):
 *  - name_official | name | suburb_name | suburb
 *  - lga_name | lga | LGA | council
 *  - suburb_slug | slug (optional)
 *  - lga_slug (optional)
 *  - centroid_lat | lat
 *  - centroid_lon | lon
 *
 * Usage:
 *   node scripts/data/csv-to-geojson.mjs src/data/suburbs_enriched.csv src/data/suburbs_enriched.geojson
 */

import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";

const [,, inPath, outPath] = process.argv;
if (!inPath || !outPath) {
  console.error("Usage: node scripts/data/csv-to-geojson.mjs <input.csv> <output.geojson>");
  process.exit(1);
}

const text = await fsp.readFile(inPath, "utf8");

// Minimal CSV parser that handles quotes and commas
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
  // last field
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
```

---

# 7) Dataset validator (optional but handy)

`scripts/data/validate-suburbs.mjs`

```js
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
```

---

# 8) Tiny README for data folder (optional)

`src/data/README.md`

```md
# Data

Preferred dataset:
- `suburbs_enriched.geojson` (GeoJSON FeatureCollection)
  - properties include: `name_official`, `lga_name`, optional `suburb_slug`, `lga_slug`, and optionally `centroid_lat`, `centroid_lon`
  - geometry may be `Point` using centroid lon/lat

Fallback:
- `suburbs.geojson` with similar shape.

CSV conversion:
- Put your CSV at `src/data/suburbs_enriched.csv`
- Run: `npm run data:csv2geo`
- Then validate: `npm run data:validate`
```

---

## How this flows

1. Put your **GeoJSON** in `src/data/` (or convert from CSV).
2. `getStaticPaths()` pulls rows via `getAllSuburbs()` and **pre-renders every suburb** (pure SSG).
3. If the dataset is missing or malformed, the build won’t explode—no pages are generated and you’ll get console warnings so CI stays readable.
4. `data:validate` gives you a quick guard before `astro build`.

If you want me to enforce **strict failure** in CI (exit 1 if 0 suburbs found), say the word and I’ll flip the guardrail to “hard fail.”
