# Geo Hierarchical Sub-Clusters Proposal ("brisbane-west", "brisbane-cbd", etc.)

Status: Draft – design + migration plan for introducing second-level geographic segmentation beneath current top-level clusters.

## 1. Objective

Enable finer-grained geographic modeling by subdividing existing top-level clusters (e.g. `brisbane`) into named sub-clusters (e.g. `brisbane-west`, `brisbane-cbd`, `brisbane-north`), while preserving:
- Deterministic analytics (metrics, doctor, diff).
- Backward compatibility for existing cluster-based pages & scripts during a transition window.
- Policy-driven gating (fragmentation, coverage) at both cluster and (optionally) sub-cluster levels.

## 2. Current vs Future Shape

### 2.1 Current (`areas.clusters.json` simplified)
```jsonc
[
  {
    "slug": "brisbane",
    "name": "Brisbane",
    "suburbs": [ { "slug": "fortitude-valley", "lat": -27.45, "lng": 153.03 }, ... ]
  },
  { "slug": "ipswich", ... },
  { "slug": "logan", ... }
]
```

### 2.2 Proposed Hierarchical Shape
Option A (embedded subclusters array inside parent):
```jsonc
[
  {
    "slug": "brisbane",
    "name": "Brisbane (Parent Aggregate)",
    "subclusters": [
      {
        "slug": "brisbane-cbd",
        "name": "Brisbane CBD",
        "suburbs": [ { "slug": "brisbane-city", "lat": -27.468, "lng": 153.024 }, ... ]
      },
      {
        "slug": "brisbane-west",
        "name": "Brisbane West",
        "suburbs": [ { "slug": "toowong", ... }, ... ]
      }
    ]
  },
  { "slug": "ipswich", ... }
]
```

Option B (flat list with `parent` pointer):
```jsonc
[
  { "slug": "brisbane", "name": "Brisbane", "kind": "parent" },
  { "slug": "brisbane-cbd", "parent": "brisbane", "suburbs": [ ... ] },
  { "slug": "brisbane-west", "parent": "brisbane", "suburbs": [ ... ] },
  { "slug": "ipswich", ... }
]
```

### 2.3 Recommendation
Use **Option B** (flat with `parent`) because:
- Simpler diffing and streaming parsing (no nested arrays scanning).
- Easier incremental rollout (can add subclusters one at a time without restructuring parent object).
- Avoids duplicating suburb lists (parent can be logical aggregate without explicit `suburbs`).

## 3. Data Model Additions
| Field | Type | Applies To | Description |
|-------|------|-----------|-------------|
| `parent` | string (slug) | sub-cluster rows | Points to top-level cluster slug. Absent for top-level. |
| `kind` | enum: `parent` \| `leaf` (optional) | any | Explicit classification; if omitted: `leaf` when has suburbs, `parent` when has children. |
| `level` | number (computed) | runtime | 0 for top-level, 1 for sub-cluster. |
| `suburbs` | array | leaf only | Same semantics as current. |
| `representatives` | object (future) | parent (aggregated) | Optionally store derived aggregated reps (weighted or union strategy). |

## 4. Migration Strategy
| Phase | Goal | Actions | Risk Mitigation |
|-------|------|--------|-----------------|
| 0 (Now) | Design acceptance | Add proposal doc (this file); align owners. | None. |
| 1 | Introduce parser support | Extend runtime to accept `parent` attribute; treat all current clusters as level 0. | Feature flag `GEO_ENABLE_SUBCLUSTERS`. |
| 2 | Add initial subclusters (empty) | Insert new leaf entries with `parent` but **no** removal from parent yet. | Parent still holds suburbs; analytics unchanged. |
| 3 | Re-home suburbs | Move subsets from parent `brisbane` into new leaf clusters; parent becomes aggregate only (no direct `suburbs`). | Doctor check: ensure total suburb count stable. |
| 4 | Enable subcluster metrics | Compute per-subcluster coverage, reps, cohesion; keep legacy cluster coverage. | Dual-report fields. |
| 5 | Flip gating | Policy shifts from parent-only to leaf-level (subclusters). | Policy version bump. |
| 6 | Deprecate parent-level direct metrics (optional) | Fully leaf-driven analytics. | Clear changelog + baseline refresh protocol. |

## 5. Runtime & Script Changes
| Component | Change |
|-----------|--------|
| `geoCompat.runtime.js` | Parse flat list; build maps: `clustersLevel0[]`, `subclustersByParent{}`, `allLeafClusters[]`. Provide helper: `expandedClusters()` returning leaf clusters (legacy alias). |
| Metrics (`metrics.mjs`) | Iterate leaf clusters; derive parent aggregate stats (sum suburbs, union adjacency nodes). Add new section: `subcluster_metrics`. |
| Doctor (`doctor.mjs`) | Coverage gating: apply to each leaf; parent gating optional (skip when parent has no suburbs). Add failure type: `subcluster_coverage`. |
| Diff (`diff.mjs`) | Track new fields: `subclusters.count`, maybe `parent_clusters.count`. Churn detection extended for subcluster representatives. |
| Reporter (`report-md.mjs`) | Add badge for subcluster coverage (worst leaf). Show table of top N subclusters with coverage / components. |
| Bridge (`bridge.mjs`) | Unchanged; operates on graph-level nodes. (Later: optionally prefer bridging inside parent first.) |
| Policy (`geo.policy.json`) | Add `perSubcluster` object similar to `perCluster`; add `subclusterMode` = `coexist` | `leaf_only`. |
| Overlay Merge | No change (adjacency independent). |

## 6. Metrics Extensions
New fields (leaf-driven):
```jsonc
{
  "subclusters": 12,
  "subcluster_representatives": { "brisbane-west": {"centroid": "toowong", ... } },
  "subcluster_coverage": { "brisbane-cbd": 1, "brisbane-west": 0.97 },
  "parent_aggregate": { "brisbane": { "leafCount": 5, "suburbCount": 140 } }
}
```

### Representative Strategy for Parents
- Option 1: Not stored (computed ad hoc via union of leaf sets at need time). ✅ (recommend to avoid extra churn)
- Option 2: Derived rep = rep of densest leaf (highest mean degree). (Defer)

## 7. Gating & Policy Evolution
`geo.policy.json` additions:
```jsonc
{
  "policyVersion": 2,
  "subclusterMode": "coexist",           // or "leaf_only"
  "perSubcluster": {
    "brisbane-cbd": { "minCoordsPct": 0.99 },
    "brisbane-west": { "minCoordsPct": 0.97 }
  },
  "allowed_islands": ["bulwer","moreton-island","kooringal","cowan-cowan"],
  "maxComponents": 1,
  "severityOverrides": { }
}
```
Validation logic:
- If `subclusterMode === "coexist"`: maintain both cluster and subcluster coverage arrays.
- If `leaf_only`: fail if any parent retains direct `suburbs` array (migration completeness check).

## 8. Diff & Severity Adjustments
| Field | Severity Rule |
|-------|---------------|
| `subclusters.count` increase | info (expected early) |
| `subclusters.count` drop | warn (possible unintended removal) |
| `subcluster_coverage.*` below policy | error |
| Parent losing all suburbs (planned) | info (if leaf_only) else warn |

## 9. Backward Compatibility Strategy
| Concern | Handling |
|---------|----------|
| Existing pages referencing `cluster.slug` | For parent pages, keep route; optionally add redirect to first leaf or aggregate view. |
| API / internal helpers expecting `clusters[]` | Provide shim: treat `clusters` = leaf set once `leaf_only` enabled. |
| Baseline diffs explosion | Introduce baseline schema upgrade flag `baseline.meta.schemaVersion`. |
| Scripts referencing `cluster_representatives` | Maintain name; add `subcluster_representatives` separately. |

## 10. UI / Routing Considerations
| Page Type | Option A | Option B |
|-----------|----------|----------|
| `/areas/brisbane/*` | Aggregated view – list subclusters + metrics | Redirect to primary subcluster (configurable) |
| `/areas/brisbane-west/*` | Standard leaf pages (existing templates) | Same |
| Sitemap | Include both parent + leaf during coexist | Only leaf in leaf_only mode |
| Breadcrumbs | Region > Subcluster > Suburb | Region > Suburb (if parent-only mode) |

## 11. Representative Selection Changes (Leaf Level)
No algorithm change required. Need to ensure `representativeOfClusterSync` works for both parent & leaf:
- If slug has no `suburbs` but has children → compute on union OR disallow (design choice: disallow & document). Recommended: disallow to avoid conflating levels.

## 12. Fragmentation Impact
Subclusters do **not** change underlying graph nodes. Fragmentation gating unaffected.
- Option (later): intra-parent cohesiveness metric (ratio of edges internal to parent vs crossing other parents) – helpful for verifying subcluster boundaries are meaningful.

## 13. Migration Quality Checks (Add to Doctor)
| Check | Failure Code |
|-------|--------------|
| Parent has both `suburbs` & children (Phase ≥3) | `hybrid_parent` |
| Leaf with 0 suburbs | `empty_subcluster` |
| Duplicate leaf slug across parents | existing slug collision logic |
| Subcluster coverage below override | `subcluster_coverage_low` |

## 14. Script Change Summary
| Script | Change |
|--------|--------|
| `metrics.mjs` | Build `leafClusters`, `parentClusters`. Add `subclusters` count + coverage map. Expose `meta.levels` summary. |
| `doctor.mjs` | Validate hierarchy invariants, enforce perSubcluster coverage. |
| `diff.mjs` | Add comparison rows for `subclusters.count`, optionally `subcluster_coverage.avg`. |
| `report-md.mjs` | Add subcluster table. |
| `bridge.mjs` | No change. |
| `overlay-merge.mjs` | No change. |
| `gate.mjs` (planned) | Include worst subcluster severity in gating decision. |

## 15. Testing Additions
| Test Name | Focus |
|-----------|-------|
| `geoHierarchy.basic.spec.ts` | Mixed parent/leaf parse & counts. |
| `geoHierarchy.coexist.spec.ts` | Parent with suburbs + new leaf accepted in coexist mode. |
| `geoHierarchy.leafOnly.spec.ts` | Fail when parent retains suburbs and `leaf_only` policy active. |
| `geoSubclusterCoverage.spec.ts` | Per-subcluster coverage gating. |
| `geoSubclusterDiff.spec.ts` | Severity classification additions. |

## 16. Rollout Checklist
1. Add `parent` field to *one* pilot subcluster (no removal of suburbs) – verify no breakages.
2. Add runtime hierarchical parsing (feature flag off by default).
3. Enable feature flag in CI branch – compare metrics diff (should be stable except new fields appended).
4. Migrate subsets of suburbs off parent (log coverage, ensure counts stable). Update baseline.
5. Introduce perSubcluster overrides in policy gradually.
6. Switch `subclusterMode` to `leaf_only` when all parents cleaned.
7. Remove superfluous parent coverage metrics from reporter (optional simplification).

## 17. Risk & Mitigation
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Partial migration leads to duplicate suburb assignments | Inconsistent analytics | Add uniqueness validation across all leaves. |
| Parent pages lose SEO value on redirect | Traffic dip | Serve aggregated landing with internal links before redirecting later. |
| Churn spikes in metrics diff (many new rows) | Noise in PR reviews | Stage baseline upgrade after batch grouping. |
| Policy misconfiguration causes over-gating early | Developer friction | Start permissive (warn) for subcluster coverage; escalate later. |

## 18. Performance Considerations
- Hierarchy adds minor overhead (map assembly). Complexity remains O(V + E).
- Representatives unaffected (just more clusters in iteration). Guard with early exit if large scale emerges (not expected now).

## 19. Open Questions (Decide Before Implementation)
| Question | Options |
|----------|---------|
| Should parent have a representative? | No (preferred) / Derived via densest leaf / Weighted centroid. |
| Keep parent pages permanently? | Transitional only / Permanent aggregate hubs. |
| Policy gating on parent after leaf_only? | Drop / Keep informational only. |

## 20. Suggested Initial Subcluster Partitioning (Illustrative)
| Parent | Leaves (example) |
|--------|------------------|
| brisbane | brisbane-cbd, brisbane-west, brisbane-north, brisbane-south, brisbane-east |
| ipswich | ipswich-core, ipswich-rural (optional) |
| logan | logan-north, logan-south (optional) |

## 21. Minimal Implementation Order (Condensed)
1. Runtime: parse `parent`; expose `leafClusters()`.
2. Metrics: add `subclusters`, `subcluster_coverage` (empty if none present).
3. Doctor: validate & gate perSubcluster coverage (warn only initially).
4. Policy: add `subclusterMode`, `perSubcluster`.
5. Diff: add new rows; baseline refresh.
6. Reporter: add subcluster table.
7. Migration execution (move suburbs from parent to leaves).
8. Flip to `leaf_only` mode; enforce parent no `suburbs`.

## 22. Definition of Done (Phase 1 of Hierarchy)
- Metrics & doctor gracefully handle both hierarchical & legacy flat data.
- Policy supports subcluster gating (warn-level configurable).
- Diff stable with new fields recognized & baseline updated.
- Reporter surfaces subcluster sample & worst coverage.
- No duplication / total suburb count invariant holds.

---
Prepared for review. Feedback areas: parent representative policy, gating strictness staging, naming conventions, and redirect strategy.
