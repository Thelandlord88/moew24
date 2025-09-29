# Adjacency: Source of Truth for Geo Linking

## What it is
A normalized **undirected** graph of suburb slugs → neighboring suburb slugs
(geographic or strategic proximity). It seeds internal links, powers scoring
and feeds governance (doctor / gate) plus promotions.

## Files & Ownership
- **Graph:** `data/adjacency.json` → `{ [slug]: string[] }`
- **Clusters:** `data/areas.extended.clusters.json` → `{clusters:[{slug,name,suburbs:string[]}]}` or flat map
- **Coverage/pages:** `data/serviceCoverage.json` → `{ [service]: string[] }`
- **Tiers/meta:** `src/data/suburbs.meta.json` → `{nodes:{ [slug]: {tier,…} }}`

## Contract (guarantees)
- slugs are **kebab-case**, lowercase
- **no self-loops**, **symmetric** edges (or symmetric artifact generated)
- every cluster suburb exists in adjacency (or policy ignore list)
- promotions never render 404s (only live pages rendered)

## Generation & Validation (CLI)
- Symmetry/health: `node scripts/geo/doctor.mjs --json`
- Gate (CI): `node scripts/geo/gate.mjs --json`
- Slug hygiene: `node scripts/geo/validate-slugs.mjs --json`
- Cluster overlaps: `node scripts/geo/validate-cluster-membership.mjs --json`
- Reconcile missing cluster members: `node scripts/geo/reconcile-clusters.mjs --json`

## Rendering rules (front end)
- **Primaries:** adjacency neighbors filtered by cluster caps + live pages
- **Promoted primaries:** only render if target has a live page
- **Secondaries:** retained for analytics / future modules (not always rendered)
- **Anchor diversity:** 0–1 anchors ⇒ diversity 0 (no variety)

## Governance metrics (doctor)
- Symmetry & optional autofix (`__reports/geo-adjacency.symmetric.json`)
- Components (count + largest_ratio)
- Cross-cluster ratio + per-cluster counts
- Coverage by cluster (% with coordinates)
- Mismatches: `clusters_not_in_adjacency` (fail) / `adjacency_not_in_clusters` (warn or policy)

## SEO guardrails
- 5–8 primaries per page is healthy
- Use descriptive, varied anchor templates
- Avoid internal `nofollow`; use selective linking instead

## Policy knobs (`geo.policy.json` excerpt)
```json
{
  "policyVersion": 1,
  "maxAllowedSeverity": "error",
  "perCluster": { "ipswich": { "minCoordsPct": 90 } },
  "crossCluster": { "maxRatioWarn": 0.02, "maxRatioError": 0.05 },
  "mismatches": {
    "failOnClustersNotInAdjacency": true,
    "failOnAdjacencyNotInClusters": false,
    "ignore": { "clusters_not_in_adjacency": [], "adjacency_not_in_clusters": [] }
  },
  "linking": { "promotions": { "maxPagesWithDiscardWarn": 10, "maxPagesWithDiscardFail": 999999 } }
}
```

## Quick cookbook
```
# end-to-end health
node scripts/geo/doctor.mjs --json | jq '.report.edges, .report.mismatches'

# gate (CI)
node scripts/geo/gate.mjs --json

# reconcile adjacency-only slugs
node scripts/geo/reconcile-clusters.mjs --json
```

---
Last updated: ${new Date().toISOString()}
# Adjacency: Source of Truth for Geo Linking

## What it is
A normalized **undirected** graph of suburb slugs → neighboring suburb slugs (geographic or strategic proximity). It seeds internal links, powers scoring (expansion/core), and feeds governance (doctor / gate).

## Files & Ownership
- **Graph:** `data/adjacency.json` → `{ [slug]: string[] }`
- **Clusters:** `data/areas.extended.clusters.json` → object with `clusters:[{slug,name,suburbs:string[]}]` (or flat map form)
- **Coverage/pages:** `data/serviceCoverage.json` → `{ [service]: string[] }`
- **Tiers/meta:** `src/data/suburbs.meta.json` → `{ nodes:{ [slug]: { tier, ... } } }`

## Contract (guarantees)
- Slugs are **kebab-case**, lowercase
- **No self-loops**, **symmetric** edges (or an autofixed symmetric artifact is emitted)
- Every cluster suburb exists in adjacency (or appears on a policy ignore list)
- Promotions never render 404s (see Rendering)

## Generation & Validation (CLI)
```
node scripts/geo/doctor.mjs            # symmetry & health
node scripts/geo/gate.mjs --json        # policy gate
node scripts/geo/validate-slugs.mjs --json
node scripts/geo/validate-cluster-membership.mjs --json
node scripts/geo/reconcile-clusters.mjs --write   # (if present) propose cluster additions
```

## Rendering rules (front end)
- **Primaries:** adjacency neighbors filtered by cluster caps + existing pages
- **Promoted primaries:** rendered only if target has a live page (or generic dynamic route)
- **Secondaries:** stored for tooling; may be selectively rendered
- **Anchor diversity:** 0–1 anchors ⇒ diversity **0** (no variety)

## Governance metrics (doctor)
- Symmetry & optional autofix → `__reports/geo-adjacency.symmetric.json`
- Component count & `largest_ratio`
- Cross-cluster ratio + per-cluster cross counts
- Coverage by cluster (% with coordinates)
- Mismatches:
  - `clusters_not_in_adjacency` → fail (unless ignored)
  - `adjacency_not_in_clusters` → warn/fail per policy

## SEO guardrails
- 5–8 primaries per page (healthy range)
- Keep link blocks in-body where possible
- Unique descriptive anchor templates; avoid boilerplate duplication
- Avoid `rel="nofollow"` on internal links; control via selection not attributes

## Policy knobs (`geo.policy.json` excerpt)
```json
{
  "policyVersion": 1,
  "maxAllowedSeverity": "error",
  "perCluster": { "ipswich": { "minCoordsPct": 90 } },
  "crossCluster": { "maxRatioWarn": 0.02, "maxRatioError": 0.05 },
  "mismatches": {
    "failOnClustersNotInAdjacency": true,
    "failOnAdjacencyNotInClusters": false,
    "ignore": { "clusters_not_in_adjacency": [], "adjacency_not_in_clusters": [] }
  }
}
```

## Quick cookbook
```
# end-to-end health
node scripts/geo/doctor.mjs --json | jq '.report.edges, .report.mismatches'

# gate (CI)
node scripts/geo/gate.mjs --json

# reconcile missing cluster assignments
node scripts/geo/reconcile-clusters.mjs --write
```
