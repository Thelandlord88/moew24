# Geo Linking Pack (Astro)

This pack wires: tier derivation → cluster/coverage validation → page-context generation → CI gate.

## Install
Copy the files into your repo root (preserving paths). Or unzip the bundle at the root.

## Run order
```bash
node scripts/geo/cluster_doctor.mjs --write --json --md --strict   # sanity of adjacency↔clusters↔coverage
node scripts/geo/derive-meta-tiers.mjs --write                      # sets core/expansion/support
node scripts/geo/page-context.mjs                                   # writes src/gen/geoPageContext.ts + report
node scripts/geo/linking_gate.mjs                                   # CI gate
```

Optional scaffold:
```bash
node scripts/geo/bootstrap_page_context.mjs .
```

## Config knobs
See `config/geo.linking.config.json`. Important:
- `allowedTiersForPages`: which tiers produce real pages (and anchors).
- `links.primaryMax/secondaryMax`: per-page caps.
- `links.minPrimaryPerPage`: CI minimum for strong pages.
- `neighbor.preferSameCluster`: order neighbors by cluster.
- `neighbor.maxCrossCluster`: cap cross-cluster primary links per page.
- `anchorTemplatesFile`: anchor copy variants (see `config/anchor.templates.json`).

## Inputs expected
- `data/adjacency.json` (or `map data/adjacency.json`)
- `data/areas.extended.clusters.json` (or `map data/areas.extended.clusters.json`)
- `data/serviceCoverage.json` (or `map data/serviceCoverage.json`)
- `src/data/suburbs.meta.json`

## Outputs
- `src/gen/geoPageContext.ts`
- `__reports/geo-linking.summary.json` (+ optional `geo-link-anchors.json`)
- Doctor: `__reports/geo-page-coverage.report.json` & `.summary.md`
- Tiers: `__reports/geo-coverage-correlation.json` & `.md`

## CI (GitHub Actions snippet)
```yaml
- run: node scripts/geo/cluster_doctor.mjs --write --json --md --strict
- run: node scripts/geo/derive-meta-tiers.mjs --write
- run: node scripts/geo/page-context.mjs
- run: node scripts/geo/linking_gate.mjs
```
