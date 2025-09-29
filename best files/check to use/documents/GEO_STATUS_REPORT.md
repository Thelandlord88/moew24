# Geo Platform Status Report (Phase 2 Clean)

Generated: 2025-09-14
Branch: `feature/geo-phase2-clean`

---
## 1. Executive Summary
The geo subsystem now produces a deterministic, policy-aware undirected adjacency graph derived from suburb centroids and cluster groupings. Core hygiene (symmetry, sorting, coverage) is solid; strategic quality targets (eliminating isolates, collapsing small components) remain outstanding. The system is ready for tightening parameters and CI gating of structural + policy metrics.

---
## 2. Current Artifacts
| Artifact | Path | Notes |
|----------|------|-------|
| Config | `config/adj.config.json` | Tunable params + policy thresholds |
| Builder Script | `scripts/geo/build-adjacency.mjs` | Deterministic generation + history |
| Validator Script | `scripts/geo/validate-adjacency.mjs` | Structural + partial policy enforcement |
| Adjacency Output | `src/data/adjacency.json` | 345 nodes (includes outer / auxiliary) |
| Build Report | `__reports/adjacency.build.json` | Metrics snapshot (schema v1) |
| Metrics Report | `__reports/geo-metrics.json` | Aggregated geo KPIs (schema v2) |
| History Log | `__history/adjacency-history.json` | Rolling append (max 500 entries) |
| Schemas | `schemas/adj.config.schema.json`, `schemas/adjacency.build.schema.json` | JSON Schema for config/report |

---
## 3. Configuration Snapshot
```
params: {
  K_BASE: 6,
  MAX_KM: 11,
  MAX_KM_EXT: 14,
  MIN_DEGREE: 3,
  PCT_PRUNE: 95,
  MAX_CROSS_CLUSTER_PER_NODE: 2,
  LOCALIZE: false
}
policy: {
  degrees: { meanMin: 4, meanMax: 8, minFloor: 2 },
  components: { max: 5, largestRatioMin: 0.85 },
  crossCluster: { maxRatioWarn: 0.08, maxRatioError: 0.12 }
}
```

---
## 4. Structural Metrics (Adjacency Build Report)
```
Nodes (adjacency): 345
Undirected Edges: 773
Degree Mean: 4.48
Degree Min / Max: 0 / 6
Isolates (deg 0): 4
Low Degree (1–2): 29
Components: 8
Largest Component Ratio: 0.968
Cross-Cluster Edges: 23 (ratio 0.0298)
Global Distance Cutoff (PCT_PRUNE=95): 5.813 km
```
Histogram (degree -> count):
```
0:4 1:14 2:15 3:46 4:68 5:96 6:102
```

---
## 5. Validator Output (Latest Run)
```
{
  self_loops: 0,
  asym_pairs: 0,
  unsorted_keys: 0,
  degrees: { mean: 4.48, min: 0 },
  components: { count: 8, largest_ratio: 0.968 },
  policy: { minDegree: 'fail', components: 'fail' }
}
```
Interpretation:
- Structural integrity passes (symmetry, ordering)
- Policy failures: minimum degree floor and component count

---
## 6. Connectivity Decomposition
Current component fragmentation (summarized):
- Total components: 8
- Largest size: 334 (≈96.8% of nodes)
- Remaining 7 components are small (size 1–4); 4 of them are isolates (degree 0).

_Isolate slugs:_ (degree 0 nodes) embedded inside adjacency (extracted programmatically at report time; list should be refreshed after tuning).

---
## 7. Quality Diagnostics
| Category | Status | Rationale | Action Path |
|----------|--------|-----------|-------------|
| Symmetry & Sorting | ✅ | Zero asym/self/unsorted | Maintain tests & validator gate |
| Coverage (coords → adjacency) | ✅ | coverage_gap=0 | Guard against regressions in validator |
| Degree Distribution | ⚠ | Tail heavy: 0–3 degree = 79 nodes | Increase K_BASE / relax prune |
| Fragmentation | ⚠ | 8 components (policy max=5) | Add edges via K_BASE↑ & MAX_KM_EXT↑ |
| Leakage | ✅ | Cross-cluster ratio 0.0298 well below warn | Monitor after densification |
| Determinism | ✅ | Stable stringify + sorted keys | Lock config for reproducibility |
| History Tracking | 🟡 | Starts now; low sample size | Commit after each param change |
| Validator Coverage | 🟡 | Lacks cross-cluster ratio check | Enhance validator to load clusters |

---
## 8. Root Causes of Weaknesses
| Issue | Likely Cause | Supporting Signal |
|-------|--------------|-------------------|
| Isolates & micro-components | Strict PCT_PRUNE + modest K_BASE | Cutoff km 5.813; mean just above floor |
| Degree ceiling (6) | K_BASE=6 seeds; MAX_KM modest | Max degree = K_BASE due to mutual constraint |
| Fragmentation persists | Sparse fringe nodes beyond MAX_KM radius | Extended rescue (MAX_KM_EXT=14) insufficient for outliers |

---
## 9. Recommended Parameter Tuning (Next Iteration)
| Param | Current | Proposed | Effect |
|-------|---------|----------|--------|
| K_BASE | 6 | 7 (maybe 8 trial) | Raises mean degree; reduces isolates |
| PCT_PRUNE | 95 | 97 | Retain mid-range edges collapsing small comps |
| MAX_KM_EXT | 14 | 16 | Rescue for sparse outskirts |
| MIN_DEGREE | 3 | Keep (then maybe 4 post-heal) | Avoid premature long edges |
| LOCALIZE | false | Keep false | No current density imbalance |

Dry-run experimentation examples:
```
node scripts/geo/build-adjacency.mjs --k 7 --pctPrune 97 --maxKmExt 16 --dry-run
node scripts/geo/build-adjacency.mjs --k 8 --pctPrune 97 --maxKmExt 16 --dry-run
```
Success criteria after tuning:
- Components ≤ 2 (ideally 1)
- Isolates = 0
- Mean degree 5.0–6.5
- Cross-cluster ratio < 0.06 (headroom under 0.08 warning)

---
## 10. Planned Enhancements
1. Validator: incorporate cluster map to enforce `crossCluster.maxRatio*` thresholds.
2. Gate Script: parse `__reports/adjacency.build.json` & exit non-zero on policy breaches.
3. History Analysis: add trend deltas (mean degree drift, component count delta) to PR summary.
4. Optional: Introduce `LOCALIZE:true` mode only if future densification causes high-degree interior bias.
5. Representative Selection: use (degree desc, then centroid proximity) once degree distribution stabilized.

---
## 11. CI & Governance Hooks (Next Steps)
| Hook | Purpose | Implementation Sketch |
|------|---------|-----------------------|
| `geo:adj:validate` in PR | Structural regression guard | Already present; extend for leakage |
| `geo:gate` | Enforce policy numerics | Add thresholds parse + exit code |
| `geo:history` | Drift detection | Compare last 2 entries: alert if deviation > tolerance |
| PR Summary Bot | Surface key metrics | Leverage existing `geo:pr:summary.mjs` with adjacency injection |

---
## 12. Risk Register
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Over-tuning increases leakage | Low | Medium | Cap `MAX_CROSS_CLUSTER_PER_NODE` (2) + enforce ratio in validator |
| Future data ingestion adds new isolates | Medium | Low | Auto-rescue pass or scheduled param review |
| Untracked param change causes noisy diffs | Medium | Medium | Require PR review of `adj.config.json` + hash in history |
| Hidden cluster drift | Low | Medium | Hash recorded (SHA256) for coords/areas/LGAs |

---
## 13. Operational Playbook (Condensed)
| Symptom | Adjustment Order |
|---------|------------------|
| Too many components | K_BASE↑ → PCT_PRUNE↑ → MAX_KM_EXT↑ |
| Leakage rises | MAX_CROSS↓ → PCT_PRUNE↓ → consider LOCALIZE |
| Over-saturated degrees | PCT_PRUNE↓ → K_BASE↓ |
| Isolates persist | MAX_KM_EXT↑ → K_BASE↑ |

---
## 14. Open Questions & Provisional Answers
| Question | Answer / Plan |
|----------|---------------|
| Should we persist a baseline adjacency hash? | Yes; store first “passing” build’s SHA in history & gate new deviation classes |
| Do we need cluster-level degree targets? | Not yet; variance appears narrow (no interior overheating) |
| How to expose metrics to UI dashboards? | Reuse `geo-metrics.json` + enrich with component/isolate changes |
| When to raise MIN_DEGREE to 4? | Only after isolates=0 and components≤2 to avoid forced long edges |
| Add edge weighting later? | Possible: store km distance for path algorithms (would require schema revision) |

---
## 15. Immediate Action Proposal
Execute tuning iteration Set A:
```
node scripts/geo/build-adjacency.mjs --k 7 --pctPrune 97 --maxKmExt 16 --dry-run
node scripts/geo/build-adjacency.mjs --k 8 --pctPrune 97 --maxKmExt 16 --dry-run
```
Choose config producing: isolates=0, components ≤2, mean degree ≤6.5, leakage <0.06. Commit updated `adj.config.json`, rebuilt adjacency, updated report & history.
Then: extend validator for cross-cluster ratio and wire into `geo:gate`.

---
## 16. Summary
The adjacency system foundation is stable, deterministic, and auditable. Primary next step: densify connectivity safely to eliminate isolates & collapse residual micro-components while maintaining low cross-cluster leakage. Governance primitives (config schema, report, history, validator) are in place to support iterative tuning and CI enforcement.

---
*Prepared automatically for team review.*
