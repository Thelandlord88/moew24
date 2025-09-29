# Owner TODO (Geo + SEO + Invariants)

1) Replace placeholders:
   - `data/suburbs.geojson` with ABS-enriched features (lat/lng present)
   - `data/serviceCoverage.json` mapping services→valid suburb slugs
   - (Optional) `src/content/areas.clusters.json` for editorial clusters
   - (Optional) `sandbox/geo/raw/*` for CSV/GeoJSON enrichment sources (create if needed)
2) Configure `SITE_URL` env or use `--site=` flag.
3) CI: run `npm run predeploy` to block broken builds (sync→doctor→build→SEO→invariants).
4) Use doctor’s extras:
   - `npm run geo:doctor -- --explain ipswich` → saves `__ai/geo-explain-ipswich.json`
   - `npm run geo:doctor -- --graph`          → saves `__ai/geo-adjacency.dot`
   - `npm run geo:doctor -- --write`          → writes `__ai/geo-proximity-fixed.json`
