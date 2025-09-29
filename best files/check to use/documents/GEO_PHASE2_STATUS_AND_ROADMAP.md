## Geo Platform – Phase 2 Consolidated Status & Forward Roadmap

_Date: 2025-09-13_

This document captures: what we built in Geo Phase 2, current guarantees, remaining gaps, risk profile, and a phased roadmap (Phase 2 wrap → Phase 3 growth). It also includes a data/file relationship tree and recommendations (including npm script ergonomics) plus answers to implicit questions you have not asked yet.

---
## 1. Objectives Recap
**Phase 2 Goals (original)**
1. Policy-aware geo metrics & reporting (islands / component gating).
2. Diff + reporter integration (markdown & machine-readable indices).
3. Bridge candidates (structural improvement hints).
4. Strategy & runtime test expansion.
5. Quality gating (severity + coverage) before merging.

**Stretch / emerging goals**
6. Historical archiving + trends.
7. Data provenance & integrity.
8. Developer ergonomics (single command pipeline, PR summary).
9. Preparation for finer sub-cluster taxonomy (e.g. `brisbane-west`, `brisbane-cbd`).

---
## 2. Delivered (Completed Work)
| Capability | Delivered Artifacts / Scripts | Notes |
|------------|------------------------------|-------|
| Metrics generation | `scripts/geo/metrics.mjs` | Produces core geo-metrics report. |
| Doctor validation | `scripts/geo/doctor.mjs` | Adds component counting, symmetry, coverage, per-cluster coverage map. |
| Diff + policy integration | `scripts/geo/diff.mjs` + `geo.policy.json` | Severity overrides & allowed islands. |
| Markdown reporter | `scripts/geo/report-md.mjs` | Human friendly summary. |
| Bridge candidates | `scripts/geo/bridge.mjs` | Suggests edges to reduce fragmentation. |
| Overlay merge & index | `scripts/geo/overlay-merge.mjs`, `report-index.mjs` | Composition of metrics & diff artifacts. |
| Gate (severity + coverage) | `scripts/geo/gate.mjs` | Enforces worst severity, per-cluster coverage, strategy coverage threshold (90%). Hash verification integrated. |
| Strategy coverage | `scripts/geo/strategy-coverage.mjs` | Exports vs test reference scan → gating. |
| History archive | `scripts/geo/history-archive.mjs` | Snapshots to `__history/` + index for trending. |
| PR summary generation | `scripts/geo/pr-summary.mjs` | Markdown summary for reviewers. |
| Churn deltas | `scripts/geo/churn.mjs` | Last vs previous run (components & coverage deltas). |
| Data integrity (hash) | `scripts/geo/hash-verify.mjs` | Fails gate except when baseline updated via `GEO_UPDATE_HASHES=1`. |
| Sandbox normalization | `sandbox/geo/` + updated `OWNER_TODO.md` | Removed space-containing directory pattern. |
| Data provenance doc | `data/PROVENANCE.md` | Refresh procedure & source mapping. |
| Policy versioning | `geo.policy.json` with `policyVersion` | Allows future schema evolution. |
| CI workflow | `.github/workflows/geo-gate.yml` | Runs full suite (currently using `geo:full`; upgrade to `geo:ci` recommended). |

---
## 3. Current Guarantees
| Guarantee | Mechanism |
|-----------|-----------|
| No silent severity regressions (beyond allowed) | Gate compares worst severity to `maxAllowedSeverity`. |
| Island exceptions allowed & bounded | `allowed_islands` list in policy. |
| Max components enforced | `maxComponents` vs doctor `graph_components.count`. |
| Per-cluster coordinate coverage | `perCluster` thresholds enforced (failing clusters break gate). |
| Strategy export test coverage floor (90%) | Gate reads strategy coverage output. |
| Data tampering detection | Hash verification script (baseline required). |
| Historical reproducibility | `__history/<timestamp>` snapshots + `index.json`. |
| Reviewer clarity | PR summary (when run) + diff top metrics. |

---
## 4. Gaps / Open Items
| Gap | Impact | Proposed Action |
|-----|--------|-----------------|
| Hash baseline not yet committed | Hash verify fails on fresh CI | Generate baseline & commit `__meta/geo.hashes.json`. |
| Workflow uses `geo:full` not `geo:ci` | PR summary + churn + hash may not run | Replace with `npm run geo:ci`. |
| Churn not a gate | Regressions may slip if severity unchanged | Add optional churn thresholds (coverage delta < -0.5 or component +1). |
| Missing sub-cluster taxonomy | Granular tuning & localized coverage not available | Introduce hierarchical cluster schema (parent-child) & aggregator. |
| No dashboard UI | Manual inspection of reports | Build `/geo-dashboard` Astro route reading history index. |
| No test stub generation | New exports risk coverage slip | Generate stubs in `__ai/geo-missing-tests.md` for uncovered exports. |
| Lack of centrality metrics | Bridge list only edge suggestions | Implement approximate betweenness / degree ranking output. |
| Integrity hashes not diff-friendly by grouping | Single file makes merges noisy | Consider per-file `__meta/hashes/<file>.sha256` structure. |
| Policy drift detection | Changing policy fields may weaken guardrails silently | Add `policy.hash` in gate & fail if hash changes without `POLICY_BUMP=1`. |
| No formal churn score | Hard to weigh multiple changes | Composite metric (severity weight + coverage delta + components delta). |

---
## 5. Hidden / Implicit Risks & Mitigations
| Risk | Why It Matters | Mitigation |
|------|----------------|-----------|
| Over-fitting severity thresholds | Changes blocked for non-impactful metrics | Track historical distribution; calibrate thresholds quarterly. |
| Data file growth (performance) | Larger JSON slows metrics & doctor | Add timing benchmarks + warn if > X ms growth. |
| Duplicate logic between `src/lib` & sandbox | Divergence and confusion | Enforce import lint rule disallowing sandbox imports in production build. |
| Gate flakiness if metrics non-deterministic | CI noise | Snapshot inputs & seed random sources (none yet, but future centrality sampling). |
| Manual hash updates silently broad | Baseline update could hide drift | Make gate print list of changed hashes & require commit message token `geo-hash-update`. |

---
## 6. Roadmap (Proposed Phases)
### Phase 2 Wrap (Stabilization)
1. Commit hash baseline & switch workflow to `geo:ci`.
2. Add churn thresholds to gate (non-zero components increase outside allowed islands, coverage drop > 0.5%).
3. Add missing test stub generator (uncovered exports) & enforce zero uncovered.

### Phase 3 (Observability & Hierarchy)
4. Hierarchical clusters (`cluster_id`, `parent`, `level`) + aggregated coverage & severity roll-up.
5. Geo dashboard Astro page (history trend charts, component map snapshot).
6. Centrality metrics (approx betweenness, top structural hubs) + gating heuristics for newly isolated nodes.
7. Churn score & regression anomaly detection (statistical baseline, e.g. z-score > 2). 

### Phase 4 (Optimization & Governance)
8. Edge quality classifier (categorize edges by geographic distance / cluster relation).
9. Policy hash + commit message guard (policy bump required for relaxing constraints).
10. Integrity per-file hashing & optional signed provenance (GPG / Sigstore). 
11. Performance budget integration (fail if `metrics runtime ms` > threshold).

### Phase 5 (Visualization & Advanced Analytics)
12. Graph snapshot export (DOT → PNG) per archive run.
13. Interactive dependency explorer (lazy load adjacency segments).
14. Predictive bridge simulation (simulate merging top N candidates & show predicted component reduction/coverage delta).

---
## 7. Unasked Questions (Answered Proactively)
**Q: How do we safely evolve the policy schema?**  
Add `policyVersion`; gate fails if unknown; add migration script that logs deprecated fields.

**Q: When do we re-baseline hashes?**  
Only after intentional data ingestion (raw source update). Require `GEO_UPDATE_HASHES=1` + commit message token.

**Q: How to add sub-clusters without thrash?**  
Introduce `areas.clusters.json` hierarchical extension: each cluster has optional `children: []`; adapt doctor to compute coverage recursively; maintain backward-compatible flattened list while migrating.

**Q: Can we accelerate the pipeline?**  
Yes: cache adjacency & enriched cluster pre-processing (serialize intermediate `__cache/geo-runtime.json`). In CI, restore via actions/cache keyed by hash of data files.

**Q: Are we over-reporting?**  
We can reduce diff rows by severity slicing (output only changed metrics or anything at `warn+`).

**Q: How to ensure each new export has a narrative test?**  
Stub generator populates `__ai/geo-missing-tests.md`; gate fails if file non-empty.

---
## 8. Current File / Data Relationship Tree
```
geo.policy.json                  # Governing thresholds & overrides
scripts/geo/
  metrics.mjs                    # Collect metrics (raw graph + coverage)
  doctor.mjs                     # Validations (symmetry, components, per-cluster coverage)
  diff.mjs                       # Compare current vs baseline metrics
  report-md.mjs                  # Generate human markdown
  bridge.mjs                     # Bridge candidate edge recommendations
  overlay-merge.mjs              # Merge layered metric sources
  report-index.mjs               # Build index JSON for cross-report queries
  gate.mjs                       # Enforce severity + coverage + strategy + hashes
  strategy-coverage.mjs          # Export usage vs tests
  history-archive.mjs            # Persist run artifacts
  pr-summary.mjs                 # Generate PR markdown summary
  churn.mjs                      # Last vs previous history delta
  hash-verify.mjs                # SHA256 baseline verify / update
  summary.mjs (legacy branch?)   # (If restored) legacy aggregator

src/lib/geoCompat.runtime.js     # Runtime priming & enriched cluster access
src/lib/geoCompat.ts             # Types / runtime surface (TS)
src/lib/routes.ts                # Geo route construction helpers
src/lib/services.ts              # Service-level geo binding
src/lib/suburbs.ts               # Core suburb utilities
src/lib/urls.ts                  # URL assembly helpers
src/lib/validators/geo.ts        # Validation functions (schema-ish)
src/lib/links/*                  # Link derivation strategies
src/lib/suburbs/resolveDisplay.ts# Display name logic

src/data/
  adjacency.json                 # Canonical symmetric adjacency
  areas.adj.json                 # Area adjacency or cluster overlay (editorial)
  areas.clusters.json            # Cluster definitions (flat for now)
  cluster_map.json               # Derived cluster→suburb mapping
  proximity.json                 # Distance-based relationships / metrics output
  suburbs_enriched.geojson       # Enriched suburb dataset (coords, metadata)
  geo.config.json                # Config hooks (if present)
  PROVENANCE.md                  # Source / refresh documentation

sandbox/geo/raw/                 # Raw ingestion sources prior to promotion

__reports/                       # Latest run artifacts (gate, metrics, diff, strategy coverage, etc.)
__history/                       # Archived snapshots (timestamped)
__meta/geo-metrics.baseline.json # Baseline metrics (diff reference)
__meta/geo.hashes.json           # (Pending) canonical file hash baseline

tests/unit/                      # Strategy, policy & runtime tests
tests/invariants/                # CSS pipeline & service coverage invariants
tests/routing/                   # URL & legacy routing tests
```

---
## 9. Recommended npm Script Additions / Adjustments
| Script | Purpose | Rationale |
|--------|---------|-----------|
| `geo:baseline` | Recompute metrics + diff + update hashes intentionally | One-stop safe baseline refresh (requires flag). |
| `geo:fast` | Run metrics+doctor only | Faster local iteration. |
| `geo:focus -- --clusters=a,b` | Partial cluster run (wrap metrics/doctor) | Speeds cluster-specific dev. |
| `geo:stubs` | Generate missing test stubs | Enforce high signal test maintenance. |
| `geo:dashboard` | Build static dashboard page (future) | Visual artifact generation. |
| `ci:geo` (alias for current `geo:ci`) | Consistent naming with other ci:* scripts | Convention alignment. |

Example `geo:baseline` implementation concept:
```jsonc
"geo:baseline": "GEO_UPDATE_HASHES=1 npm run geo:full && npm run geo:hash"
```

---
## 10. Immediate Action Checklist (Recommended Now)
- [ ] Commit hash baseline (`GEO_UPDATE_HASHES=1 npm run geo:hash`).
- [ ] Switch workflow step to `npm run geo:ci`.
- [ ] Add churn regression gate (coverage drop / component increase thresholds) inside `gate.mjs`.
- [ ] Implement missing test stub generator & fail if stubs produced.
- [ ] Plan hierarchical cluster schema (draft JSON example + migration script).

---
## 11. Overall Assessment
The geo quality platform has reached **guardrail maturity**: policy-centric gating, per-cluster coverage, strategy coverage enforcement, and integrity checks provide strong regression protection. The next marginal gains shift from “prevent bad” to “accelerate insight & evolution” (hierarchy, trends, predictive bridging). Remaining technical debt is low/contained (hash baseline & workflow alignment). Performance and complexity are reasonable; risk now concentrates in policy evolution and data ingestion governance—both solvable with hash / policy version hashing.

**In short:** A solid foundation is in place. Focus next on hierarchical modeling & visualization to unlock stakeholder clarity and faster structural iteration.

---
## 12. Suggested Next PR Titles
- `geo: enable hierarchical clusters + coverage roll-ups`
- `geo: add churn thresholds & missing test stub gate`
- `geo: add integrity baseline + policy hash enforcement`
- `geo: introduce dashboard route for trends`

---
## 13. Questions You Might Soon Ask (Pre-Answers)
| Question | Answer |
|----------|--------|
| “How do we revert a bad data ingestion?” | Use git diff + restore prior `src/data/*`; hashes will fail until baseline updated intentionally. |
| “Can we snapshot only deltas to history?” | Yes: store only metrics diff + gate summary; regenerate full metrics on demand using baseline + deltas (optional optimization later). |
| “How do we version clusters?” | Add `clusters.version` field + commit message token `geo-clusters:` to modify. |
| “When do we run centrality (expensive)?” | On scheduled nightly run + manual trigger flag `GEO_CENTRALITY=1`. |

---
## 14. Appendix – Example Hierarchical Cluster Schema Draft
```jsonc
[
  {
    "slug": "brisbane",
    "level": 0,
    "children": [
      { "slug": "brisbane-cbd", "level": 1, "suburbs": ["brisbane-city", "spring-hill"] },
      { "slug": "brisbane-west", "level": 1, "suburbs": ["st-lucia", "toowong"] }
    ]
  }
]
```
Doctor extension: compute coverage at leaf & roll upward (aggregate). Gate: require parent coverage = weighted leaf coverage.

---
---
## 15. Executive Summary (Expanded)
Phase 2 established a *governed geo graph platform* with: deterministic metrics, policy-bound gating, integrity verification, historical archiving, and strategy (test) coverage enforcement. Residual risk now concentrates in (a) hierarchical evolution (sub‑clusters), (b) governance drift (policy or data baselines updated without intent), and (c) visibility (human, visual, and predictive insights). We can confidently declare Phase 2 feature-complete once hash baseline + churn thresholds + workflow upgrade land. Phase 3 should emphasize structural refinement (hierarchy), richer analytics (centrality & churn scoring), and visualization (dashboard + predictive bridges) while keeping the guardrails uncompromised.

---
## 16. Glossary
| Term | Definition |
|------|------------|
| Component | Connected set of suburbs (undirected projection) in adjacency graph. |
| Island | A component permitted by policy beyond the primary component. |
| Coverage (coords) | % of suburbs with valid lat/lng coordinates. |
| Per-cluster coverage | Coverage computed within each editorial cluster. |
| Severity | Classification (info/warn/error) assigned to metric diff based on policy thresholds. |
| Strategy Coverage | % of exported geo/runtime functions referenced in unit tests. |
| Gate | Composite quality check enforcing policy + integrity + test coverage. |
| Baseline (metrics) | Canonical previous metrics snapshot used for diff comparisons. |
| Hash Baseline | SHA256 fingerprint file proving canonical data integrity. |
| Churn | Change delta across historical runs (components, coverage, etc.). |
| Bridge Candidate | Suggested edge that would reduce fragmentation (join components or shorten path lengths). |
| Hierarchical Cluster | Parent/child cluster taxonomy enabling roll‑up metrics. |

---
## 17. Architecture & Data Flow (Conceptual)
```
Raw Geo Data (suburbs_enriched.geojson, adjacency.json, clusters) 
  ↓ (prime runtime)
geoCompat.runtime → enrichedClusters(), adjacency()
  ↓
metrics.mjs → geo-metrics.json (structural + coverage metrics)
  ↓
doctor.mjs   → geo-doctor.json (validation report + coverage_by_cluster, components)
  ↓
diff.mjs     → geo-metrics.diff.json (baseline vs current with severities)
  ↓
strategy-coverage.mjs → geo-strategy-coverage.json
  ↓
gate.mjs (reads: policy, diff, doctor, strategy, hash-verify)
  ↓ pass/fail + geo-gate.json
  ↓
history-archive.mjs (snapshot + index update)
  ↓
pr-summary.mjs / churn.mjs → reviewer artifacts / regression signals
```

---
## 18. Metrics Inventory & Severity Mapping
| Metric Key | Description | Source | Default Severity Rule | Notes |
|------------|-------------|--------|-----------------------|-------|
| graph_components.count | Total connected components | doctor | error if > maxComponents & not allowed island pattern | Allowed islands enumerated. |
| coords_coverage_pct | Global coordinate coverage % | doctor | warn < 99, error < policy min | Policy uses perCluster for precision. |
| coverage_by_cluster[slug] | Coverage per cluster | doctor | error if < perCluster.minCoordsPct | Skip if cluster threshold absent. |
| asymmetry_edges | Count of directed edges lacking reciprocal | doctor | warn >0, error > threshold (if symmetry required) | Autofix optional. |
| cross_cluster_edges | Edges crossing cluster boundary | doctor | info baseline; escalate if ratio > planned threshold (future) | Ratio metric TBD. |
| degree.mean (if present) | Average degree across nodes | metrics | info baseline; warn on large negative delta | Tuned after baseline distribution captured. |
| bridge_candidates.count | Suggested bridging edges | bridge | info; potential warn if persistent > X over N runs | For improvement tracking. |
| strategy_coverage.pct | Export test reference coverage | gate | error if < minStrategyCoveragePct | Floor currently 90%. |
| hash.mismatch.count | Count of data files failing integrity | hash-verify | error if >0 | Blocks merge. |
| churn.coverage_delta | Coverage change vs prior run | churn | warn < -0.5, error < -1.0 (proposal) | To implement gating soon. |
| churn.components_delta | Component count delta | churn | error if >0 unless all new are allowed islands | Mitigates silent fragmentation. |

---
## 19. Gate Algorithm (Pseudo-Code)
```
load policy
run (or assume pre-run) metrics, doctor, diff, strategy-coverage
worstSeverity = max(diff.rows[].severity)
fail if worstSeverity > policy.maxAllowedSeverity
for each cluster threshold: fail if coverage_by_cluster[cluster] < threshold
compute strategyPct; fail if strategyPct < policy.minStrategyCoveragePct
run hash-verify (unless GEO_SKIP_HASH=1 or updating baseline)
optionally load churn: fail if coverage drop or components delta breaches thresholds
write geo-gate.json summary with all checks + strategy + hash result + churn snapshot
exit with aggregated pass/fail
```

---
## 20. Policy Schema Specification (Draft Evolution)
```jsonc
{
  "policyVersion": 1,
  "maxComponents": 1,
  "allowed_islands": ["bulwer", ...],
  "severityOverrides": { /* metric -> severity */ },
  "perCluster": { "ipswich": { "minCoordsPct": 0.98 } },
  "maxAllowedSeverity": "error",
  "minStrategyCoveragePct": 90,
  "churn": { "maxCoverageDropPct": 0.5, "allowNewComponents": false },
  "hash": { "requireBaseline": true },
  "hierarchy": { "enabled": false, "rollupFormula": "weighted" }
}
```
Future fields: `policyHash`, `hierarchy.minParentCoverage`, `centrality.maxIsolatedBetweenness`.

---
## 21. Baseline & Hash Lifecycle
| Event | Action | Command | Gate Behavior |
|-------|--------|---------|---------------|
| Intentional data ingestion | Update data & metrics | `npm run geo:full` | Fails until baseline updated if hashes differ. |
| Approve new canonical state | Refresh hash baseline | `GEO_UPDATE_HASHES=1 npm run geo:hash` | Gate passes next runs. |
| Policy relaxation | Bump policyVersion + commit msg token | edit policy + `git commit -m "geo: policy bump: reason"` | Gate enforces version recognition. |
| Baseline metric re-seeding | (Optional) store new `geo-metrics.baseline.json` | custom script (future) | Diff resets. |

Safeguard additions (future): require commit message token `geo-hash-update` when hash baseline changes.

---
## 22. CI Pipeline (Expanded)
1. Checkout + install.
2. `npm run geo:ci` (orchestrates metrics → doctor → diff → strategy coverage → gate → history archive).
3. `npm run geo:pr:summary` (if not included already) posts PR comment.
4. (Planned) `npm run geo:churn` gating thresholds.
5. (Planned) Upload artifacts & (optionally) attach summary badge.
6. Nightly schedule runs centrality (future flag `GEO_CENTRALITY=1`).

Caching opportunity: restore `__cache/geo-runtime.json` keyed by hash of data files; skip expensive priming.

---
## 23. Testing Strategy & Coverage Matrix
| Layer | Goal | Test Types | Current Gaps |
|-------|------|-----------|--------------|
| Runtime geo utilities | Correct enrichment & path logic | unit | Add negative edge cases & malformed suburb slugs. |
| Policy gating | Block regressions | unit + integration (gate exit code) | Add churn & hash mismatch scenarios. |
| Strategy coverage | Keep exports tested | meta (strategy-coverage script) | Stub generator not yet present. |
| Data integrity | Detect tampering | integration (hash-verify) | Baseline file missing until created. |
| Historical archiving | Stable index updates | integration | Add test ensuring chronological order & no duplication. |
| Bridge candidates | Suggest valid edges | unit (sample graphs) | Validate no duplicate reciprocal edges. |

Proposed new test file examples:
- `tests/unit/geoChurnGate.spec.ts`
- `tests/unit/geoHashBaseline.spec.ts`
- `tests/unit/geoHierarchyRollup.spec.ts` (Phase 3).

---
## 24. Technical Debt Register (Expanded)
| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| Hash baseline missing | High | Low | Blocks CI integrity guarantee. |
| Workflow not using geo:ci | High | Low | Limits visibility. |
| No sub-cluster schema | High | Medium | Unlocks finer coverage gating. |
| No churn gating | Medium | Low | Silent regressions possible. |
| Missing test stubs generator | Medium | Low | Coverage decay risk. |
| No centrality metrics | Medium | Medium | Harder to target structural improvements. |
| Policy hash guard absent | Medium | Low | Drift risk. |
| Performance budget absent | Low | Low | Add timing capture per run. |

---
## 25. Phase Transition Criteria
| Phase 2 Completion Requires | Status |
|-----------------------------|--------|
| Hash baseline committed | Pending |
| CI uses `geo:ci` | Pending |
| Churn thresholds added | Pending |
| Strategy coverage passes @ ≥90% | Active |
| Gate stable across 3 consecutive runs | Pending |

---
## 26. Hierarchical Sub-Cluster Implementation Plan
| Step | Action | Output |
|------|--------|--------|
| 1 | Draft hierarchical schema (`areas.hierarchical.clusters.json`) | New schema file |
| 2 | Migration script flatten → hierarchical & back | `scripts/geo/cluster-migrate.mjs` |
| 3 | Doctor roll-up coverage (weighted by suburb count) | `cluster_rollup_coverage` field |
| 4 | Policy adds `hierarchy.enabled` & optional parent thresholds | Updated policy |
| 5 | Gate evaluates parent coverage post-leaf | Extended gate summary |
| 6 | Dashboard visualizes hierarchy tree | `/geo-dashboard` page |

Edge Case Handling: orphan cluster nodes, empty children arrays, duplicate suburb assignment (fail doctor).

---
## 27. Centrality & Bridge Analytics Plan
| Metric | Approach | Notes |
|--------|----------|-------|
| Degree Centrality | Already trivially derivable (degree counts) | Persist top K to report index. |
| Approx Betweenness | Random node sampling + BFS | Run nightly; cache results. |
| Articulation Points | Tarjan algorithm on undirected graph | Flag critical connectors (potential gating). |
| Bridge Impact Simulation | For each candidate edge, union-find component shrink estimate | Quick pre-add effect. |

---
## 28. Churn & Composite Score Blueprint
Churn deltas currently: components, coverage. Composite formula (proposal):
```
churn_score = (w_components * clamp(components_delta,0,3))
        + (w_coverage * abs(min(coverage_delta,0)))
        + (w_severity * severityDeltaIndex)
weights suggestion: components=4, coverage=2, severity=3.
```
Severity delta index = difference in ordinal (info=0,warn=1,error=2) worst severity vs previous.

Gate usage: warn if churn_score ≥ 4; error if ≥ 6.

---
## 29. Performance Baseline & Budgets
Capture `metrics_ms`, `doctor_ms`, `gate_ms` (already have doctor timings). Add timings to gate summary. Initial budgets (tunable):
| Stage | Target ms | Warn | Error |
|-------|-----------|------|-------|
| metrics | < 500 | > 800 | > 1200 |
| doctor  | < 400 | > 700 | > 1000 |
| gate    | < 200 | > 400 | > 600 |

Trend watch: escalate if P95 over 7 historical runs breaches warn boundary.

---
## 30. Ownership & RACI (Light)
| Area | Responsible | Consulted | Informed |
|------|-------------|-----------|----------|
| Policy (`geo.policy.json`) | Geo Maintainer | Dev Leads | Reviewers |
| Data ingestion (`src/data/*`) | Data Curator | Geo Maintainer | All |
| Gate scripts | Geo Maintainer | QA | All |
| Hash baseline | Geo Maintainer | Security | All |
| Hierarchy design | Geo Maintainer | Editorial | All |

---
## 31. Migration / Rollback Procedures
| Scenario | Procedure |
|----------|-----------|
| Bad data commit | Revert commit, rerun `geo:full`; ensure hash mismatch fails until baseline restored. |
| Policy overly strict | Bump `policyVersion`, adjust thresholds, include reasoning in commit. |
| Hash baseline accidentally updated | Revert `__meta/geo.hashes.json` and re-run gate. |
| Hierarchy misconfiguration | Disable `hierarchy.enabled`, rerun gate, fix schema offline. |

---
## 32. Future KPIs
| KPI | Definition | Target |
|-----|------------|--------|
| Single Component Ratio | largest_component_size / total_nodes | ≥ 0.97 (excluding allowed islands) |
| Strategy Coverage % | Tested export ratio | ≥ 95% Phase 3 end |
| Mean Time to Bridge (MTTB) | Time from detection of fragmentation to accepted bridge PR | < 2 days |
| Gate Flake Rate | % of CI runs failing non-deterministically | 0% |
| Data Integrity Incidents | Hash mismatches w/out intent | 0 |

---
## 33. Decision Log (Key Past Decisions)
| Decision | Rationale | Date |
|----------|-----------|------|
| Clean branch instead of history rewrite | Faster recovery & audit clarity | 2025-09-10 |
| Introduce strategy coverage gating | Prevent silent test entropy | 2025-09-12 |
| Add hash verification | Detect tampering / drift | 2025-09-13 |
| Use per-cluster coverage thresholds | Precision gating vs blunt global | 2025-09-13 |
| Plan hierarchical clusters (Phase 3) | Needed for finer geography semantics | 2025-09-13 |

---
## 34. Stub Generator Specification (Upcoming)
Script: `scripts/geo/generate-missing-test-stubs.mjs`
Steps:
1. Read `geo-strategy-coverage.json` → uncovered exports.
2. For each uncovered export `foo`, append to `__ai/geo-missing-tests.md`:
```ts
// Stub test for export: foo
import { foo } from '../../src/lib/...';
describe('foo()', () => {
  it('TODO: add behavior spec', () => {
   expect(foo).toBeDefined();
  });
});
```
3. Gate fails if file non-empty & older than N hours (prevent indefinite TODOs).

---
## 35. Questions & Answers (Additional)
| Question | Answer |
|----------|--------|
| What if a cluster splits unexpectedly? | Gate triggers components delta error; run bridge suggestions to evaluate fix. |
| Can we auto-add bridges? | Future optional autofix mode generating PR with added edges (guarded by review). |
| How to visualize component map quickly? | Export DOT + run `dot -Tpng` in CI & attach artifact. |
| How to sandbox centrality cost? | Run partial sampling (k random sources) and compare stability before enabling gating. |
| Handling extremely large data additions? | Add pre-ingest size check & memory/time budget enforcement. |

---
## 36. Outlook & Recommendation
The system is structurally prepared for hierarchical complexity and advanced analytics. Immediate focus should be *operational hardening* (hash baseline + churn gating) to finalize Phase 2 closure. Thereafter, hierarchy + dashboard deliver the largest clarity lift. Analytical deepening (centrality, churn composites) should proceed only after at least 5–7 archived runs establish baseline distributions.

Strategic Recommendation Order:
1. Lock Operational Integrity (baseline, churn thresholds, policy hash guard)
2. Hierarchy & Roll-Up Coverage
3. Dashboard + Visual Graph Snapshot
4. Centrality & Composite Churn Score
5. Predictive Bridge Simulation & Edge Classification

---
_End of document (expanded)._ 
