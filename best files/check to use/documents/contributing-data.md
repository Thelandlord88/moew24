# Contributing to Data Files

This site precomputes cross-service links and validates all data at build time.

## Pre-push checklist

```bash
npm run css:baseline:check
npm run prebuild             # shape + semantics + buildable + graph + symmetry
npm test                     # unit + integration
npm run lint:cross           # parity (sample locally)
```

## Files

- `src/content/areas.clusters.json` — Suburbs grouped by cluster.
- `src/data/serviceCoverage.json` — Coverage tokens per service (suburb slugs **or** cluster slugs).
- `src/data/adjacency.json` — Neighbor tables per suburb.

Adjacency accepted shapes:

```jsonc
{
  "ashgrove": ["red-hill", "bardon"],
  "red-hill": { "adjacent_suburbs": ["ashgrove"] }
}
```

## Rules

- Use kebab-case slugs: `st-lucia`, `upper-brookfield`.
- A suburb belongs to one cluster only.
- Adjacency must be symmetric.
- Cross-cluster edges are not allowed.

## Common failures

| Failure | Cause | Fix |
|---------|-------|-----|
| Unknown coverage tokens | Misspelled suburb/cluster | Correct token or add cluster |
| Suburb in multiple clusters | Duplicate entry | Remove duplicate |
| CROSS EDGE | Adjacency crosses clusters | Remove edge |
| ASYM | Missing reverse neighbor | Add reverse or remove forward |
| SELF-LOOP / DUP-NEIGHBORS | Authoring mistake | Remove self/duplicate |

## Strict mode

Enable slug strictness in CI when ready:

```bash
STRICT_MODE=1 npm run lint:data
```
