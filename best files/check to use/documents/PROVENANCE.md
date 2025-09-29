## Geo Data Provenance

Document the origin & refresh procedure for each canonical geo data file.

| File | Source / Generation | Refresh Command | Notes |
|------|---------------------|-----------------|-------|
| `src/data/adjacency.json` | Derived via bridge + overlay merge | `npm run geo:metrics` (post-bridge) | Must remain symmetric (doctor enforces) |
| `src/data/areas.adj.json` | Editorial cluster mapping | Manual edit + lint | Keep slugs lowercase |
| `src/data/areas.clusters.json` | Editorial cluster defs | Manual edit | Sync with `cluster_map.json` |
| `src/data/cluster_map.json` | Generated mapping cluster->suburbs | `npm run geo:metrics` | Deterministic |
| `src/data/proximity.json` | Metrics proximity builder | `npm run geo:metrics` | Distance thresholds in config |
| `src/data/suburbs_enriched.geojson` | External + enrichment script | External fetch -> transform script | Strip unused props |

### Refresh Workflow
1. Update raw sources in `sandbox/geo/raw/` (if needed).
2. Run: `npm run geo:metrics`.
3. Verify: `npm run geo:doctor` (all green).
4. Run gate: `npm run geo:gate` (severity + coverage pass).
5. Commit changes & update this file if structure changed.

### Integrity Hashes (Future)
Add a script to compute SHA256 for canonical files and compare on gate.
