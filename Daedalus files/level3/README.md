# Daedalus — Level 3 (Internal-Link Policy Engine + Sitemaps/Robots)

This overlay upgrades your Level 1/2 Daedalus with:
- **Internal-link policy engine** (distance-weighted, cluster-aware, reciprocity-aware, hub-dampened).
- **Crawl-budget caps** (per-page and global inbound fairness) with round-robin selection.
- **Reciprocity enforcement** (optional) with conflict-safe quotas.
- **Sitemap partitioning** and **robots.txt** emission with configurable disallows.
- **Expanded reports** (`links.scored.json`, `sitemaps.json`).

## Apply
```bash
unzip daedalus_level3.zip -d .
node scripts/daedalus/cli.mjs build
```

## New config (merge into `daedalus.config.json`)
```json
{
  "policies": {
    "neighborsMax": 8,
    "neighborsMin": 4,
    "enforceReciprocity": true,
    "globalInboundCap": 40,
    "scoring": {
      "weightCluster": 1.0,
      "weightDistance": 1.2,
      "distanceScaleKm": 12,
      "weightReciprocalEdge": 0.8,
      "weightHubDamping": 0.6
    }
  },
  "sitemaps": {
    "partitionSize": 5000,
    "path": "public",
    "includeServices": ["*"]
  },
  "robots": {
    "userAgent": "*",
    "disallow": ["/api/", "/__reports/"],
    "extra": []
  }
}
```
> If you lack coordinates in `suburbs.meta.json`, the engine falls back to cluster affinity + hub damping.

## What changes
- Replaces `scripts/daedalus/plugins/05-internal-links.mjs` with a policy engine that plans links **globally** first for fairness.
- Adds `scripts/daedalus/plugins/07-sitemap-robots.mjs` to emit `public/sitemap.xml` (+ partitions) and `public/robots.txt`.
- Adds reports: `__reports/daedalus/links.scored.json`, `__reports/daedalus/sitemaps.json`.

