# Geo System — Drop-in Docs

This docs set explains how our geo pipeline works and links to **existing scripts by relative path**.

## Scripts (relative links)

- [`../scripts/data/csv-to-geojson.mjs`](../scripts/data/csv-to-geojson.mjs)
- [`../scripts/data/geojson-to-clusters.mjs`](../scripts/data/geojson-to-clusters.mjs)
- [`../scripts/data/adjacency-from-csv.mjs`](../scripts/data/adjacency-from-csv.mjs)
- [`../scripts/data/validate-suburbs.mjs`](../scripts/data/validate-suburbs.mjs)
- [`../scripts/data/validate-adj.mjs`](../scripts/data/validate-adj.mjs)
- [`../scripts/geo/prebuild-geo.sh`](../scripts/geo/prebuild-geo.sh)

## Data files

- `../src/data/suburbs_enriched.geojson` (preferred)
- `../src/data/suburbs.geojson` (fallback)
- `../src/data/areas.clusters.json` (generated)
- `../src/data/areas.adj.json` (generated)
- `../src/data/adjacency.csv` (optional source)
- `../src/data/region-map.json` (optional mapping)

See the Mermaid diagrams:

- `geo-system-mindmap.mmd`
- `geo-system-flowchart.mmd`
