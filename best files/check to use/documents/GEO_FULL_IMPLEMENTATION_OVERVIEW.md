# Geo Analytics Stack – Full Implementation & Evolution Overview

> Status: Phase 1 Hardening COMPLETE (Metrics + Doctor + Diff + Index + Per-Cluster Coverage + Smallest Components + Infinity Stringification). This document is the comprehensive companion to `GEO_OPERATORS_GUIDE.md` and is intended for maintainers, reviewers, auditors, and future engineers.

---

## 0. Executive Summary

The geo analytics toolchain ingests cluster + adjacency data, normalizes & validates it, computes rich structural metrics, enforces data quality gates, detects regressions, and surfaces actionable repair artifacts (symmetry autofix, bridge candidates). All outputs live in deterministic JSON under `__reports/` (machine focus) and `__ai/` (human / exploratory utilities). Tests assert a stable contract.

Key capabilities delivered:

| Capability | Delivered | Notes |
|------------|-----------|-------|
| Cluster + suburb ingestion | ✅ | Via `primeGeoCompat()` runtime harness. |
| Symmetry detection + optional autofix suggestion | ✅ | Writes `geo-adjacency.symmetric.json` under `__reports/`. |
| Metrics snapshot (degree stats, reps, components, cohesion, bridges) | ✅ | `geo-metrics.json` enriched after runtime prime. |
| Doctor gating (symmetry, components, coverage, cross-cluster edges) | ✅ | Exit code enforcement ready for CI. |
| Per-cluster coordinate coverage | ✅ | Included in both metrics meta & doctor report. |
| Connected component analysis + smallest components list | ✅ | Detects fragmentation; lists islands for triage. |
| Representative suburb strategies (adjacency degree / alphabetical / centroid) | ✅ | Persisted, deterministic tie-breaks. |
| Diff with severities + representative churn detection | ✅ | `geo-metrics.diff.json` with `rows[]` and `representative_changes[]`. |
| Aggregated index (single-pane) | ✅ | `geo-report.index.json`. |
| Baseline management | ✅ | Updated with new fields to eliminate NaN deltas. |
| Infinity threshold clarity | ✅ | Serialized as string (`"Infinity"`). |
| Tests (doctor pass, baseline, diff structure) | ✅ | Extendable; red-team tests pending optional next phase. |

Open decision (documented but optional to enforce): treat 4‑node Moreton Island component as intentional OR bridge it to enforce single-component invariant.

---

## 1. File Inventory & Responsibilities

### 1.1 Core Runtime & Scripts (under `scripts/geo/`)

| File | Purpose | Key Outputs / Side Effects |
|------|---------|----------------------------|
| `scripts/geo/metrics.mjs` | Computes base + extended metrics (degree distribution, cohesion, bridges, components, representatives, per-cluster coverage). | `__reports/geo-metrics.json` (primary snapshot) – enriched in-place then rewritten. |
| `scripts/geo/doctor.mjs` | Validates graph & data against thresholds (symmetry, coords coverage, components, cross-cluster edges) + optional symmetry autofix emission. | `__reports/geo-doctor.json`, optional `__reports/geo-adjacency.symmetric.json` (proposal). Exit code non‑zero on failure. |
| `scripts/geo/diff.mjs` | Compares current metrics vs baseline or branch; classifies severities; detects representative churn. | `__reports/geo-metrics.diff.json` + console tables. |
| `scripts/geo/report-index.mjs` | Aggregates metrics + doctor + baseline into a single index for bots/dashboards. | `__reports/geo-report.index.json`. |
| *(Planned)* `scripts/geo/report-md.mjs` | Markdown PR reporter (badges, tables, churn). | `__ai/geo-report.md` (future addition). |
| *(Planned)* `scripts/geo/bridge.mjs` | Bridge candidate generator (connect smallest component to main). | `__ai/geo-bridge-candidates.json`, optional overlay adjacency (future addition). |

### 1.2 Data & Supporting Sources

| File | Role |
|------|------|
| `src/data/areas.clusters.json` | Canonical cluster definitions + suburb coordinates. |
| `src/data/areas.adj.json` | Core adjacency (directed lists); cleaned & normalized by runtime. |
| `src/data/proximity.json` (optional) | Persisted nearby recommendations (future drift comparison). |
| `src/data/geo.config.json` | Existing geo scoring config (distinct from future analytics severity config). |
| `src/lib/geoCompat.runtime.js` | Runtime adapter exposing `primeGeoCompat`, `enrichedClusters`, `adjacency` (abstraction boundary for scripts). |

### 1.3 Reports & Artifacts (Outputs)

| Path | Description |
|------|-------------|
| `__reports/geo-metrics.json` | Core metrics snapshot (counts, structure, analytics, reps). |
| `__reports/geo-doctor.json` | Validation result (report + thresholds + autofix info). |
| `__reports/geo-adjacency.symmetric.json` | Proposed symmetric adjacency (only when autofix enabled & needed). |
| `__reports/geo-metrics.diff.json` | Field deltas vs baseline/branch with severities + rep churn. |
| `__reports/geo-report.index.json` | Aggregated index composed of metrics + doctor + baseline. |
| `__meta/geo-metrics.baseline.json` | Authoritative baseline for diff comparisons. |
| `__ai/` (directory) | Human-friendly or experimental outputs (future: markdown report, bridge candidates, overlays). |

### 1.4 Tests (Illustrative)

| File | Focus |
|------|-------|
| `tests/unit/geoDoctor.spec.ts` | Doctor pass path; thresholds presence; smallest components conditional. |
| `tests/unit/geoDiff.spec.ts` | Diff rows structure + severity field + representative changes array. |
| `tests/unit/geoMetricsBaseline.spec.ts` (name may vary) | Baseline shape stability (prevents silent schema regressions). |

---

## 2. Data Flow & Execution Order

```text
  primeGeoCompat() → load & normalize clusters + adjacency
        │
        ├─ metrics.mjs → writes geo-metrics.json (base stats → extended analytics) → (baseline optionally refreshed)
        │
        ├─ doctor.mjs → writes geo-doctor.json (+ symmetry proposal if enabled)
        │
        ├─ diff.mjs → reads metrics + baseline → writes geo-metrics.diff.json
        │
        └─ report-index.mjs → aggregates → geo-report.index.json
```

Extended (future): `report-md.mjs` → markdown; `bridge.mjs` → candidate edges.

---

## 3. Data Normalization & Integrity Guarantees

| Aspect | Guarantee |
|--------|-----------|
| Slugs | Lowercased & kebab-case assumed by runtime; duplicates eliminated in adjacency arrays. |
| Self loops | Removed (ignored in metrics & doctor). |
| Asymmetry | Counted (A→B without B→A); symmetry autofix proposes reciprocal patch only. |
| Unknown nodes | Dropped during adjacency normalization; not recorded in metrics. |
| Coordinates | Only counted when both `lat` & `lng` are finite numbers. |
| Components | Calculated on undirected projection (edge exists if either direction defined). |
| Representatives | Deterministic tie-breaking (degree → name → slug; centroid ties: degree priority). |

---

## 4. Metrics Glossary

| Field | Meaning | Notes |
|-------|---------|-------|
| `clusters` | Count of cluster objects post-load. | Fails doctor if below `GEO_MIN_CLUSTERS`. |
| `suburbs` | Total suburb count across clusters. | May differ from adjacency node set if stray adjacency nodes present (should converge). |
| `adjacencyNodes` | Unique keys in adjacency map. | Used to detect orphans vs cluster coverage. |
| `orphanAdjacencyNodes` | Adjacency nodes not belonging to any cluster. | Should be 0; elevated counts justify data cleanup. |
| `degree.*` | Distribution of node out-degree (after normalization). | Quantiles via nearest-rank; mean fixed to 2 decimals. |
| `graph_components.*` | Fragmentation summary (count, largest component size, largest ratio, smallest listing). | `smallest` elements limited (size<=20, top 5). |
| `cross_cluster_edges` | Undirected unique edges crossing clusters. | Sensitive to cluster boundary edits. |
| `cluster_representatives` | Representative slug per strategy per cluster. | Object keyed by cluster slug. |
| `cluster_cohesion` | Internal vs cross edge counts & internal ratio per cluster. | High ratios (>.9) indicate strong internal connectivity. |
| `bridge_suburbs` | High cross-cluster ratio + adequate degree (potential structural “bridges”). | Derived from adjacency & cluster mapping. |
| `coverageByCluster` | Per-cluster coordinate coverage ratio (0–1). | In metrics meta. |
| `coverage_by_cluster` | Same as above but inside doctor report. | Mirrors metrics for gating clarity. |

---

## 5. Thresholds & Gating (Doctor)

| Environment Variable | Default | Effect |
|----------------------|---------|--------|
| `GEO_MIN_CLUSTERS` | 1 | Minimum clusters required. |
| `GEO_REQUIRE_SYMMETRY` | true | Fail if any asymmetry edges. |
| `GEO_MIN_COORDS_PCT` | 80 | Global coordinate coverage %. |
| `GEO_MAX_CROSS_CLUSTER_EDGES` | Infinity | Cap cross-cluster edges (fail if exceeded when finite). |
| `GEO_MAX_COMPONENTS` | Infinity | Max allowed component count (fail if exceeded when finite). |
| `GEO_AUTOFIX_SYMMETRY` | 0 | If `1`, propose symmetric adjacency file. |

Serialization detail: `Infinity` values are stringified to `"Infinity"` in output for audit transparency.

---

## 6. Diff & Severity Semantics

Severity classification (current heuristic):

| Rule | Severity |
|------|----------|
| `graph_components.count` increase (unbounded) | error |
| `degree.mean` drop > 10% | error |
| Absolute % change > 20% (other tracked fields) | warn |
| Otherwise | info |

Representative churn:

| Strategy | Default Severity | Rationale |
|----------|------------------|-----------|
| `adjacency_degree` | warn | Structural hub shift. |
| `centroid` | warn | Geographic centroid movement. |
| `alphabetical` | info | Usually cosmetic ordering change. |

---

## 7. Fragmentation Handling (Current vs Options)

Current: 2 components (`largest_ratio ~0.988`). Smallest component list identifies the “Moreton Island” quartet.

Options:

| Policy | Config/Gate | Pros | Cons |
|--------|-------------|------|------|
| Intentional island | `GEO_MAX_COMPONENTS=2` | Geographic fidelity | Slightly more logic for ‘reachability’ features |
| Enforced single component | `GEO_MAX_COMPONENTS=1` + add bridge edges | Simplifies path algorithms | Potentially artificial connectivity |
| Permissive | leave Infinity | No friction | Silent fragmentation drift risk |

---

## 8. Troubleshooting Log (Encountered & Solved)

| Issue | Symptom | Root Cause | Resolution | Future Guard |
|-------|---------|-----------|-----------|--------------|
| Duplicate logic blocks in early doctor script | Confusing double execution | Residual experimental code | Consolidated to single function logic | Unit test to assert single write pass |
| Asymmetry edges not showing when empty adjacency variant loaded | Fallback noop path hid logic | Module fallback swallows load errors | Added explicit console warning + noop safe defaults | Logging & optional validation flag |
| Components count NaN delta in diff | Baseline lacked new fields | Baseline not refreshed after metrics enhancement | Refreshed baseline with all new fields | Add baseline refresh step to release checklist |
| Infinity serialization inconsistencies | `Infinity` risked `null`/tooling mismatch | Raw numeric Infinity JSON semantics | Stringified Infinity and tolerant deserializer | Policy documented |
| Representative churn partially invisible | Shape changed (array → object) | Diff mapping assumed array shape | Added shape-normalizing helper `repsToMap()` | Backward compatibility preserved |
| No smallest component introspection | Harder fragmentation triage | Only summary stats emitted | Added `graph_components.smallest[]` | Future: size threshold config |

---

## 9. Unasked (But Answered) Questions

| Question | Answer |
|----------|--------|
| Why nearest-rank quantiles vs interpolation? | Determinism + simplicity for modest N; avoids floating ambiguity. |
| Why store representatives per strategy (not single pick)? | Enables auditing & strategy evolution without churn risk. |
| Why not mutate adjacency in-place on autofix? | Preserves source of truth; human review required; prevents silent graph rewrites. |
| Why count components on undirected projection? | Directional gaps shouldn’t artificially split connectivity claims. |
| How to add a new representative strategy? | Implement `representativeOfClusterSync` variant + extend serialization map + update tests. |
| How to gate fragmentation strictly later? | Set `GEO_MAX_COMPONENTS=1`; run doctor; address failures (bridge or policy). |
| How to diff multiple historical runs? | Persist sequential metrics snapshots (timestamped) & extend diff script to accept two explicit file paths. |
| Can we centrality-rank suburbs? | Yes—add approximate betweenness or weighted degree as new field; update tests + docs. |

---

## 10. Expansion Guide (Future Enhancements)

| Enhancement | Outline |
|-------------|---------|
| Markdown PR Reporter | Implement `report-md.mjs` reading index + diff; push artifact to CI comment bot. |
| Bridge Candidate Generator | Use smallest component nodes → nearest mainland nodes via haversine; output overlay adjacency. |
| Config Overrides (`geo.config.json`) | Add optional severity overrides, per-cluster min coverage, cross-cluster edge whitelists. |
| Historical Run Index | Append `geo-report.index.json` copies to `__history/<timestamp>/`; build history timeline page. |
| Per-Cluster Fragmentation Score | (# internal edges) / (# total edges touching cluster) → trending dashboard metric. |
| Performance Timings | Wrap phases with `performance.now()`; store in `meta.timings`. |
| API Endpoints | Expose latest artifacts as JSON for front-end dashboards (Astro API routes). |

---

## 11. Reproduction Script (One-Shot Bootstrap)

Save as `scripts/geo/bootstrap.mjs` to recreate the full analytics suite in a fresh clone (assuming data files exist):

```js
#!/usr/bin/env node
import { execSync } from 'node:child_process';

function run(label, cmd) {
  console.log(`[bootstrap] ${label}`);
  execSync(cmd, { stdio: 'inherit' });
}

// 1. Metrics snapshot
run('metrics', 'node scripts/geo/metrics.mjs');

// 2. Doctor validation (permissive components; strict symmetry & coords)
run('doctor', 'GEO_REQUIRE_SYMMETRY=true GEO_MIN_COORDS_PCT=80 node scripts/geo/doctor.mjs');

// 3. Baseline (create if missing)
try { execSync('test -f __meta/geo-metrics.baseline.json'); }
catch { run('baseline-init', 'cp __reports/geo-metrics.json __meta/geo-metrics.baseline.json'); }

// 4. Diff
run('diff', 'node scripts/geo/diff.mjs');

// 5. Index aggregation
run('index', 'node scripts/geo/report-index.mjs');

console.log('\n[bootstrap] COMPLETE – artifacts in __reports/.');
```

**Usage:**

```bash
node scripts/geo/bootstrap.mjs
```

---

## 12. CI Minimal Sequence

```bash
npm run geo:metrics
GEO_REQUIRE_SYMMETRY=true GEO_MIN_COORDS_PCT=90 GEO_MAX_COMPONENTS=2 npm run geo:doctor
npm run geo:diff -- --branch main
npm run geo:report
```

Add failure gate on diff errors (optional):

```bash
node -e "const r=require('./__reports/geo-metrics.diff.json');process.exit(r.rows.some(x=>x.severity==='error')?1:0)"
```

---

## 13. Ops Checklists

### 13.1 Ship Checklist

* [ ] Metrics produced & non-zero clusters/suburbs
* [ ] Doctor passed (`ok:true`)
* [ ] Fragmentation matches policy (count acceptable)
* [ ] Coverage ≥ gate & per-cluster coverage plausible
* [ ] Diff shows no unexpected `error` severities
* [ ] Updated baseline only if intentional model change

### 13.2 Triage Checklist

* [ ] Open `geo-doctor.json` → inspect `failures[]`
* [ ] If symmetry fail: review `geo-adjacency.symmetric.json`
* [ ] If fragmentation fail: inspect `graph_components.smallest`; consider bridge edges
* [ ] If coverage fail: confirm coordinate fields & numeric coercion
* [ ] Re-run doctor with same thresholds; verify pass

---

## 14. Security & Safety Considerations

| Topic | Approach |
|-------|----------|
| Source immutability | Autofix & bridge suggestions write *proposals* only. |
| Injection risk | Scripts avoid eval; JSON parsed from whitelisted paths. |
| Determinism | Sorting & tie-break rules ensure reproducible diffs. |
| Failure transparency | Doctor exits non-zero with explicit `failures[]`. |
| Leakage | No secrets; purely structural data. |

---

## 15. Key Trade-Offs Made

| Decision | Rationale | Alternative Rejected |
|----------|-----------|----------------------|
| Keep representative strategies separate | Auditability & future weighting | Single fused heuristic which would hinder debugging |
| Use nearest-rank quantiles | Simplicity & determinism | Interpolated quantiles (minor fractional noise) |
| Undirected components for fragmentation | Prevent spurious splits | Pure directed SCCs (harder to interpret for path semantics) |
| Non-mutating autofix | Avoid silent writes | Direct adjacency rewrite (risk of unnoticed drift) |

---

## 16. Suggested Next Steps (Optional)

1. Implement markdown reporter (`report-md.mjs`).
2. Add `bridge.mjs` (if opting for strict connectivity) – or document intentional island policy in `GEO_OPERATORS_GUIDE.md`.
3. Introduce `meta.timings` for performance baselining.
4. Add config overrides (`geo.config.json` v2) for severity and per-cluster coverage gating.
5. Expand diff to include coverage delta severity rules.
6. Build Astro dashboard pages reading artifacts (see design notes in previous internal discussion).

---

## 17. FAQ Lite (Quick Answers)

| Q | A |
|---|---|
| Can we run doctor without metrics? | Metrics should usually run first (diff + index expect metrics file), but doctor can run independently. |
| Are orphan adjacency nodes fatal? | Not now—highlight via `orphanAdjacencyNodes`; can add gate if needed. |
| Why not store graph in a DB? | Scale & complexity do not warrant it; static JSON is fast + diffable. |
| How do we test new adjacency before committing? | Run scripts against a branch copy; optionally use overlay adjacency file for ephemeral evaluation. |

---

## 18. Contact & Ownership

* Primary Owner: (add team / engineer)
* Escalation Path: open issue labeled `geo-analytics` + attach failing artifacts.
* Change Policy: baseline updates only after intentional model or structural data change + PR review.

---
\n## 19. One-Line TL;DR

Deterministic graph analytics with auditable representatives, fragmentation awareness, and CI-ready gating—clean baseline, explicit thresholds, and low-friction future expansion.

---
End of Document
\n---
\n## 20. Geo-Focused Directory Tree (Curated)

```text
root/
  src/
    lib/
      geoCompat.runtime.js        # Runtime adapter (load + normalize)
    data/
      areas.clusters.json         # Clusters + suburbs + coords
      areas.adj.json              # Core adjacency (directed)
      proximity.json              # (Optional) persisted nearby lists
      geo.config.json             # Scoring (not analytics severity overrides yet)
    pages/ (future Astro UI surface)
  scripts/
    geo/
      metrics.mjs                 # Metrics generation
      doctor.mjs                  # Validation + thresholds + autofix
      diff.mjs                    # Baseline/branch delta & severities
      report-index.mjs            # Aggregated index composer (planned if not present)
      report-md.mjs               # (Planned) Markdown reporter
      bridge.mjs                  # (Planned) Bridge candidate generator
  __reports/                      # Machine-readable primary artifacts
    geo-metrics.json
    geo-doctor.json
    geo-metrics.diff.json
    geo-report.index.json
    geo-adjacency.symmetric.json (conditional)
  __meta/
    geo-metrics.baseline.json     # Baseline snapshot
  __ai/
    geo-bridge-candidates.json    # (Future) Bridge suggestions
    geo-report.md                 # (Future) PR markdown summary
  tests/
    unit/
      geoDoctor.spec.ts
      geoDiff.spec.ts
      geoMetricsBaseline.spec.ts
  docs/
    GEO_OPERATORS_GUIDE.md
    GEO_FULL_IMPLEMENTATION_OVERVIEW.md
```

---
\n## 21. Phase Change Log (Condensed)

| Phase | Date (approx) | Core Additions | Notes |
|-------|---------------|----------------|-------|
| Seed  | Earlier       | Base metrics + symmetry detection | Pre-Batch enhancements minimal gating. |
| Batch 2 Integration | Current | Representatives, components, cohesion, bridges, diff severities | Major structural maturity. |
| Phase 1 Hardening | Current | Smallest components, per-cluster coverage, Infinity stringification, refreshed baseline | Audit readiness achieved. |
| Phase 2 (Planned) | Pending | Markdown reporter, bridge tool, config overrides | Visibility + governance. |
| Phase 3 (Planned) | Pending | Timings, history index, performance & centrality | Operational intelligence. |

---
\n## 22. Performance Benchmarks (Current Scale)

| Pass | Complexity | Observed (approx) | Notes |
|------|------------|-------------------|-------|
| Load/prime | O(V + E) | < 50 ms | JSON parse + normalization. |
| Metrics core | O(V + E) | < 80 ms | Degree stats + cohesion + components. |
| Representatives | O(V) per strategy | ~10–15 ms | Three strategies, cached cluster loops. |
| Doctor | O(V + E) | < 60 ms | Rebuild undirected projection + validation. |
| Diff | O(F) | < 10 ms | F = compared fields; constant small. |

Future: add `meta.timings` to record exact numbers per run for regression detection.

---
\n## 23. Risk Matrix (Augmented)

| Risk | Area | Likelihood | Impact | Mitigation | Status |
|------|------|------------|--------|------------|--------|
| Silent fragmentation growth | Structure | Medium | Medium | Gate `GEO_MAX_COMPONENTS`, smallest list | Pending policy choice |
| Representative strategy bug | Logic | Low | Medium | Deterministic tie-break + churn diff | Active guard |
| Coordinate regression | Data quality | Low | Medium | Global & per-cluster coverage gating | Active guard |
| Baseline drift accepted silently | Process | Medium | Low | Explicit baseline refresh step + test | Active guard |
| Unbounded cross-cluster edge inflation | Topology | Low | Low–Med | Optional gate + diff severity | Optional |
| Performance regression (larger V,E) | Scale | Low (now) | Low–Med | Add timings + watch growth | Planned |
| Accidental mutation of source adjacency | Integrity | Low | High | Non-mutating autofix; proposals only | Active guard |
| Severity heuristic misclassification | Policy | Medium | Low | Config overrides (future) | Planned |

---
\n## 24. Future Testing Strategy (Beyond Current Unit Tests)

| Category | Test Idea | Goal |
|----------|-----------|------|
| Property | Autofix idempotence (run twice → added_edges=0 second time) | Ensure stability |
| Scenario | Force artificial asymmetry & expect failure / autofix proposal | Validate gating path |
| Scenario | Force fragmentation (remove a bridge) & gate at `GEO_MAX_COMPONENTS=1` | Regression in connectivity |
| Property | `sum(component sizes) == total nodes` | Invariant assurance |
| Load | Large synthetic graph (e.g. 5k nodes) timing under threshold | Performance guard |
| Strategy | Add mock cluster with tie conditions (names/degree) to verify deterministic pick | Tie-break correctness |
| Config (future) | Severity override file applied accurately | Governance correctness |

---
\n## 25. Bridge Candidate Script (Detailed Pattern – Planned)

Core algorithm steps (to be implemented in `scripts/geo/bridge.mjs`):

1. Prime runtime; fetch adjacency + cluster coordinate map.
2. Build undirected component sets; select smallest component(s) (excluding largest).
3. For each island node, compute distance to all main-component nodes (Haversine).
4. Filter by `--maxKm`; take top `--top` nearest.
5. Emit `__ai/geo-bridge-candidates.json` with structure:

```json
   {
     "params": { "maxKm": 30, "top": 3 },
     "island": ["bulwer","moreton-island","kooringal","cowan-cowan"],
     "candidates": [
       { "source": "bulwer", "candidates": [ { "target": "<main-node>", "km": 27.13 } ] }
     ]
}
```


1. (Optional) With `--write`, output overlay adjacency file for manual review.

Edge validations: no self loops, finite distances only, skip nodes missing coordinates.

---
\n## 26. Config Override Example (Future `geo.policy.json`)

Proposed separate analytics policy file (NOT to confuse with existing scoring `geo.config.json`):

```jsonc
{
  "severityOverrides": {
    "graph_components.count": "error",
    "degree.mean": "warn"
  },
  "perCluster": {
    "ipswich": { "minCoordsPct": 0.95 }
  },
  "whitelists": {
    "crossClusterEdges": [["node-a","node-b"]]
  },
  "representatives": {
    "strategyOrder": ["centroid","adjacency_degree","alphabetical"]
  }
}
```

Integration steps: load if present; apply overrides after computing raw severities; propagate into diff output.

---
\n## 27. Historical Run Schema (Planned)

When implementing history retention, suggested directory pattern:

```text
__history/
  2025-09-12T06-30-00Z/
    geo-metrics.json
    geo-doctor.json
    geo-metrics.diff.json   # (diff vs baseline at that time)
    meta.json               # { "commit": "<sha>", "branch": "feature/x", "generatedAt": "..." }
```

Index file `__history/index.json` example:

```json
{
  "runs": [
    { "id": "2025-09-12T06-30-00Z", "commit": "abcd123", "components": 2, "coverage": 1.0 },
    { "id": "2025-09-13T05-10-00Z", "commit": "ef45678", "components": 1, "coverage": 0.99 }
  ]
}
```

Diff UI can then compare arbitrary `runs[i].id` pairs.

---
\n## 28. Glossary (Quick Reference)

| Term | Definition |
|------|------------|
| Component | Connected set of nodes in undirected projection of adjacency. |
| Coverage (Global) | % of suburbs with valid (finite) lat/lng. |
| Coverage (Per Cluster) | Ratio of valid coordinates inside a cluster. |
| Representative (Centroid) | Suburb nearest to arithmetic mean of cluster coordinates. |
| Bridge Suburb | Node with notable proportion of cross-cluster adjacency edges. |
| Churn (Representative) | Change in representative slug for a strategy vs baseline. |
| Symmetry | Condition where every directed edge has a reciprocal counterpart. |
| Autofix Proposal | Non-mutating JSON enumerating symmetric completion of edges. |
| Baseline | Stable snapshot for diff comparisons; updated intentionally. |

---
\n## 29. Additional Improvement Ideas (Backlog Seed)

* Weighted centrality (edge weighting via road importance or service frequency).
* GeoJSON export of components for quick mapping overlays.
* Visualization hooks (force-directed cluster boundary graph) for UI.
* Alert hook (GitHub Action) posting comment when severity `error` appears.
* Slack webhook integration for fragmentation or coverage regressions.
* Drift detection for `proximity.json` vs on-the-fly nearest computations.
* Switch to typed schema emission (`schemaVersion` bump when structural fields added).

---
\n## 30. Maintenance SLA Suggestion

| Action | Cadence | Owner |
|--------|---------|-------|
| Baseline review | After intentional structural change | Geo maintainer |
| Metrics smoke run | Each PR (CI) | CI pipeline |
| Fragmentation audit | Weekly until policy locked | Geo maintainer |
| Representative churn scan | Weekly or on major adjacency edits | Content/SEO owner |
| Coverage audit per cluster | Monthly | Data steward |

---
\n## 31. Closing Note

The system is structured so each enhancement is an additive module (script + artifact + test + doc row). Keep this invariant: *data correctness before performance; clarity before compactness.* This ensures sustainable evolution without hidden coupling.

