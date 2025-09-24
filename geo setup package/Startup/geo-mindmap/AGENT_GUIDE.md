# Agent Guide — Geo System

This document gives **explicit steps** and **acceptance checks** for an automated agent to keep the geo system healthy.

## Inputs
- `src/data/suburbs_enriched.geojson` (preferred) or `src/data/suburbs.geojson`
- Optional: `src/data/suburbs_enriched.csv` (to generate the GeoJSON)
- Optional: `src/data/adjacency.csv` (edge list)
- Optional: `src/data/region-map.json` (LGA → region mapping)

## Steps
1. If `suburbs_enriched.csv` exists → run: `npm run data:csv2geo`
2. Run: `npm run geo:from:geojson`
3. If `adjacency.csv` exists → run: `npm run geo:adj:from:csv`
4. Run validations: `npm run geo:validate` (must exit code 0)
5. Build: `npm run build` (or `npm run geo:prebuild && astro build`)
6. Post-build checks:
   - `npm run perf:psi` must pass budgets (exit 0)
   - `npm run test:e2e` must pass (exit 0)

## Acceptance Criteria
- Files present: `src/data/areas.clusters.json`, `src/data/areas.adj.json`
- Validators report **no**: unknown ids, missing names/LGAs, self loops, asymmetry
- Build succeeds and produces `dist/`
- PSI: performance ≥ threshold, LCP/CLS/INP/TBT within budgets
- E2E: all tests green

## Fallback/Recovery
- If `suburbs_enriched.geojson` missing → attempt to build from `suburbs_enriched.csv`
- If adjacency invalid → regenerate from `adjacency.csv` with `--symmetric`, then re-validate
- If PSI fails → re-run once; if still failing, lower preview budgets by 5–10% (never in production)
