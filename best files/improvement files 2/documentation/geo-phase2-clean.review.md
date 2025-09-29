# Branch review: feature/geo-phase2-clean
Generated: Mon Sep 15 00:39:33 UTC 2025

## Pointers
- HEAD on feature/geo-phase2-clean: 20bb5a1
- Base: origin/main
- Commits since base: 23

## Recent commits
* 20bb5a1 (HEAD -> feature/geo-phase2-clean, origin/feature/geo-phase2-clean) geo(adjacency): tuning (K_BASE=9,PCT_PRUNE=97,MAX_KM_EXT=16) + validator cross-cluster + gate integration
* 08ea92a docs(geo): add GEO_STATUS_REPORT status summary
* 84e7bf2 geo(adjacency): add builder+validator config & schemas
* ef23ae1 geo(data): ingest normalized data + runtime coords merge & slug hyphenization
* 8451b3a lint(spacing): add spacing.mjs tool + apply auto-fixes to geo scripts
* 488e39b geo(report): style & spacing fixes (lint comment resolutions)
* bf5848e geo(metrics): fix representative import path reuse runtime module
* 545f440 geo(gate): use diff.worst_severity with fallback computeWorst
* 1b22d00 geo(diff): baseline arg, write-baseline, allow-initial, added cross_cluster_edges + worst_severity classification
* 0f533c0 geo(scripts): restructure geo pipeline (geo:produce, geo:gate:read, explicit metrics/doctor/diff)
* 8d45b29 geo: add runtime shim (geoCompat.runtime) and fix imports for geo scripts (P0)
* 6507c6c geo(gate): add policy-only mode, policy drift flag, performance budgets, churn skip notice, performance warn/error codes
* a4a518c geo(gate): add coverage normalization w/ hierarchy fallback, failure codes, policy checksum, cross-cluster ratio gating, churn severity delta, timings propagation
* b45adad geo: doctor percent coverage, cross-cluster ratio, asymmetry sample w/ degrees, schemaVersion+hash, unexpected_small; gate coverage normalization; stub path fix
* 4f0cc3e geo: doctor hierarchy validation, asymmetry samples, island annotation; gate strict doctor check + severity delta; robust stub imports
* 8100c7e geo: add hash baseline, switch to geo:ci, churn gating, stub generator, hierarchical cluster draft & rollup
* 8520178 docs(geo): expand phase2 status & roadmap with architecture, metrics inventory, algorithms, governance
* 0a5d695 geo: add strategy coverage threshold, CI workflow, PR summary, churn & hash verification integration
* 1b97451 geo: normalize sandbox, add history archiver, enforce strategy coverage %, provenance doc, full suite scripts
* eef16c2 geo: add cluster coverage field, strategy coverage analyzer script
* 0979083 geo: add gating script (severity, per-cluster coverage) and extend policy schema
* 7bf5a01 docs(geo): add hierarchical sub-clusters proposal
* 95b0212 geo: phase2 clean branch – policy island support, reporter, bridge candidates, docs & tests

## Diffstat (summary)
 .github/workflows/geo-gate.yml                     |   52 +
 GEO_STATUS_REPORT.md                               |  188 +
 __ai/OWNER_TODO.md                                 |   13 +
 __ai/geo-bridge-candidates.json                    |  160 +
 __ai/geo-proximity-diff.json                       |  662 ++++
 __ai/geo-report.json                               |  734 ++++
 __ai/geo-report.md                                 |   27 +
 __ai/geo-report.txt                                |   40 +
 __ai/upstream-issues-summary.json                  |    9 +
 __ai/upstream-issues.json                          |  344 ++
 __history/adjacency-history.json                   |   50 +
 __meta/geo-metrics.baseline.json                   |    9 +
 __meta/geo.hashes.json                             |    6 +
 __reports/adjacency.build.json                     |   55 +
 __reports/geo-doctor.json                          |  123 +
 __reports/geo-gate.json                            |   98 +
 __reports/geo-metrics.diff.json                    |   67 +
 __reports/geo-metrics.json                         |  359 ++
 __reports/geo-report.index.json                    |  500 +++
 __reports/geo-strategy-coverage.json               |  257 ++
 __reports/local-build-run-after-install.log        |  103 +
 __reports/local-build-run.log                      |   59 +
 config/adj.config.json                             |   25 +
 data/PROVENANCE.md                                 |   22 +
 docs/CODE-CITATIONS.md                             |   12 +
 docs/GEO_FULL_IMPLEMENTATION_OVERVIEW.md           |  569 +++
 docs/GEO_PHASE2_PLAN.md                            |   49 +
 docs/GEO_PHASE2_STATUS_AND_ROADMAP.md              |  518 +++
 docs/GEO_SUBCLUSTERS_PROPOSAL.md                   |  246 ++
 geo-adjacency-TODO.md                              |   17 +
 geo-import/README.geo-data.md                      |   24 +
 geo-import/README.md                               |   70 +
 geo-import/adjacency.json                          |    1 +
 geo-import/aliases.json                            |  347 ++
 geo-import/areas.clusters.json                     |  378 ++
 geo-import/geo.integrity.json                      |   20 +
 geo-import/lga.groups.json                         |  354 ++
 geo-import/lgas.groups.json                        |  354 ++
 geo-import/suburbs.aliases.json                    |  347 ++
 geo-import/suburbs.coords.json                     | 1382 +++++++
 geo-import/suburbs.index.json                      | 3797 ++++++++++++++++++++
 geo.policy.json                                    |   19 +
 package.json                                       |   18 +
 public/faqs.compiled.json                          |    2 +-
 push.log                                           |    8 +
 sandbox/geo/README.md                              |   15 +
 schemas/adj.config.schema.json                     |   22 +
 schemas/adjacency.build.schema.json                |   18 +
 scripts/geo/bridge.mjs                             |   46 +
 scripts/geo/build-adjacency.mjs                    |  164 +
 scripts/geo/churn.mjs                              |   27 +
 scripts/geo/diff.mjs                               |  114 +
 scripts/geo/doctor.mjs                             |  150 +
 scripts/geo/gate.mjs                               |  205 ++
 scripts/geo/generate-missing-test-stubs.mjs        |   33 +
 scripts/geo/hash-verify.mjs                        |   49 +
 scripts/geo/history-archive.mjs                    |   30 +
 scripts/geo/ingest-import.mjs                      |  189 +
 scripts/geo/metrics.mjs                            |  170 +
 scripts/geo/overlay-merge.mjs                      |   33 +
 scripts/geo/pr-summary.mjs                         |   41 +
 scripts/geo/report-index.mjs                       |   14 +
 scripts/geo/report-md.mjs                          |   45 +
 scripts/geo/strategy-coverage.mjs                  |   46 +
 scripts/geo/validate-adjacency.mjs                 |   87 +
 scripts/lint/spacing.mjs                           |  400 +++
 src/data/README.geo-data.md                        |   24 +
 src/data/__backup_20250914_065639/adjacency.json   |  734 ++++
 .../__backup_20250914_065639/suburbs.coords.json   | 1738 +++++++++
 src/data/adjacency.json                            |  735 +---
 src/data/areas.clusters.json                       |  378 ++
 src/data/areas.hierarchical.clusters.json          |   10 +
 src/data/faqs.compiled.json                        |    2 +-
 src/data/geo.integrity.json                        |   20 +
 src/data/geo.integrity.local.json                  |   28 +
 src/data/lgas.groups.json                          |  354 ++
 src/data/suburbs.aliases.json                      |  347 ++
 src/data/suburbs.coords.json                       | 1382 +++++++
 src/data/suburbs.index.json                        | 3797 ++++++++++++++++++++
 src/lib/geoCompat.runtime.js                       |   84 +
 src/lib/geoCompat.runtime.ts                       |   77 +
 src/pages/areas/# Code Citations.md                |   12 +
 tests/unit/geoBridge.spec.ts                       |   15 +
 tests/unit/geoDiff.spec.ts                         |   15 +
 tests/unit/geoDoctor.spec.ts                       |   23 +
 tests/unit/geoMetricsBaseline.spec.ts              |   29 +
 tests/unit/geoPolicyIsland.spec.ts                 |   37 +
 tests/unit/geoReportMd.spec.ts                     |   16 +
 88 files changed, 23513 insertions(+), 736 deletions(-)

## Changed files
A	.github/workflows/geo-gate.yml
A	GEO_STATUS_REPORT.md
A	__ai/OWNER_TODO.md
A	__ai/geo-bridge-candidates.json
A	__ai/geo-proximity-diff.json
A	__ai/geo-report.json
A	__ai/geo-report.md
A	__ai/geo-report.txt
A	__ai/upstream-issues-summary.json
A	__ai/upstream-issues.json
A	__history/adjacency-history.json
A	__meta/geo-metrics.baseline.json
A	__meta/geo.hashes.json
A	__reports/adjacency.build.json
A	__reports/geo-doctor.json
A	__reports/geo-gate.json
A	__reports/geo-metrics.diff.json
A	__reports/geo-metrics.json
A	__reports/geo-report.index.json
A	__reports/geo-strategy-coverage.json
A	__reports/local-build-run-after-install.log
A	__reports/local-build-run.log
A	config/adj.config.json
A	data/PROVENANCE.md
A	docs/CODE-CITATIONS.md
A	docs/GEO_FULL_IMPLEMENTATION_OVERVIEW.md
A	docs/GEO_PHASE2_PLAN.md
A	docs/GEO_PHASE2_STATUS_AND_ROADMAP.md
A	docs/GEO_SUBCLUSTERS_PROPOSAL.md
A	geo-adjacency-TODO.md
A	geo-import/README.geo-data.md
A	geo-import/README.md
A	geo-import/adjacency.json
A	geo-import/aliases.json
A	geo-import/areas.clusters.json
A	geo-import/geo.integrity.json
A	geo-import/lga.groups.json
A	geo-import/lgas.groups.json
A	geo-import/suburbs.aliases.json
A	geo-import/suburbs.coords.json
A	geo-import/suburbs.index.json
A	geo.policy.json
M	package.json
M	public/faqs.compiled.json
A	push.log
A	sandbox/geo/README.md
A	schemas/adj.config.schema.json
A	schemas/adjacency.build.schema.json
A	scripts/geo/bridge.mjs
A	scripts/geo/build-adjacency.mjs
A	scripts/geo/churn.mjs
A	scripts/geo/diff.mjs
A	scripts/geo/doctor.mjs
A	scripts/geo/gate.mjs
A	scripts/geo/generate-missing-test-stubs.mjs
A	scripts/geo/hash-verify.mjs
A	scripts/geo/history-archive.mjs
A	scripts/geo/ingest-import.mjs
A	scripts/geo/metrics.mjs
A	scripts/geo/overlay-merge.mjs
A	scripts/geo/pr-summary.mjs
A	scripts/geo/report-index.mjs
A	scripts/geo/report-md.mjs
A	scripts/geo/strategy-coverage.mjs
A	scripts/geo/validate-adjacency.mjs
A	scripts/lint/spacing.mjs
A	src/data/README.geo-data.md
A	src/data/__backup_20250914_065639/adjacency.json
A	src/data/__backup_20250914_065639/suburbs.coords.json
M	src/data/adjacency.json
A	src/data/areas.clusters.json
A	src/data/areas.hierarchical.clusters.json
M	src/data/faqs.compiled.json
A	src/data/geo.integrity.json
A	src/data/geo.integrity.local.json
A	src/data/lgas.groups.json
A	src/data/suburbs.aliases.json
A	src/data/suburbs.coords.json
A	src/data/suburbs.index.json
A	src/lib/geoCompat.runtime.js
A	src/lib/geoCompat.runtime.ts
A	src/pages/areas/# Code Citations.md
A	tests/unit/geoBridge.spec.ts
A	tests/unit/geoDiff.spec.ts
A	tests/unit/geoDoctor.spec.ts
A	tests/unit/geoMetricsBaseline.spec.ts
A	tests/unit/geoPolicyIsland.spec.ts
A	tests/unit/geoReportMd.spec.ts

## scripts/geo tree
scripts/geo-report.mjs
scripts/geo/bridge.mjs
scripts/geo/build-adjacency.mjs
scripts/geo/churn.mjs
scripts/geo/diff.mjs
scripts/geo/doctor.mjs
scripts/geo/gate.mjs
scripts/geo/generate-missing-test-stubs.mjs
scripts/geo/hash-verify.mjs
scripts/geo/history-archive.mjs
scripts/geo/ingest-import.mjs
scripts/geo/metrics.mjs
scripts/geo/overlay-merge.mjs
scripts/geo/pr-summary.mjs
scripts/geo/report-index.mjs
scripts/geo/report-md.mjs
scripts/geo/strategy-coverage.mjs
scripts/geo/validate-adjacency.mjs

## Config & schema diffs
diff --git a/__reports/adjacency.build.json b/__reports/adjacency.build.json
new file mode 100644
index 0000000..f349721
--- /dev/null
+++ b/__reports/adjacency.build.json
@@ -0,0 +1,55 @@
+{
+  "schemaVersion": 1,
+  "generatedAt": "2025-09-15T00:31:20.276Z",
+  "params": {
+    "K_BASE": 9,
+    "MAX_KM": 11,
+    "MAX_KM_EXT": 16,
+    "PCT_PRUNE": 97,
+    "MAX_CROSS": 2,
+    "MIN_DEG": 3,
+    "LOCALIZE": false
+  },
+  "inputs": {
+    "coords_sha256": "b3827e88a18e1b29a478d1781615ae1def32817fa1756d1312fbb594e2f62b82",
+    "areas_sha256": "5b10d3e8931bce95d8351caa2929031a1fdea42e7c220d8a82b2022bb7491b07",
+    "lgas_sha256": "128899752216680060ff59ad0fcacfd796a7e3a142ea15a9ce4a40ff6ab2b6db"
+  },
+  "nodes": 345,
+  "qa": {
+    "orphans_in_coords_not_clustered": 0,
+    "orphan_examples": []
+  },
+  "degrees": {
+    "mean": 6.75,
+    "min": 0,
+    "max": 9,
+    "histogram": {
+      "0": 2,
+      "1": 8,
+      "2": 4,
+      "3": 12,
+      "4": 20,
+      "5": 32,
+      "6": 44,
+      "7": 84,
+      "8": 67,
+      "9": 72
+    },
+    "isolates": 2
+  },
+  "components": {
+    "count": 5,
+    "largest_ratio": 0.98
+  },
+  "edges": {
+    "undirected": 1164
+  },
+  "cross_cluster": {
+    "edges": 31,
+    "ratio": 0.0266
+  },
+  "distances": {
+    "cutoff_km": 7.158
+  }
+}
diff --git a/__reports/geo-doctor.json b/__reports/geo-doctor.json
new file mode 100644
index 0000000..4f137c9
--- /dev/null
+++ b/__reports/geo-doctor.json
@@ -0,0 +1,123 @@
+{
+  "report": {
+    "clusters": 3,
+    "suburbs": 121,
+    "edges": {
+      "directed": 1546,
+      "undirected": 773,
+      "cross_cluster_ratio": 0.0039
+    },
+    "asymmetry_edges": 0,
+    "cross_cluster_edges": 3,
+    "coords_coverage_pct": 100,
+    "coverage_by_cluster": {
+      "ipswich": 100,
+      "brisbane": 100,
+      "logan": 100
+    },
+    "cluster_coverage": {
+      "ipswich": 100,
+      "brisbane": 100,
+      "logan": 100
+    },
+    "hierarchy_rollup": {
+      "ipswich": 100,
+      "brisbane": 0,
+      "logan": 100
+    },
+    "graph_components": {
+      "count": 8,
+      "largest_size": 334,
+      "largest_ratio": 0.968,
+      "smallest": [
+        {
+          "size": 1,
+          "nodes": [
+            "kooringal"
+          ],
+          "is_island": true
+        },
+        {
+          "size": 1,
+          "nodes": [
+            "lake-manchester"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 1,
+          "nodes": [
+            "lyons"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 1,
+          "nodes": [
+            "moreton-bay"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 2,
+          "nodes": [
+            "banks-creek",
+            "england-creek"
+          ],
+          "is_island": false
+        }
+      ],
+      "unexpected_small": [
+        {
+          "size": 1,
+          "nodes": [
+            "lake-manchester"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 1,
+          "nodes": [
+            "lyons"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 1,
+          "nodes": [
+            "moreton-bay"
+          ],
+          "is_island": false
+        },
+        {
+          "size": 2,
+          "nodes": [
+            "banks-creek",
+            "england-creek"
+          ],
+          "is_island": false
+        }
+      ]
+    },
+    "asymmetry_examples": [],
+    "meta": {
+      "timings": {
+        "doctor_ms": 320.7
+      },
+      "schemaVersion": 1,
+      "hash": "97b52488aa4c4add121cebf98d581e2cda6a08a0882c06d9f638480fcb4ae735"
+    },
+    "autofix": {
+      "enabled": false
+    }
+  },
+  "thresholds": {
+    "minClusters": 1,
+    "requireSymmetry": true,
+    "minCoordsPct": 80,
+    "maxCrossClusterEdges": "Infinity",
+    "maxComponents": "Infinity"
+  },
+  "ok": true,
+  "failures": []
+}
\ No newline at end of file
diff --git a/__reports/geo-gate.json b/__reports/geo-gate.json
new file mode 100644
index 0000000..deb9706
--- /dev/null
+++ b/__reports/geo-gate.json
@@ -0,0 +1,98 @@
+{
+  "gated_at": "2025-09-13T21:29:20.663Z",
+  "mode": "policy-only",
+  "worst_severity": "error",
+  "max_allowed": "error",
+  "coverage_failures": [
+    {
+      "cluster": "ipswich",
+      "actual": 0,
+      "required": 0.98
+    },
+    {
+      "cluster": "brisbane",
+      "actual": 0,
+      "required": 1
+    }
+  ],
+  "doctor_issues": [
+    "too_many_components",
+    "doctor_failed"
+  ],
+  "unexpected_small_components": [
+    {
+      "size": 1,
+      "nodes": [
+        "springfield lakes"
+      ],
+      "is_island": false
+    },
+    {
+      "size": 1,
+      "nodes": [
+        "augustine heights"
+      ],
+      "is_island": false
+    },
+    {
+      "size": 1,
+      "nodes": [
+        "redbank plains"
+      ],
+      "is_island": false
+    },
+    {
+      "size": 1,
+      "nodes": [
+        "bellbird park"
+      ],
+      "is_island": false
+    },
+    {
+      "size": 1,
+      "nodes": [
+        "collingwood park"
+      ],
+      "is_island": false
+    }
+  ],
+  "churn": null,
+  "strategy": {
+    "pct": null,
+    "total": null,
+    "uncovered": null,
+    "min_required": 90
+  },
+  "policyVersion": 1,
+  "failures": [
+    {
+      "code": "coverage",
+      "message": "per-cluster coverage shortfall",
+      "coverageFailures": [
+        {
+          "cluster": "ipswich",
+          "actual": 0,
+          "required": 0.98
+        },
+        {
+          "cluster": "brisbane",
+          "actual": 0,
+          "required": 1
+        }
+      ]
+    },
+    {
+      "code": "doctor",
+      "message": "doctor anomalies present",
+      "doctorIssues": [
+        "too_many_components",
+        "doctor_failed"
+      ]
+    }
+  ],
+  "timings": {
+    "doctor_ms": 4.2
+  },
+  "policyChecksum": "91e3be296ba59f5b7c846b0a9169e7884e7db5d28a0025f7d30c3f962acef6b8",
+  "policyChanged": null
+}
\ No newline at end of file
diff --git a/__reports/geo-metrics.diff.json b/__reports/geo-metrics.diff.json
new file mode 100644
index 0000000..9798de7
--- /dev/null
+++ b/__reports/geo-metrics.diff.json
@@ -0,0 +1,67 @@
+{
+  "compared_at": "2025-09-13T21:29:20.623Z",
+  "branch": null,
+  "rows": [
+    {
+      "field": "clusters",
+      "baseline": 3,
+      "current": 3,
+      "delta": 0,
+      "pct": 0,
+      "severity": "info"
+    },
+    {
+      "field": "suburbs",
+      "baseline": 344,
+      "current": 121,
+      "delta": -223,
+      "pct": -64.83,
+      "severity": "error"
+    },
+    {
+      "field": "adjacencyNodes",
+      "baseline": 344,
+      "current": 121,
+      "delta": -223,
+      "pct": -64.83,
+      "severity": "error"
+    },
+    {
+      "field": "degree.mean",
+      "baseline": 5.43,
+      "current": 4.05,
+      "delta": -1.38,
+      "pct": -25.41,
+      "severity": "error"
+    },
+    {
+      "field": "graph_components.count",
+      "baseline": 2,
+      "current": 55,
+      "delta": 53,
+      "pct": 2650,
+      "severity": "info"
+    },
+    {
+      "field": "graph_components.largest_ratio",
+      "baseline": 0.988,
+      "current": 0.277,
+      "delta": -0.711,
+      "pct": -71.96,
+      "severity": "error"
+    },
+    {
+      "field": "cross_cluster_edges",
+      "baseline": 0,
+      "current": 0,
+      "delta": 0,
+      "pct": 0,
+      "severity": "info"
+    }
+  ],
+  "representative_changes": [],
+  "policyIslandMatch": false,
+  "worst_severity": "error",
+  "baseline_file": "__meta/geo-metrics.baseline.json",
+  "baseline_source": "file"
+}
\ No newline at end of file
diff --git a/__reports/geo-metrics.json b/__reports/geo-metrics.json
new file mode 100644
index 0000000..a6b3a1b
--- /dev/null
+++ b/__reports/geo-metrics.json
@@ -0,0 +1,359 @@
+{
+  "clusters": 3,
+  "suburbs": 121,
+  "adjacencyNodes": 345,
+  "orphanAdjacencyNodes": 4,
+  "degree": {
+    "min": 0,
+    "p25": 4,
+    "median": 5,
+    "p75": 6,
+    "p90": 6,
+    "max": 6,
+    "mean": 4.48
+  },
+  "schema_version": 2,
+  "meta": {
+    "generatedAt": "2025-09-14T23:31:56.907Z",
+    "coverageByCluster": {
+      "ipswich": 1,
+      "brisbane": 1,
+      "logan": 1
+    },
+    "globalCoveragePct": 100,
+    "timings": {
+      "prime_ms": 0,
+      "metrics_ms": 1.1,
+      "total_ms": 472.4
+    }
+  },
+  "top_hubs_per_cluster": [
+    {
+      "cluster": "ipswich",
+      "top": [
+        {
+          "slug": "augustine-heights",
+          "name": "Augustine Heights",
+          "degree": 6
+        },
+        {
+          "slug": "bellbird-park",
+          "name": "Bellbird Park",
+          "degree": 6
+        },
+        {
+          "slug": "booval",
+          "name": "Booval",
+          "degree": 6
+        },
+        {
+          "slug": "brookwater",
+          "name": "Brookwater",
+          "degree": 6
+        },
+        {
+          "slug": "camira",
+          "name": "Camira",
+          "degree": 6
+        },
+        {
+          "slug": "dinmore",
+          "name": "Dinmore",
+          "degree": 6
+        },
+        {
+          "slug": "east-ipswich",
+          "name": "East Ipswich",
+          "degree": 6
+        },
+        {
+          "slug": "ipswich",
+          "name": "Ipswich",
+          "degree": 6
+        },
+        {
+          "slug": "newtown",
+          "name": "Newtown",
+          "degree": 6
+        },
+        {
+          "slug": "sadliers-crossing",
+          "name": "Sadliers Crossing",
+          "degree": 6
+        }
+      ]
+    },
+    {
+      "cluster": "brisbane",
+      "top": [
+        {
+          "slug": "darra",
+          "name": "Darra",
+          "degree": 6
+        },
+        {
+          "slug": "doolandella",
+          "name": "Doolandella",
+          "degree": 6
+        },
+        {
+          "slug": "durack",
+          "name": "Durack",
+          "degree": 6
+        },
+        {
+          "slug": "fig-tree-pocket",
+          "name": "Fig Tree Pocket",
+          "degree": 6
+        },
+        {
+          "slug": "graceville",
+          "name": "Graceville",
+          "degree": 6
+        },
+        {
+          "slug": "jamboree-heights",
+          "name": "Jamboree Heights",
+          "degree": 6
+        },
+        {
+          "slug": "middle-park",
+          "name": "Middle Park",
+          "degree": 6
+        },
+        {
+          "slug": "milton",
+          "name": "Milton",
+          "degree": 6
+        },
+        {
+          "slug": "mount-ommaney",
+          "name": "Mount Ommaney",
+          "degree": 6
+        },
+        {
+          "slug": "sherwood",
+          "name": "Sherwood",
+          "degree": 6
+        }
+      ]
+    },
+    {
+      "cluster": "logan",
+      "top": [
+        {
+          "slug": "bahrs-scrub",
+          "name": "Bahrs Scrub",
+          "degree": 6
+        },
+        {
+          "slug": "beenleigh",
+          "name": "Beenleigh",
+          "degree": 6
+        },
+        {
+          "slug": "bethania",
+          "name": "Bethania",
+          "degree": 6
+        },
+        {
+          "slug": "browns-plains",
+          "name": "Browns Plains",
+          "degree": 6
+        },
+        {
+          "slug": "edens-landing",
+          "name": "Edens Landing",
+          "degree": 6
+        },
+        {
+          "slug": "hillcrest",
+          "name": "Hillcrest",
+          "degree": 6
+        },
+        {
+          "slug": "kingston",
+          "name": "Kingston",
+          "degree": 6
+        },
+        {
+          "slug": "logan-central",
+          "name": "Logan Central",
+          "degree": 6
+        },
+        {
+          "slug": "logan-reserve",
+          "name": "Logan Reserve",
+          "degree": 6
+        },
+        {
+          "slug": "marsden",
+          "name": "Marsden",
+          "degree": 6
+        }
+      ]
+    }
+  ],
+  "cross_cluster_edges": 3,
+  "cluster_representatives": {
+    "ipswich": {
+      "adjacency_degree": "ipswich",
+      "alphabetical": "augustine heights",
+      "centroid": "ipswich"
+    },
+    "brisbane": {
+      "adjacency_degree": "indooroopilly",
+      "alphabetical": "anstead",
+      "centroid": "indooroopilly"
+    },
+    "logan": {
+      "adjacency_degree": "logan central",
+      "alphabetical": "bahrs scrub",
+      "centroid": "logan central"
+    }
+  },
+  "graph_components": {
+    "count": 8,
+    "largest_size": 334,
+    "largest_ratio": 0.968
+  },
+  "cluster_cohesion": [
+    {
+      "cluster": "ipswich",
+      "suburbs": 30,
+      "internalEdges": 98,
+      "crossEdges": 48,
+      "internal_ratio": 0.671
+    },
+    {
+      "cluster": "brisbane",
+      "suburbs": 48,
+      "internalEdges": 166,
+      "crossEdges": 44,
+      "internal_ratio": 0.79
+    },
+    {
+      "cluster": "logan",
+      "suburbs": 43,
+      "internalEdges": 168,
+      "crossEdges": 36,
+      "internal_ratio": 0.824
+    }
+  ],
+  "bridge_suburbs": [
+    {
+      "slug": "st-lucia",
+      "degree": 5,
+      "cross": 4,
+      "cross_ratio": 0.8
+    },
+    {
+      "slug": "goodna",
+      "degree": 5,
+      "cross": 3,
+      "cross_ratio": 0.6
+    },
+    {
+      "slug": "red-hill",
+      "degree": 5,
+      "cross": 3,
+      "cross_ratio": 0.6
+    },
+    {
+      "slug": "riverview",
+      "degree": 5,
+      "cross": 3,
+      "cross_ratio": 0.6
+    },
+    {
+      "slug": "browns-plains",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "camira",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "dinmore",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "doolandella",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "hillcrest",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "milton",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "sadliers-crossing",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "springfield-lakes",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "woodend",
+      "degree": 6,
+      "cross": 3,
+      "cross_ratio": 0.5
+    },
+    {
+      "slug": "eagleby",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    },
+    {
+      "slug": "forest-lake",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    },
+    {
+      "slug": "karana-downs",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    },
+    {
+      "slug": "logan-village",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    },
+    {
+      "slug": "north-booval",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    },
+    {
+      "slug": "oxley",
+      "degree": 5,
+      "cross": 2,
+      "cross_ratio": 0.4
+    }
+  ]
+}
\ No newline at end of file
diff --git a/__reports/geo-report.index.json b/__reports/geo-report.index.json
new file mode 100644
index 0000000..2a9c6e9
--- /dev/null
+++ b/__reports/geo-report.index.json
@@ -0,0 +1,500 @@
+{
+  "generated_at": "2025-09-13T22:02:29.058Z",
+  "metrics": {
+    "clusters": 3,
+    "suburbs": 121,
+    "adjacencyNodes": 121,
+    "orphanAdjacencyNodes": 0,
+    "degree": {
+      "min": 1,
+      "p25": 3,
+      "median": 4,
+      "p75": 5,
+      "p90": 6,
+      "max": 8,
+      "mean": 4.05
+    },
+    "meta": {
+      "generatedAt": "2025-09-13T21:36:52.005Z",
+      "coverageByCluster": {
+        "ipswich": 0,
+        "brisbane": 0,
+        "logan": 0
+      },
+      "timings": {
+        "prime_ms": 0,
+        "metrics_ms": 1.4,
+        "total_ms": 13.5
+      }
+    },
+    "top_hubs_per_cluster": [
+      {
+        "cluster": "ipswich",
+        "top": [
+          {
+            "slug": "ipswich",
+            "name": "Ipswich",
+            "degree": 7
+          },
+          {
+            "slug": "camira",
+            "name": "Camira",
+            "degree": 6
+          },
+          {
+            "slug": "goodna",
+            "name": "Goodna",
+            "degree": 6
+          },
+          {
+            "slug": "silkstone",
+            "name": "Silkstone",
+            "degree": 6
+          },
+          {
+            "slug": "bundamba",
+            "name": "Bundamba",
+            "degree": 5
+          },
+          {
+            "slug": "raceview",
+            "name": "Raceview",
+            "degree": 5
+          },
+          {
+            "slug": "booval",
+            "name": "Booval",
+            "degree": 4
+          },
+          {
+            "slug": "newtown",
+            "name": "Newtown",
+            "degree": 4
+          },
+          {
+            "slug": "springfield",
+            "name": "Springfield",
+            "degree": 4
+          },
+          {
+            "slug": "woodend",
+            "name": "Woodend",
+            "degree": 4
+          }
+        ]
+      },
+      {
+        "cluster": "brisbane",
+        "top": [
+          {
+            "slug": "jindalee",
+            "name": "Jindalee",
+            "degree": 8
+          },
+          {
+            "slug": "oxley",
+            "name": "Oxley",
+            "degree": 8
+          },
+          {
+            "slug": "anstead",
+            "name": "Anstead",
+            "degree": 7
+          },
+          {
+            "slug": "auchenflower",
+            "name": "Auchenflower",
+            "degree": 7
+          },
+          {
+            "slug": "indooroopilly",
+            "name": "Indooroopilly",
+            "degree": 7
+          },
+          {
+            "slug": "pullenvale",
+            "name": "Pullenvale",
+            "degree": 6
+          },
+          {
+            "slug": "richlands",
+            "name": "Richlands",
+            "degree": 6
+          },
+          {
+            "slug": "sumner",
+            "name": "Sumner",
+            "degree": 6
+          },
+          {
+            "slug": "brookfield",
+            "name": "Brookfield",
+            "degree": 5
+          },
+          {
+            "slug": "inala",
+            "name": "Inala",
+            "degree": 5
+          }
+        ]
+      },
+      {
+        "cluster": "logan",
+        "top": [
+          {
+            "slug": "waterford",
+            "name": "Waterford",
+            "degree": 6
+          },
+          {
+            "slug": "belivah",
+            "name": "Belivah",
+            "degree": 5
+          },
+          {
+            "slug": "crestmead",
+            "name": "Crestmead",
+            "degree": 5
+          },
+          {
+            "slug": "loganlea",
+            "name": "Loganlea",
+            "degree": 5
+          },
+          {
+            "slug": "springwood",
+            "name": "Springwood",
+            "degree": 5
+          },
+          {
+            "slug": "bannockburn",
+            "name": "Bannockburn",
+            "degree": 4
+          },
+          {
+            "slug": "beenleigh",
+            "name": "Beenleigh",
+            "degree": 4
+          },
+          {
+            "slug": "greenbank",
+            "name": "Greenbank",
+            "degree": 4
+          },
+          {
+            "slug": "hillcrest",
+            "name": "Hillcrest",
+            "degree": 4
+          },
+          {
+            "slug": "holmview",
+            "name": "Holmview",
+            "degree": 4
+          }
+        ]
+      }
+    ],
+    "cross_cluster_edges": 0,
+    "cluster_representatives": {
+      "ipswich": {
+        "adjacency_degree": "ipswich",
+        "alphabetical": "augustine heights",
+        "centroid": "ipswich"
+      },
+      "brisbane": {
+        "adjacency_degree": "indooroopilly",
+        "alphabetical": "anstead",
+        "centroid": "indooroopilly"
+      },
+      "logan": {
+        "adjacency_degree": "logan central",
+        "alphabetical": "bahrs scrub",
+        "centroid": "logan central"
+      }
+    },
+    "graph_components": {
+      "count": 55,
+      "largest_size": 48,
+      "largest_ratio": 0.277
+    },
+    "cluster_cohesion": [
+      {
+        "cluster": "ipswich",
+        "suburbs": 30,
+        "internalEdges": 38,
+        "crossEdges": 34,
+        "internal_ratio": 0.528
+      },
+      {
+        "cluster": "brisbane",
+        "suburbs": 48,
+        "internalEdges": 90,
+        "crossEdges": 48,
+        "internal_ratio": 0.652
+      },
+      {
+        "cluster": "logan",
+        "suburbs": 43,
+        "internalEdges": 40,
+        "crossEdges": 46,
+        "internal_ratio": 0.465
+      }
+    ],
+    "bridge_suburbs": [
+      {
+        "slug": "crestmead",
+        "degree": 5,
+        "cross": 4,
+        "cross_ratio": 0.8
+      },
+      {
+        "slug": "springwood",
+        "degree": 5,
+        "cross": 4,
+        "cross_ratio": 0.8
+      },
+      {
+        "slug": "camira",
+        "degree": 6,
+        "cross": 4,
+        "cross_ratio": 0.67
+      },
+      {
+        "slug": "jindalee",
+        "degree": 8,
+        "cross": 5,
+        "cross_ratio": 0.63
+      },
+      {
+        "slug": "brookfield",
+        "degree": 5,
+        "cross": 3,
+        "cross_ratio": 0.6
+      },
+      {
+        "slug": "raceview",
+        "degree": 5,
+        "cross": 3,
+        "cross_ratio": 0.6
+      },
+      {
+        "slug": "ipswich",
+        "degree": 7,
+        "cross": 4,
+        "cross_ratio": 0.57
+      },
+      {
+        "slug": "goodna",
+        "degree": 6,
+        "cross": 3,
+        "cross_ratio": 0.5
+      },
+      {
+        "slug": "waterford",
+        "degree": 6,
+        "cross": 3,
+        "cross_ratio": 0.5
+      },
+      {
+        "slug": "anstead",
+        "degree": 7,
+        "cross": 3,
+        "cross_ratio": 0.43
+      },
+      {
+        "slug": "indooroopilly",
+        "degree": 7,
+        "cross": 3,
+        "cross_ratio": 0.43
+      },
+      {
+        "slug": "belivah",
+        "degree": 5,
+        "cross": 2,
+        "cross_ratio": 0.4
+      },
+      {
+        "slug": "bundamba",
+        "degree": 5,
+        "cross": 2,
+        "cross_ratio": 0.4
+      },
+      {
+        "slug": "inala",
+        "degree": 5,
+        "cross": 2,
+        "cross_ratio": 0.4
+      },
+      {
+        "slug": "riverhills",
+        "degree": 5,
+        "cross": 2,
+        "cross_ratio": 0.4
+      },
+      {
+        "slug": "oxley",
+        "degree": 8,
+        "cross": 3,
+        "cross_ratio": 0.38
+      }
+    ]
+  },
+  "doctor": {
+    "report": {
+      "clusters": 3,
+      "suburbs": 121,
+      "edges": {
+        "directed": 490,
+        "undirected": 245,
+        "cross_cluster_ratio": 0
+      },
+      "asymmetry_edges": 0,
+      "cross_cluster_edges": 0,
+      "coords_coverage_pct": 0,
+      "coverage_by_cluster": {
+        "ipswich": 0,
+        "brisbane": 0,
+        "logan": 0
+      },
+      "cluster_coverage": {
+        "ipswich": 0,
+        "brisbane": 0,
+        "logan": 0
+      },
+      "hierarchy_rollup": {
+        "ipswich": 0,
+        "brisbane": 0,
+        "logan": 0
+      },
+      "graph_components": {
+        "count": 55,
+        "largest_size": 48,
+        "largest_ratio": 0.277,
+        "smallest": [
+          {
+            "size": 1,
+            "nodes": [
+              "springfield lakes"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "augustine heights"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "redbank plains"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "bellbird park"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "collingwood park"
+            ],
+            "is_island": false
+          }
+        ],
+        "unexpected_small": [
+          {
+            "size": 1,
+            "nodes": [
+              "springfield lakes"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "augustine heights"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "redbank plains"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "bellbird park"
+            ],
+            "is_island": false
+          },
+          {
+            "size": 1,
+            "nodes": [
+              "collingwood park"
+            ],
+            "is_island": false
+          }
+        ]
+      },
+      "asymmetry_examples": [],
+      "meta": {
+        "timings": {
+          "doctor_ms": 4.2
+        },
+        "schemaVersion": 1,
+        "hash": "2e35aa2881049a1f0a9625699b2dadf339c84409b78b1c0358d0885d80c1a0c8"
+      },
+      "autofix": {
+        "enabled": false
+      }
+    },
+    "thresholds": {
+      "minClusters": 1,
+      "requireSymmetry": true,
+      "minCoordsPct": 80,
+      "maxCrossClusterEdges": "Infinity",
+      "maxComponents": "Infinity"
+    },
+    "ok": false,
+    "failures": [
+      "coords_coverage_pct=0% < 80%"
+    ]
+  },
+  "baseline": {
+    "clusters": 3,
+    "suburbs": 344,
+    "adjacencyNodes": 344,
+    "orphanAdjacencyNodes": 0,
+    "degree": {
+      "min": 1,
+      "p25": 4,
+      "median": 5,
+      "p75": 6,
+      "p90": 8,
+      "max": 16,
+      "mean": 5.43
+    },
+    "graph_components": {
+      "count": 2,
+      "largest_size": 340,
+      "largest_ratio": 0.988
+    },
+    "meta": {
+      "generatedAt": "baseline-refresh",
+      "coverageByCluster": {
+        "ipswich": 1,
+        "brisbane": 1,
+        "logan": 1
+      }
+    }
+  }
+}
\ No newline at end of file
diff --git a/__reports/geo-strategy-coverage.json b/__reports/geo-strategy-coverage.json
new file mode 100644
index 0000000..7959772
--- /dev/null
+++ b/__reports/geo-strategy-coverage.json
@@ -0,0 +1,257 @@
+{
+  "summary": {
+    "total_exports": 35,
+    "uncovered": 35
+  },
+  "rows": [
+    {
+      "name": "getSafeCoverage",
+      "declared_in": [
+        "src/lib/coverage.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "coveredSuburbs",
+      "declared_in": [
+        "src/lib/coverage.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "isCovered",
+      "declared_in": [
+        "src/lib/coverage.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "coveredInCluster",
+      "declared_in": [
+        "src/lib/coverage.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getSuburbsForCluster",
+      "declared_in": [
+        "src/lib/coverage.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "enrichedClusters",
+      "declared_in": [
+        "src/lib/geoCompat.runtime.js",
+        "src/lib/geoCompat.runtime.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "adjacency",
+      "declared_in": [
+        "src/lib/geoCompat.runtime.js",
+        "src/lib/geoCompat.runtime.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "representativeOfClusterSync",
+      "declared_in": [
+        "src/lib/geoCompat.runtime.js",
+        "src/lib/geoCompat.runtime.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getBuildableSuburbsForService",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getAllServices",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getServiceCoverageStats",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "prettyServiceName",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "isServiceCovered",
+      "declared_in": [
+        "src/lib/links/buildable.ts",
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getServicesForSuburb",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getSameClusterSuburbs",
+      "declared_in": [
+        "src/lib/links/buildable.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getLocalGuidesLink",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getLocalGuidesLinks",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "asArray",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "toServiceHref",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getCrossServiceItemsForSuburb",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getRelatedServiceLinks",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "unslugToName",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "toServiceCards",
+      "declared_in": [
+        "src/lib/links/index.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "slugify",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getKnownSuburbSlugs",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "findClusterSlugForSuburb",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "inSameCluster",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getAllClusters",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "getSuburbsInCluster",
+      "declared_in": [
+        "src/lib/links/knownSuburbs.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "pickNearbyCoveredInSameClusterSync",
+      "declared_in": [
+        "src/lib/links/nearby.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "resolveSuburbDisplay",
+      "declared_in": [
+        "src/lib/suburbs/resolveDisplay.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "safeSuburbLabel",
+      "declared_in": [
+        "src/lib/suburbs/resolveDisplay.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "resolveSuburbDisplays",
+      "declared_in": [
+        "src/lib/suburbs/resolveDisplay.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "clearDisplayCache",
+      "declared_in": [
+        "src/lib/suburbs/resolveDisplay.ts"
+      ],
+      "test_refs": 0
+    },
+    {
+      "name": "coverageToMap",
+      "declared_in": [
+        "src/utils/_shape/coverageToMap.ts"
+      ],
+      "test_refs": 0
+    }
+  ]
+}
\ No newline at end of file
diff --git a/__reports/local-build-run-after-install.log b/__reports/local-build-run-after-install.log
new file mode 100644
index 0000000..3799d84
--- /dev/null
+++ b/__reports/local-build-run-after-install.log
@@ -0,0 +1,103 @@
+
+> ondlive-main@1.0.0 prebuild
+> node scripts/cleanup-strays.mjs && node scripts/expand-coverage.mjs && npm run guard:canonical && npm run lint:data && npm run lint:graph && node scripts/build-cross-service-map.mjs && npm run lint:adj && npm run routes:audit && node scripts/verify-blog-base.mjs
+
+No stray files to remove.
+Wrote src/data/serviceCoverage.json with 187 total entries.
+
+> ondlive-main@1.0.0 guard:canonical
+> node tools/guard-canonical-components.mjs
+
+✅ No shadow files for canonical components found.
+
+> ondlive-main@1.0.0 lint:data
+> tsx tools/validate-data.zod.ts
+
+validate-data.zod OK
+
+> ondlive-main@1.0.0 lint:graph
+> node tools/graph-sanity.mjs
+
+🔍 Checking adjacency vs cluster integrity...
+
+📊 Total clusters: 3
+📊 Total suburbs: 121
+📊 Adjacency entries: 121
+
+📊 Cluster breakdown:
+  ipswich: 30 suburbs, 30 with adjacency data
+  brisbane: 48 suburbs, 48 with adjacency data
+  logan: 43 suburbs, 43 with adjacency data
+
+✅ Graph data integrity OK: all adjacency nodes exist in clusters
+[crossMap] Wrote src/data/crossServiceMap.json with 121 suburbs.
+
+> ondlive-main@1.0.0 lint:adj
+> node tools/adjacency-symmetry.mjs
+
+adjacency-symmetry OK
+
+> ondlive-main@1.0.0 routes:audit
+> node scripts/audit-routes.mjs
+
+No route collisions.
+BLOG_BASE is default ("/blog/") — skipping verify.
+
+> ondlive-main@1.0.0 build
+> npm run guard:routes && npm run build:faqs && npm run verify:faqs && USE_NETLIFY=1 astro build && node scripts/guard-css.js && node scripts/css-guardrails.mjs && node scripts/audit-css-duplicates.mjs && node scripts/audit-css-budgets.mjs && GUARD_MODE=ci npm run guard:ci && node scripts/performance-guardian.mjs && node scripts/consolidate-ld.mjs && node scripts/audit-related-links.mjs && npm run validate:schema && npm run check:links && npm run build:report
+
+
+> ondlive-main@1.0.0 guard:routes
+> node scripts/guard-dynamic.mjs
+
+🛡️  Checking dynamic routes...
+
+📊 Found 3 dynamic page(s)
+
+✅ src/pages/blog/[cluster]/[slug].astro (17.5KB)
+   Params: filename=[cluster, slug] content=[]
+   Mode: SSG
+   Tracked: Yes
+
+✅ src/pages/blog/[cluster]/category/[category].astro (3.6KB)
+   Params: filename=[cluster, category] content=[]
+   Mode: SSG
+   Tracked: Yes
+
+✅ src/pages/services/[service]/[suburb].astro (17.5KB)
+   Params: filename=[service, suburb] content=[]
+   Mode: SSG
+   Tracked: Yes
+
+📊 Route Status Matrix:
+┌─────────────────────────────────────────────┬─────┬─────┬────────┬─────────┐
+│ File                                        │ SSG │ SSR │ Track  │ Status  │
+├─────────────────────────────────────────────┼─────┼─────┼────────┼─────────┤
+│ src/pages/blog/[cluster]/[slug].astro       │  ✓  │  ✗  │   ✓    │ OK      │
+│ src/pages/blog/[cluster]/category/[category │  ✓  │  ✗  │   ✓    │ OK      │
+│ src/pages/services/[service]/[suburb].astro │  ✓  │  ✗  │   ✓    │ OK      │
+└─────────────────────────────────────────────┴─────┴─────┴────────┴─────────┘
+
+📊 Summary: 3 files, 0 failures, 0 warnings
+
+✅ All dynamic routes look good
+
+> ondlive-main@1.0.0 build:faqs
+> node scripts/build-faqs-new.mjs
+
+[faqs] Wrote src/data/faqs.compiled.json and public/faqs.compiled.json
+
+> ondlive-main@1.0.0 verify:faqs
+> node scripts/ops/verify-faqs.mjs
+
+🔍 Verifying FAQ compilation and structure...
+✅ FAQ verification passed!
+   Suburbs: 8
+   Services: 3
+   Total questions: 5
+   Generated: 2025-09-13T11:41:46.229Z
+   Warnings: 16
+11:41:51 [@astrojs/netlify] Enabling sessions with Netlify Blobs
+EISDIR: illegal operation on a directory, read
+  Stack trace:
+
diff --git a/__reports/local-build-run.log b/__reports/local-build-run.log
new file mode 100644
index 0000000..656909f
--- /dev/null
+++ b/__reports/local-build-run.log
@@ -0,0 +1,59 @@
+
+> ondlive-main@1.0.0 prebuild
+> node scripts/cleanup-strays.mjs && node scripts/expand-coverage.mjs && npm run guard:canonical && npm run lint:data && npm run lint:graph && node scripts/build-cross-service-map.mjs && npm run lint:adj && npm run routes:audit && node scripts/verify-blog-base.mjs
+
+No stray files to remove.
+Wrote src/data/serviceCoverage.json with 187 total entries.
+
+> ondlive-main@1.0.0 guard:canonical
+> node tools/guard-canonical-components.mjs
+
+✅ No shadow files for canonical components found.
+
+> ondlive-main@1.0.0 lint:data
+> tsx tools/validate-data.zod.ts
+
+validate-data.zod OK
+
+> ondlive-main@1.0.0 lint:graph
+> node tools/graph-sanity.mjs
+
+🔍 Checking adjacency vs cluster integrity...
+
+📊 Total clusters: 3
+📊 Total suburbs: 121
+📊 Adjacency entries: 121
+
+📊 Cluster breakdown:
+  ipswich: 30 suburbs, 30 with adjacency data
+  brisbane: 48 suburbs, 48 with adjacency data
+  logan: 43 suburbs, 43 with adjacency data
+
+✅ Graph data integrity OK: all adjacency nodes exist in clusters
+[crossMap] Wrote src/data/crossServiceMap.json with 121 suburbs.
+
+> ondlive-main@1.0.0 lint:adj
+> node tools/adjacency-symmetry.mjs
+
+adjacency-symmetry OK
+
+> ondlive-main@1.0.0 routes:audit
+> node scripts/audit-routes.mjs
+
+node:internal/modules/esm/resolve:853
+  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
+        ^
+
+Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'globby' imported from /workspaces/July22/scripts/audit-routes.mjs
+    at packageResolve (node:internal/modules/esm/resolve:853:9)
+    at moduleResolve (node:internal/modules/esm/resolve:910:20)
+    at defaultResolve (node:internal/modules/esm/resolve:1130:11)
+    at ModuleLoader.defaultResolve (node:internal/modules/esm/loader:396:12)
+    at ModuleLoader.resolve (node:internal/modules/esm/loader:365:25)
+    at ModuleLoader.getModuleJob (node:internal/modules/esm/loader:240:38)
+    at ModuleWrap.<anonymous> (node:internal/modules/esm/module_job:85:39)
+    at link (node:internal/modules/esm/module_job:84:36) {
+  code: 'ERR_MODULE_NOT_FOUND'
+}
+
+Node.js v20.11.1
diff --git a/schemas/adj.config.schema.json b/schemas/adj.config.schema.json
new file mode 100644
index 0000000..8b7192a
--- /dev/null
+++ b/schemas/adj.config.schema.json
@@ -0,0 +1,22 @@
+{
+  "$schema": "http://json-schema.org/draft-07/schema#",
+  "$id": "adj.config.schema.json",
+  "type": "object",
+  "properties": {
+    "params": {
+      "type": "object",
+      "properties": {
+        "K_BASE": {"type": "integer", "minimum": 1},
+        "MAX_KM": {"type": "number", "minimum": 0},
+        "MAX_KM_EXT": {"type": "number", "minimum": 0},
+        "MIN_DEGREE": {"type": "integer", "minimum": 0},
+        "PCT_PRUNE": {"type": "number", "minimum": 0, "maximum": 100},
+        "MAX_CROSS_CLUSTER_PER_NODE": {"type": "integer", "minimum": 0},
+        "LOCALIZE": {"type": "boolean"}
+      },
+      "additionalProperties": false
+    },
+    "paths": {"type": "object"},
+    "policy": {"type": "object"}
+  }
+}
diff --git a/schemas/adjacency.build.schema.json b/schemas/adjacency.build.schema.json
new file mode 100644
index 0000000..9929f8a
--- /dev/null
+++ b/schemas/adjacency.build.schema.json
@@ -0,0 +1,18 @@
+{
+  "$schema": "http://json-schema.org/draft-07/schema#",
+  "$id": "adjacency.build.schema.json",
+  "type": "object",
+  "required": ["schemaVersion","generatedAt","params","nodes","degrees","components","edges","cross_cluster","distances"],
+  "properties": {
+    "schemaVersion": {"type": "integer"},
+    "generatedAt": {"type": "string"},
+    "params": {"type": "object"},
+    "nodes": {"type": "integer"},
+    "degrees": {"type": "object", "required": ["mean","min","max","histogram","isolates"]},
+    "components": {"type": "object", "required": ["count","largest_ratio"]},
+    "edges": {"type": "object", "required": ["undirected"]},
+    "cross_cluster": {"type": "object", "required": ["edges","ratio"]},
+    "distances": {"type": "object", "required": ["cutoff_km"]},
+    "qa": {"type": "object"}
+  }
+}

## package.json diff
diff --git a/package.json b/package.json
index 3d270d4..c12cee2 100644
--- a/package.json
+++ b/package.json
@@ -25,6 +25,24 @@
     "lint:geo:fix": "node scripts/lint-geo-neighbors.mjs --fix",
     "lint:graph": "node tools/graph-sanity.mjs",
     "report:geo": "node scripts/geo-report.mjs",
+    "geo:gate": "node scripts/geo/gate.mjs",
+    "geo:strategy:coverage": "node scripts/geo/strategy-coverage.mjs",
+    "geo:history": "node scripts/geo/history-archive.mjs",
+    "geo:metrics": "node scripts/geo/metrics.mjs",
+    "geo:doctor": "node scripts/geo/doctor.mjs",
+    "geo:diff": "node scripts/geo/diff.mjs",
+    "geo:produce": "npm run geo:metrics && (npm run geo:doctor || true) && (npm run geo:diff || true) && npm run geo:strategy:coverage",
+    "geo:gate:read": "node scripts/geo/gate.mjs --no-run",
+    "geo:full": "npm run geo:produce && npm run geo:gate:read && npm run geo:history",
+    "geo:hash": "node scripts/geo/hash-verify.mjs",
+    "geo:churn": "node scripts/geo/churn.mjs",
+    "geo:pr:summary": "node scripts/geo/pr-summary.mjs",
+    "geo:ci": "npm run geo:full && npm run geo:pr:summary && npm run geo:churn && npm run geo:hash",
+    "geo:stubs": "node scripts/geo/generate-missing-test-stubs.mjs",
+    "geo:adj:build": "node scripts/geo/build-adjacency.mjs",
+    "geo:adj:check": "node scripts/geo/build-adjacency.mjs --dry-run",
+    "geo:adj:validate": "node scripts/geo/validate-adjacency.mjs",
+    "geo:adj:full": "npm run geo:adj:build && npm run geo:adj:validate",
     "lint:buildable": "node tools/check-buildable.mjs",
     "lint:cross": "tsx tools/diff-cross-service.ts",
     "lint:data": "tsx tools/validate-data.zod.ts",
