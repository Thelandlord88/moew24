---
title: Suburbs Dataset & Local Council Mapping
description: Source-of-truth explanation for generated suburb pages, their council (cluster) mapping, why and how we generate them, coordinate rationale, troubleshooting, and FAQs.
status: draft
updated: 2025-09-16
---

# Suburbs / Local Council Overview

This document explains:

1. WHAT suburbs we generate (the "page universe") and how they map to local councils.
2. WHY we generate and store them (business, SEO, data quality & product reasons).
3. HOW the pipeline derives, validates, and exports them (inputs → transformations → outputs).
4. HOW coordinates (`lat`,`lng`) are used and why 100% coordinate coverage matters.
5. TROUBLESHOOTING & diagnostic commands.
6. FORWARD QUESTIONS you have not (yet) asked but should have answers for.

> NOTE: Terminology – we treat a "cluster" in code as the implementation unit that (currently) aligns 1:1 with a Local Government Area (LGA) / council region. If that ever diverges (e.g. nested or micro-clusters), this doc must be updated.

---

## 1. Councils / Clusters

Current top-level clusters (from `data/areas.extended.clusters.json`):

| Cluster Slug | Interpreted Council (LGA)        | Notes |
|--------------|-----------------------------------|-------|
| `brisbane`   | Brisbane City Council             | Largest set; some adjacency-only slugs still unclustered. |
| `ipswich`    | City of Ipswich                   | 100% coordinate coverage. |
| `logan`      | Logan City Council                | 100% coordinate coverage. |

"Suburbs" in the system = the union of cluster suburb lists + any additional slugs referenced by adjacency / coverage / meta (some may not yet be formally assigned to a cluster → reported as `adjacency_not_in_clusters`).

## Contracts & Invariants (must hold)

- **Slug format:** `^[a-z0-9]+(?:-[a-z0-9]+)*$` (kebab-case, lowercase, ASCII). Validators fail CI on violations.
- **Adjacency symmetry:** Graph is undirected. Doctor enforces & can auto-fix reciprocal edges; self-loops removed.
- **Coordinates:** 100% coverage per active cluster (gate threshold) unless explicitly waived.
- **Promotions:** Only rendered if target has a page; virtual-only counted via `promotionsDiscarded`.
- **Universes:** Every artifact declares `meta.universe` (`full`, `pages`, `clusters`).
- **Versioning:** Reports include `schemaVersion` + content hash for drift and reproducibility.
- **Diversity definition:** 0 for 0–1 anchors; (0,1] for >1 anchors based on token collision probability.
- **Primary cap & ordering:** Controlled by config (cluster-first ordering, cross-cluster limit, primaryMax, minPrimaryPerPage with sparse exemption).

### Universe Distinctions
| Universe | Description | File | Purpose |
|----------|-------------|------|---------|
| Full Graph | All slugs appearing in adjacency build (incl. unclustered) | `__reports/adjacency.build.json` | Structural health & graph metrics. |
| Page Universe | Subset with approved tiers (core/expansion) & coverage | `src/gen/geoPageContext.ts` / `__reports/geo-linking.summary.json` | Actual pages that render internal links. |
| Cluster Defined | Slugs explicitly in clusters file | `data/areas.extended.clusters.json` | Governance: coverage & membership. |

---

## 2. Why We Generate These Suburbs

| Goal | Benefit |
|------|---------|
| Local SEO authority | Dense, contextually-relevant internal link mesh among geographically proximate suburbs signals topical depth & service relevance. |
| Crawl efficiency | Predictable, bounded link sets prevent random high-degree link sprawl; improves discoverability for fresh pages. |
| Expansion roadmap | "Promotion pressure" & unclustered high‑degree nodes highlight where to invest in new pages/content next. |
| Governance & QA | Automated symmetry, coverage, component, mismatch, and diversity checks reduce manual audits. |
| Risk isolation | Dividing the geo system into data → doctor → context → gate isolates failure domains and keeps regressions explainable. |
| Analytics & personalization (future) | Clean coordinate & cluster model enables proximity-based modules (e.g., “nearby suburbs”, radius filters, service density scoring). |

We store coordinates so we can **(a)** sanity‑check geometry (no orphan cluster far away), **(b)** enable future geographic queries (distance / bounding boxes), **(c)** allow dynamic expansions (radius-limited candidate pages), and **(d)** differentiate true cross-cluster borders from accidental long-range bridges.

---

## 3. How They Are Generated (Pipeline)

```
Raw Inputs                     Processing / Validation                    Outputs
-----------                    -----------------------                    -----------------------------
data/adjacency.json   --->  doctor.mjs (symmetry, edges, comps)  --->  __reports/geo-doctor.json
data/areas.extended... --->  cluster membership validator        --->  warnings / gate decisions
data/serviceCoverage.json --> coverage expansion (prebuild)      --->  set of candidate page slugs
src/data/suburbs.meta.json -> tier filter (core/expansion)       --->  page-universe filter
config/anchor.templates... -> page-context template hashing     --->  linkVariants (deterministic)
__reports/geo-linking.promotions.json (optional) -> page-context -> promotions (ONLY if target has page)
```

Key generator: `geo_linking_pack/scripts/geo/page-context.mjs`

Responsibilities:
1. Filter adjacency neighbors into primary / secondary respecting cluster preference & cross-cluster cap.
2. Add promotions ONLY if the candidate has a live page (never 404)—virtual-only are counted as `promotionsDiscarded`.
3. Pick anchor templates deterministically (hash-based) to avoid churn in diffs.
4. Compute anchor text diversity (empty → 0, single anchor → 0, variety → (0,1]).
5. Emit per-page stats (effectivePrimary, diversity) and global aggregates.

Doctor (`scripts/geo/doctor.mjs`) adds structural health:
* Symmetry (or writes auto-fixed artifact if enabled).
* Component count & size distribution.
* Cross-cluster ratio (global + per-cluster involvement counts).
* Mismatches (`clusters_not_in_adjacency`, `adjacency_not_in_clusters`).
* Timing buckets (profiling for regression monitoring).

Gate (`scripts/geo/gate.mjs`) enforces policy:
* Severity floors (diff metrics).
* Per-cluster coordinate coverage & optional hierarchy thresholds.
* Cross-cluster ratio thresholds.
* Mismatch gating (configurable fail/warn).
* Strategy coverage (tests vs exported functions).
 * (Future) Promotion pressure thresholds.

Linking gate (`geo_linking_pack/scripts/geo/linking_gate.mjs`) enforces linking-specific fairness (promoted share, cross-cluster promoted ratio, anchor diversity, min primary). 

---

## 4. Coordinates & Their Role

Coordinates are **not** for rendering a map (yet) but are integral to:

| Aspect | Usage |
|--------|-------|
| Coverage % gating | Clusters must exceed a minimum coordinate coverage (100% currently). |
| Plausibility checks | Detect outlier nodes far from cluster centroid for data hygiene. |
| Future radius-based features | Precompute nearby candidate suburbs beyond edge-only adjacency. |
| Cross-cluster classification | Distinguish legitimate border edges from accidental long-range links (future improvement). |

If a suburb lacks coordinates it drags cluster coverage below thresholds → gate fail (or warning if configured). Keep 100% coverage to simplify reasoning.

---

## 5. Promotion Logic (Current State)

| Stage | Behavior |
|-------|----------|
| Candidate scoring (promotions file) | Can list virtual or existing pages as helpful neighbors. |
| Rendering in page-context | Only includes promoted slugs with existing pages; others counted in `promotionsDiscarded`. |
| Metrics | `promoted` (rendered count) vs `promotionsDiscarded` (latent demand). |
| Governance | High discarded counts indicate content debt (future gate condition). |

This prevents generating links to non-existent pages while preserving *signal* about where coverage gaps are.

### Example Per-Page Context Snippet

```json
{
	"tier": "core",
	"neighborsPrimary": ["springfield", "springfield-lakes", "camira"],
	"neighborsPrimaryPromoted": [],
	"promotionsDetail": [
		{ "slug": "ripley", "score": 0.82, "degree": 9, "virtualOnly": true, "targetHasPage": false }
	],
	"promotionsDiscarded": 1,
	"anchorDiversity": 0.78,
	"effectivePrimary": 3
}
```

### Policy Knobs (Illustrative `geo.policy.json` Excerpt)

```json
{
	"crossCluster": { "maxRatioWarn": 0.02, "maxRatioError": 0.05 },
	"perCluster": {
		"brisbane": { "minCoordsPct": 100 },
		"ipswich": { "minCoordsPct": 100 },
		"logan": { "minCoordsPct": 100 }
	},
	"mismatches": {
		"failOnClustersNotInAdjacency": true,
		"failOnAdjacencyNotInClusters": false,
		"ignore": { "clusters_not_in_adjacency": [], "adjacency_not_in_clusters": [] }
	},
	"linking": {
		"promotions": { "maxPagesWithDiscardWarn": 10, "maxPagesWithDiscardFail": 999999 },
		"fairness": {
			"minAnchorDiversity": 0.55,
			"maxPromotedShareWarn": 0.5,
			"maxPromotedShareFail": 0.67,
			"maxPromotedCrossClusterRatio": 0.35
		}
	}
}
```

---

## 6. Troubleshooting Guide

| Symptom | Likely Cause | Command / Fix |
|---------|--------------|---------------|
| `adjacency_not_in_clusters` spikes | New adjacency build introduced unassigned suburbs | `node scripts/geo/reconcile-clusters.mjs --json` then update clusters file. |
| `clusters_not_in_adjacency` non-empty | Cluster file lists orphan suburb | Remove or add to adjacency input; re-run doctor. |
| `hierarchy_rollup` shows 0 for a cluster | Hierarchy file missing that slug or slug mismatch | Verify slug casing in `areas.hierarchical.clusters.json`. |
| Gate fails `minPrimaryPerPage` | Too few neighbors with pages | Add content coverage or adjust promotions; verify promos not discarded. |
| High promoted share warning | Over-reliance on promotions | Create pages for top discarded promotion targets. |
| Diversity < threshold | Template repetition or low primary count | Add more anchor templates or ensure neighbor set size adequate. |
| Cross-cluster ratio jump | Erroneous long-distance edges | Inspect last adjacency diff; prune or cap distance in builder. |
| Sudden degree inflation | Adjacency builder parameter drift | Diff `__reports/adjacency.build.json` vs previous commit; revert noise edges.
| Doctor runtime regressions | Larger input or inefficient normalization | Profile timing buckets; optimize slugify or adjacency normalization. |

### Core Commands
```
# Structural health
node scripts/geo/doctor.mjs --json | jq '.report.edges, .report.mismatches'

# Gate (policy & health) with JSON summary
node scripts/geo/gate.mjs --json

# Linking fairness gate
node geo_linking_pack/scripts/geo/linking_gate.mjs

# Page context regeneration
node geo_linking_pack/scripts/geo/page-context.mjs

# Reconcile unclustered suburbs (proposals)
node scripts/geo/reconcile-clusters.mjs --json

# Quick promotion pressure (if health reporter present)
node scripts/geo/report-linking-health.mjs
```

### Reports to Open First

| File | Purpose |
|------|---------|
| `__reports/geo-doctor.json` | Structural graph health, mismatches, timings |
| `__reports/geo-linking.summary.json` | Per-page linking stats (diversity, promotionsDiscarded) |
| `__reports/geo-linking.health.md` | Reviewer-friendly delta snapshot |
| `__reports/geo-tests.summary.md` | Which geo tests ran & pass/fail |
| `__reports/adjacency.build.json` | Raw degrees, components baseline |

---

## 7. Frequently Anticipated Questions (FAQ)

**Q: Why not render promotions to non-existent pages to encourage exploration?**  
Because 404/soft-404 link targets harm crawl quality & user trust; we surface demand via `promotionsDiscarded` instead.

**Q: Why is diversity 0 for single-anchor pages?**  
No variety exists; treating that as “max diversity” (1.0) would mask thin anchor sets.

**Q: Why do some adjacency nodes lack clusters?**  
They are either (a) prospective future coverage, (b) noise needing pruning, or (c) awaiting reconciliation. Track them deliberately; don’t silently ignore.

**Q: Can we merge clusters later?**  
Yes—cluster is just a grouping key. Update clusters file + regenerate; doctor & gate will recompute ratios accordingly.

**Q: How do we keep diffs stable?**  
Deterministic template hashing + sorted, slugified adjacency + symmetry autofix ensure reproducible outputs.

**Q: What is an acceptable cross-cluster ratio?**  
Current ratios <1% are excellent; >5% merits review. Policy thresholds enforce this.

**Q: Where do tiers influence linking?**  
`src/data/suburbs.meta.json` → page-context filters to allowed tiers; promotions cannot “resurrect” an excluded tier.

**Q: How do we test this without a heavyweight framework?**  
Plain Node specs under `tests/geo/` plus the unified `scripts/geo/test-runner.mjs` produce self-contained JSON & MD summaries.

**Q: How to adopt a new suburb?**  
Add to coverage (or meta if tier assignment needed) → ensure adjacency edges exist → run doctor → confirm no mismatches → generate page-context.

---

## 8. Forward-Looking Enhancements

| Idea | Value |
|------|-------|
| Degree distribution & percentile stats in doctor | Faster anomaly detection. |
| Border-edge classification (touching vs bridging) | More nuanced cross-cluster gating. |
| Automated promotion adoption report | Visibility into content debt burn-down. |
| Radius-based candidate generator (augment adjacency) | Reduces manual adjacency curation. |
| Visual graph snapshot export (JSON → PNG) | PR reviewers can see topology trends. |
| Promotion pressure gate (warn on rising discarded pages) | Prevent silent content debt expansion. |
| Degree distribution (p50/p90/p99) surfaced in summary | Faster anomaly triage. |

---

## 9. Glossary
| Term | Meaning |
|------|---------|
| Primary neighbors | Direct same-page links (cluster-biased) chosen from adjacency. |
| Secondary neighbors | Non-page or overflow neighbors kept for analytics. |
| Promotion | Virtual candidate link considered to supplement sparse pages (only rendered if target page exists). |
| Effective primary | Real primary count + rendered promotions. |
| Promotion pressure | Aggregate discarded virtual promotion count (content gap indicator). |
| Cross-cluster ratio | Undirected cross-cluster edges ÷ total undirected edges. |

---

## 10. Quick Execution Cheat Sheet
```
# Full geo cycle (metrics, doctor, diff, strategy coverage, gate)
npm run geo:full

# Link context only
node geo_linking_pack/scripts/geo/page-context.mjs

# Geo tests (summary MD + JSON)
npm run test:geo

# Inspect a single page
node scripts/geo/inspect.mjs --slug=brassall
```

---

## 11. Update Checklist (When Data Model Changes)
Before merging changes that alter adjacency or clusters:

1. Run `doctor.mjs` and confirm mismatches ≤ previous (unless intentional).
2. Regenerate page context; check `promotionsDiscarded` trend.
3. Run `npm run test:geo` (all green).
4. Update this doc if: cluster definitions, promotion logic, diversity semantics, or gating thresholds changed.
5. Include a short PR note: summary of graph diffs (edges +/- , ratio changes, degree changes).
6. If mismatches changed materially: attach reconciliation proposals or add to ignore list intentionally.
7. Add / refresh `__reports/geo-linking.health.md` for reviewer context.

---

_Generated / maintained alongside the geo Phase 2 hardening initiative._
