# Geo Internal Linking & SEO Strategy

Generated: 2025-09-15
Related Data Assets: `src/data/adjacency.json`, `config/adj.bridges.json`, `src/data/suburbs.meta.json`, `src/data/areas.clusters.json`

---
## 1. Why the Geo Graph Matters for SEO
| SEO Objective | How the Adjacency Graph Enables It |
|---------------|------------------------------------|
| Topical Authority (E-E-A-T) | Dense, geographically coherent interlinking signals comprehensive service coverage within a region. |
| Crawl Efficiency | Predictable, breadth-first navigable mesh (no isolates, single component) lets bots discover all local pages with shallow depth. |
| Long-Tail Capture | Each suburb page can surface tightly related micro-intents ("service in {neighbor suburb}") via near-suburb anchors. |
| Relevance & Semantic Context | Mutual, distance-bounded links reduce noise vs arbitrary tag clouds; anchors reflect real-world proximity. |
| Link Equity Distribution | Degree normalization + forced bridges remove rank sinks (previous isolates) and prevent orphaning. |
| Structured Data Enhancement | Graph supports generating JSON-LD `areaServed`, `geo`, and `relatedLink` arrays that mirror real adjacency. |
| Cluster (City/LGA) Theming | Cluster-level rollups unify internal linking silos without spiking cross-cluster leakage (kept <3%). |
| UX + Conversion | Nearby suburbs pre-listed lower friction for user path refinement ("I'm 2km away in X suburb"). |

---
## 2. Core Data Concepts
- **Adjacency (Mutual kNN + Pruning)**: Ensures each suburb links only to a curated set of geographically nearest peers.
- **Forced Bridges**: Small, auditable set of synthetic edges eliminating isolates (currently 11 / 1175 ≈ 0.94%).
- **Tiers**: Distinguish `core` vs `maritime` vs `remote` to allow policy exceptions & styling (e.g., badge or tooltip). 
- **Clusters**: Higher-order grouping (e.g., Brisbane / Logan / Ipswich) for hub pages & hierarchical navigation.

Graph Snapshot (Post Tuning):
```
components: 1
mean_degree: ~6.8
min_degree: 2 (core_min: 2)
cross_cluster_ratio: ~0.027
forced_edge_share: <1%
```

---
## 3. Linking Model per Suburb Page
| Layer | Purpose | Source | Cardinality (typical) |
|-------|---------|--------|-----------------------|
| Primary Neighbors | Core contextual navigation | Top N (e.g. 6–8) adjacency entries | 6–8 |
| Bridge Highlights | Ensure remote coverage & explain outliers | Forced edge list intersecting page | 0–2 |
| Cluster Siblings | Broader cluster expansion / hub internal equity | All cluster suburbs (capped, sample) | 4–12 (sampled) |
| Cross-Cluster Gateways | Controlled leakage for authority & breadth | Cross-cluster edges (rank by distance) | 1–2 |
| Secondary (Rotational) | Reduce link staleness; rotate remaining adjacency set each build | Adjacency minus primary | 2–4 (optional) |
| Hierarchical Up-Link | Provide parent context (Cluster/LGA page) | clusters file | 1 |
| Geo Service Variants | Intent-specific anchor text expansions | Derived from adjacency & service taxonomy | M (configurable) |

---
## 4. Build-Time Precomputation Pipeline
1. **Load Data**: `adjacency.json`, clusters, meta, bridges.
2. **Enrich Node Objects**: For each suburb slug compute:
   - `neighborsPrimary`: first K adjacency entries (sorted by distance if distances stored later; presently lexical → recommend optional distance embedding file).
   - `neighborsAll`: full adjacency list.
   - `forcedNeighbors`: subset where pair in forced edges.
   - `cluster`: cluster slug; `clusterSiblingsSample`: sample using deterministic hash (e.g. stable shuffle + slice). 
   - `crossCluster`: neighbors where cluster differs; sorted ascending by degree of target to favor less saturated pages.
   - `linkVariants`: e.g. `[{ text: "{service} in {neighbor}", href:"/suburbs/{neighbor}" }]` for each service family.
3. **Generate Static JSON/TS Module**: `src/gen/geoPageContext.ts` exporting a map: `export const GEO_PAGE_CTX: Record<string, GeoPageCtx> = {...}`.
4. **Astro Integration**: In `getStaticPaths`, import `GEO_PAGE_CTX`; return one entry per slug with `props: GEO_PAGE_CTX[slug]`.
5. **Page Component Usage**:
   ```astro
   ---
   import Layout from '../layouts/SuburbLayout.astro';
   export async function getStaticPaths() { return Object.entries(GEO_PAGE_CTX).map(([slug, ctx]) => ({ params:{ slug }, props: ctx })); }
   const { neighborsPrimary, crossCluster, clusterSiblingsSample, linkVariants } = Astro.props;
   ---
   <Layout>
     <PrimaryLinks items={neighborsPrimary} />
     <ClusterLinks items={clusterSiblingsSample} />
     <CrossClusterLinks items={crossCluster} />
     <ServiceIntents items={linkVariants.slice(0,8)} />
   </Layout>
   ```
6. **LD-JSON Injection (Optional)**: Build `relatedLink` array from `neighborsPrimary` and forced edges, embed via `<script type="application/ld+json">`.

---
## 5. Anchor Text Strategy (SEO)
| Anchor Pattern | When Used | Rationale |
|----------------|----------|-----------|
| `{Neighbor Suburb}` | Primary / forced | Pure geo relevance, minimal risk |
| `{Service} – {Neighbor Suburb}` | Service intent section | Captures long-tail transactional queries |
| `Nearby: {Neighbor}, {Neighbor}` | Inline paragraph linking | Natural language internal linking |
| `{Cluster} area: {Neighbor}` | Cluster siblings | Reinforces cluster topical term |
| `Also serving {Neighbor}` | Footer service coverage | Signals breadth to crawlers |

Avoid: Over-optimized repetitive `service in suburb` blocks; rotate template variants.

---
## 6. Controlling Link Volume & Quality
- **Max Links Heuristic**: Keep total internal links per page (body + nav + geo sets) under a configured threshold (e.g. 120) to avoid dilution.
- **Degree Normalization**: If a node’s degree > P90, downsample primary neighbors to maintain parity; track fairness metric.
- **Forced Edge Styling**: Optionally badge forced edges with subtle marker + `title` attribute clarifying bridging role (human trust & editorial transparency).

---
## 7. Future Enhancements
| Enhancement | Description | SEO / UX Benefit |
|-------------|-------------|------------------|
| Distance Weights | Store distance (km) in adjacency export to order neighbors semantically | Better relevance ordering & snippet logic |
| Semantic Enrichment | Add local embeddings (service × suburb) for anchor variant diversity | Reduces repetitive anchors, enhances topical depth |
| Hierarchical Subclusters | Two-level nav: micro-cluster pages (e.g. North-West Corridor) | Improves crawl segmentation & silo clarity |
| Link Rotation Ledger | Track which neighbors got primary placement over time | Distributes internal equity fairly |
| A/B Monitoring | Server logs + search console mapping of CTR vs link position | Data-driven internal link refinement |
| Content Gap Analyzer | Compare service taxonomy coverage across neighbor sets | Ensures consistent intent distribution |

---
## 8. Risk Controls
| Risk | Mitigation | Monitoring Metric |
|------|------------|-------------------|
| Over-linking / link spam | Cap counts per section; enforce test | `links_per_section` in build report |
| Anchor Homogeneity | Template pool with hashing rotation | `anchor_diversity_index` |
| Cross-Cluster Leakage Drift | Maintain ratio threshold + derivative guard | `cross_cluster_ratio_drift` |
| Forgotten Forced Edges Growth | % forced edges gating (<2%) | `forced_edge_pct` |
| Orphan Regression | Gate on min core degree >= 2 | `core_min_degree` |

---
## 9. Proposed Build Artifacts (Additions)
| File | Purpose |
|------|---------|
| `__reports/geo-linking.summary.json` | Per-page link counts + diversity metrics |
| `src/gen/geoPageContext.ts` | Astro props source of truth |
| `__reports/geo-anchor-templates.json` | Catalog of active anchor patterns |
| `__reports/geo-link-fairness.json` | Degree vs actual primary link exposure distribution |

Schema sketch for linking summary:
```json
{
  "slug": {
    "primary_count": 7,
    "cross_cluster_count": 1,
    "forced_count": 1,
    "cluster_sample_count": 6,
    "total_internal_geo_links": 18,
    "anchor_diversity_index": 0.78
  }
}
```

---
## 10. Implementation Checklist (Incremental)
1. Generate `geoPageContext` builder script.  
2. Integrate into Astro `getStaticPaths`.  
3. Add LD-JSON generator component.  
4. Add test: no page exceeds max geo links threshold.  
5. Add test: `forced_edge_pct < 0.02`.  
6. Add drift report for `cross_cluster_ratio`.  
7. Introduce anchor template variants + rotation seed.  
8. Add fairness metrics & gating.  

---
## 11. Example Geo Page Props Object
```ts
interface GeoPageCtx {
  slug: string;
  cluster: string | null;
  tier: string; // core | maritime | remote
  neighborsPrimary: string[]; // top adjacency subset
  forcedNeighbors: string[];
  crossCluster: string[]; // small set of cross-cluster neighbors
  clusterSiblingsSample: string[];
  linkVariants: { text:string; href:string; intent?:string }[];
  metrics: { degree:number; isForced:boolean; }; // simplified illustration
}
```

---
## 12. Why This Is Durable
- **Determinism**: Build outputs (adjacency, context) are stable & hashable → minimal noisy diffs.
- **Auditable Overrides**: Forced bridges & tiers are explicit JSON—no hidden heuristics.
- **Scalable**: Additional suburbs only require adjacency regeneration; linking logic auto-propagates.
- **Extensible**: Distance & semantic weighting can be layered without changing baseline graph contract.
- **Governable**: Existing gating infra can ingest linking metrics for CI enforcement.

---
## 13. Summary
By fusing geographic adjacency (graph-theoretic rigor) with a disciplined build-time enrichment pipeline, we can mass-generate internal linking structures that are:
- Relevant (distance-constrained)
- Balanced (degree normalized, no isolates)
- Efficient to crawl (single component, controlled leakage)
- Flexible for future semantic enrichment (service variants, subclusters)

This positions the site to scale localized landing pages while preserving a coherent, authoritative internal link mesh—directly boosting topical authority, indexation reliability, and long-tail query capture.

*Next action suggestion*: implement the `geoPageContext` generator plus a minimal Astro integration prototype to validate prop shapes and link counts before layering advanced features.
