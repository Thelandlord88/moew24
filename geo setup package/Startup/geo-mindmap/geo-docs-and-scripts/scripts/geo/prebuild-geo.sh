#!/usr/bin/env bash
set -euo pipefail

echo "▶ Geo prebuild: GeoJSON → clusters"
node scripts/data/geojson-to-clusters.mjs src/data/suburbs_enriched.geojson

echo "▶ Geo prebuild: adjacency.csv → areas.adj.json"
if [ -f "src/data/adjacency.csv" ]; then
  node scripts/data/adjacency-from-csv.mjs src/data/adjacency.csv src/data/areas.adj.json --symmetric
else
  echo "  (no src/data/adjacency.csv found — skipping adjacency rebuild)"
fi

echo "▶ Geo prebuild: validate"
node scripts/data/validate-suburbs.mjs
node scripts/data/validate-adj.mjs

echo "✅ Geo prebuild complete"
