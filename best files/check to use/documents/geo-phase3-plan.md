---
title: Geo Phase 3 – Suburb Registry, Backlog Intelligence & Governance Expansion
description: Full technical design & implementation runbook for elevating coordinates -> page intent, registry-driven universes, promotion adoption loop, backlog prioritization, and strengthened CI governance.
status: draft
updated: 2025-09-16
owner: geo-platform
---

# Geo Phase 3 – Technical Plan

> Goal: Eliminate ambiguity between "we know a suburb exists" vs "we intend (or no longer intend) to publish a page" while converting latent signal (promotions, orphans, coverage gaps) into a governed backlog + automated adoption lifecycle.

## 0. Executive Summary

Phase 3 formalizes a Suburb Registry as the **authoritative intent layer**. Coordinates & adjacency are no longer an implicit promise; instead each suburb has a lifecycle state: `published`, `staged`, `candidate`, `deprecated`, or `ignored`. We add:

| Capability | Outcome |
|------------|---------|
| Registry file + schema | Stable contract for page intent + auditing & diff semantics. |
| Page-universe derivation from intent | Deterministic, documented, testable page selection (replaces implicit coverage-only logic). |
| Backlog scoring (promotion pressure + graph centrality) | Prioritized list of next suburbs to publish – data > intuition. |
| Promotion adoption loop | High-pressure candidates escalate automatically (optional gating or alert). |
| Governance gates on orphans & deprecated usage | CI fails before drift accumulates. |
| Health metrics (registry counts, backlog delta) | Trend visibility in PR & history. |
| Deprecation workflow | Safe removal path (no accidental reintroduction / broken links). |

Rollout is incremental (registry read-only shadow → authoritative) to avoid destabilizing existing page-context generation.

---
## 1. Data Model & Contracts

### 1.1 Registry File
Path: `src/data/suburbs.registry.json`
```
{
  "$schema": "./schemas/suburbs.registry.schema.json",
  "version": 1,
  "updated": "2025-09-16T00:00:00Z",
  "suburbs": {
    "springfield": { "state": "published",  "tier": "core",       "first_seen": "2024-12-10T09:03:00Z" },
    "springfield-lakes": { "state": "published", "tier": "core" },
    "ripley": { "state": "candidate",  "tier": "expansion", "signals": { "promotion_pressure": 11 } },
    "karalee": { "state": "staged", "tier": "expansion", "staged_at": "2025-09-10T11:20:00Z" },
    "some-old": { "state": "deprecated", "tier": "support", "deprecated_at": "2025-08-05T12:00:00Z", "reason": "merged-into:new-slug" },
    "airport-test": { "state": "ignored", "tier": "support", "reason": "operational area not for landing pages" }
  }
}
```

### 1.2 States (Closed Set)
| State | Meaning | Allowed Transitions |
|-------|---------|--------------------|
| `candidate` | Known; not yet prioritized for build | → staged, published, ignored, deprecated |
| `staged` | Content scaffold / preview; not live in prod nav (optional) | → published, deprecated |
| `published` | Live page in page universe | → deprecated |
| `deprecated` | Historical; remove links & redirects process | → (terminal) |
| `ignored` | Known but explicitly out-of-scope (e.g., industrial zone) | → candidate, deprecated |

### 1.3 Invariants (CI-Enforced)
- Every suburb in clusters *must* appear in registry unless in an ignore allowlist.
- `published` must have coordinates + appear in adjacency.
- `deprecated` must NOT appear in page universe, nor as primary link target; can persist temporarily in adjacency until cleanup step.
- `promotionsDiscarded` referencing a `published` page ⇒ logic bug (fail gate).
- `promotion_pressure` (derived) only accumulated for `candidate` / `staged`, not `published`.
- Timestamps are ISO 8601 UTC; absence is permitted for legacy migration.

---
## 2. Derived Universes (Authoritative Definition)

| Universe | Selection Logic | Producing Script | Artifact |
|----------|-----------------|------------------|----------|
| Full Graph | All adjacency nodes | `build-adjacency.mjs` | `__reports/adjacency.build.json` |
| Intent Universe | All registry suburbs (any state) | `registry-health.mjs` | `__reports/geo-registry.json` |
| Page Universe | Registry.state ∈ { published, staged } | `page-context.mjs` (modified) | `__reports/geo-linking.summary.json` |
| Backlog Universe | Registry.state = candidate | `report-backlog.mjs` | `__reports/geo-backlog.json` |

Page-context currently uses `(coverage ∩ allowed tiers)`. Phase 3 replaces *or augments* with `(registry.state in allowedStates) ∩ (tier in allowedTiers)`.

Feature flag for transition:
```
process.env.GEO_USE_REGISTRY === '1'
```

---
## 3. Scoring & Backlog Prioritization

### 3.1 Inputs
| Signal | Source | Normalization |
|--------|--------|--------------|
| Promotion pressure | `promotionsDiscarded` occurrences referencing slug across pages | min-max 0..1 (cap at P95) |
| Graph centrality (degree) | adjacency undirected degree | log-scale & min-max |
| Cross-cluster bridge relevance | # cluster-unique edges (optional) | boolean / small weight |
| Cluster coverage gap | (cluster published count / cluster total) inverted | 0..1 |
| Time in candidate | `now - first_seen` | days / max_days cap |

### 3.2 Formula
```
score = w_promo * promo_norm
      + w_degree * degree_norm
      + w_gap * coverage_gap_norm
      + w_age * age_norm
      + w_bridge * bridge_flag

Default Weights (tunable):
w_promo=4, w_degree=2, w_gap=2, w_age=1, w_bridge=0.5
```

### 3.3 Output Structure
`__reports/geo-backlog.json`
```
{
  "generatedAt": "...",
  "weights": { ... },
  "candidates": [
    { "slug": "ripley", "score": 0.87, "components": { "promo": 0.95, "degree": 0.6, "gap": 0.7, "age": 0.2, "bridge": 0 }, "state": "candidate", "cluster": "ipswich" },
    ...
  ],
  "top": ["ripley","flinders-view", ...]
}
```

### 3.4 Adoption Thresholds
- Auto-suggest escalate to `staged` if `promo_norm >= 0.9 OR score >= 0.8` for >= 2 consecutive runs.
- Gate warning if *any* candidate stays above score 0.85 for > N days (`N=30`).

---
## 4. Promotion Adoption Loop

1. Page-context records `promotionsDiscarded` by page.
2. Aggregator (`promotions-aggregate.mjs`) builds per-slug pressure counts.
3. Backlog scorer normalizes & ranks.
4. If threshold met, add entry to `__reports/geo-adoption.suggestions.json`:
```
{ "slug": "ripley", "action": "stage", "reason": "promotion_pressure_high", "score": 0.87 }
```
5. Gate optionally fails if suggestions ignored for X days (opt-in: `policy.adoption.enforce=true`).

---
## 5. Deprecation Workflow

| Step | Action | Automation |
|------|--------|------------|
| 1 | Mark registry.state = deprecated; add `deprecated_at` | Manual edit + schema validation |
| 2 | Gate warns if any incoming primary link remains | linking gate cross-check |
| 3 | Remove from coverage file (if present) | Manual or script |
| 4 | After 7 days with zero links | adjacency prune script removes edges |
| 5 | Optionally keep redirect mapping | route config / redirects file |

Gate fails if a deprecated suburb still appears in page-context after grace period.

---
## 6. Schema Additions

### 6.1 `suburbs.registry.schema.json` (excerpt)
```
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["suburbs"],
  "properties": {
    "version": { "type": "integer" },
    "suburbs": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "required": ["state","tier"],
        "properties": {
          "state": { "enum": ["candidate","staged","published","deprecated","ignored"] },
          "tier": { "enum": ["core","expansion","support"] },
          "first_seen": { "type": "string", "format": "date-time" },
          "deprecated_at": { "type": "string", "format": "date-time" },
          "reason": { "type": "string" },
          "signals": { "type": "object", "additionalProperties": true }
        }
      }
    }
  }
}
```

---
## 7. CI / Gate Extensions

### 7.1 New Validations
| Check | Gate | Behavior |
|-------|------|----------|
| Orphan coordinates (registry missing) | registry gate | fail |
| Published missing coordinates | registry gate | fail |
| Deprecated still in page universe | linking gate | fail after grace |
| High-pressure candidate unaddressed | adoption gate | warn/fail (config) |
| Registry drift (hash changes) | gate | show delta summary |

### 7.2 Files Emitted
| Artifact | Purpose |
|----------|---------|
| `__reports/geo-registry.json` | Registry + counts + hash |
| `__reports/geo-backlog.json` | Ranked backlog candidates |
| `__reports/geo-adoption.suggestions.json` | Escalation recommendations |
| `__reports/geo-registry.health.md` | Human summary |

### 7.3 Gate Policy Additions (`geo.policy.json`)
```
"registry": {
  "graceDaysDeprecated": 7,
  "maxHighPressureAgeDays": 30,
  "adoption": { "enforce": false }
},
"adoption": {
  "scoreStage": 0.8,
  "promoNormStage": 0.9
}
```

---
## 8. Script Inventory (New / Modified)

| Script | New? | Description |
|--------|------|-------------|
| `scripts/geo/migrate-registry.mjs` | New | Seed registry from existing coverage/meta. |
| `scripts/geo/validate-registry.mjs` | New | Enforce invariants (orphans, published vs coords). |
| `scripts/geo/registry-health.mjs` | New | Emit `__reports/geo-registry.json` & MD. |
| `scripts/geo/promotions-aggregate.mjs` | New | Aggregate discarded promotion counts. |
| `scripts/geo/report-backlog.mjs` | New | Score + output backlog. |
| `scripts/geo/adoption-suggest.mjs` | New | Generate adoption suggestions. |
| `scripts/geo/prune-deprecated.mjs` | New | Remove adjacency edges post grace period. |
| `geo_linking_pack/scripts/geo/page-context.mjs` | Mod | Use registry for page universe (flagged). |
| `scripts/geo/doctor.mjs` | Mod | Add `registry_counts` summary. |
| `scripts/geo/gate.mjs` | Mod | Extend gating stages for registry + adoption. |

---
## 9. Incremental Rollout Plan

| Phase | Action | Risk Mitigation |
|-------|--------|-----------------|
| 0 | Create registry (shadow) + validation (non-blocking) | No functional change; compare counts. |
| 1 | Add doctor `registry_counts` | Observability before gating. |
| 2 | Introduce backlog scoring + MD (non-blocking) | Validate scoring sanity manually. |
| 3 | Switch page-context behind `GEO_USE_REGISTRY=1` in CI preview | Toggle revertable. |
| 4 | Enable gating (orphans / published missing coords) as warnings | Soft rollout. |
| 5 | Promote warnings → failures | After stability window (>= 1 week). |
| 6 | Enable adoption suggestions display (non-enforcing) | Team review. |
| 7 | Optionally enforce adoption (if backlog stagnates) | Config switch. |

Rollback: unset `GEO_USE_REGISTRY`, revert gate policy entries, remove adoption enforcement.

---
## 10. Testing Strategy

### 10.1 Unit / Fixture Tests
| Test | Fixture | Assertion |
|------|---------|-----------|
| Registry parse | minimal + invalid state | schema validation fails on wrong state |
| Orphan detection | coords > registry | orphan list non-empty |
| Backlog scoring scaling | synthetic promo counts | monotonic ordering by promo pressure |
| Adoption threshold | candidate with high score persists 2 runs | suggestion emitted |
| Deprecation grace | deprecated with lingering link | gate fails post-grace |

### 10.2 Integration
1. Run full pipeline with registry disabled & enabled; diff page-context size (expected minimal change until states edited).
2. Add candidate → ensure not in page universe; stage → appears; deprecate → removed after grace.
3. Promotion discard injection → backlog reorder stable.

### 10.3 Determinism Checks
Hash backlog output (IDs + scores) stable given identical inputs.

---
## 11. Metrics & Observability Additions

| Metric | Source | Purpose |
|--------|--------|---------|
| `registry_counts.{published,staged,candidate,deprecated,ignored}` | doctor / registry-health | Track expansion progress. |
| `backlog.top_n` | backlog report | Monitor if same slugs persist (stagnation). |
| `adoption.suggestions` count | adoption-suggest | Ensures loop productive. |
| `orphans.count` | validate-registry | Should trend → 0. |
| `deprecated.linked` | linking gate | Detect incomplete cleanup. |

Add a historical archive job (append snapshot of registry counts + backlog top 10 to `__history/registry.jsonl`).

---
## 12. Risk Analysis & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Registry drift out-of-sync with coverage | Misreported page universe | Make registry authoritative; coverage becomes advisory. |
| Over-aggressive adoption enforcement | Premature page creation workload | Start with suggest-only; escalate manually. |
| Score gaming (promo pressure inflated) | Misprioritization | Cap promo component & include multi-signal blend. |
| Backlog stagnation | Unused framework | Track age-in-top10; raise alert if > N days. |
| Deprecation link leakage | 404 risk | Gate hardened to fail after grace. |

---
## 13. Open Questions (Pre-Answered)

| Question | Proposed Answer |
|----------|-----------------|
| Multiple services (e.g., cleaning vs gardening) differing coverage? | Registry stays service-agnostic; per-service overlays may filter published subset. |
| Regional expansions (new cluster) mid-flight? | Add cluster with zero published; backlog scorer weights its coverage_gap high to prioritize early pages. |
| Performance concerns with scoring? | O(#suburbs) with simple maps; negligible at current scale (< 2k). |
| How to sunset registry v1 schema? | Bump `version`, add `migrations/registry.v1->v2.mjs`. |
| Need audit of who changed states? | Optionally append git commit hash + author into `signals.last_state_change`. |

---
## 14. Implementation Checklist (Chronological)

1. [ ] Add schema + empty registry (shadow) & migration script.
2. [ ] Add registry validation (non-blocking) + doctor counts.
3. [ ] Add promotions aggregate + backlog scorer.
4. [ ] Add adoption suggestions (JSON + MD) & test fixtures.
5. [ ] Modify page-context (flagged) to use registry.
6. [ ] Add gating for orphans / published w/o coords (warn).
7. [ ] Enable staging path & stage a sample suburb.
8. [ ] Switch gating to fail for orphans after stability window.
9. [ ] Add depreciation scenario + prune script.
10. [ ] Turn on optional adoption enforcement (decision-based). 
11. [ ] Documentation update (suburbs-overview + README). 
12. [ ] Historical archiving for counts & backlog top10.

---
## 15. Sample Commands (Phase 3 Tools)
```
# Create initial registry from existing data
node scripts/geo/migrate-registry.mjs --write

# Validate invariants
node scripts/geo/validate-registry.mjs --json

# Generate backlog & suggestions
node scripts/geo/promotions-aggregate.mjs && node scripts/geo/report-backlog.mjs && node scripts/geo/adoption-suggest.mjs

# Regenerate page context using registry
GEO_USE_REGISTRY=1 node geo_linking_pack/scripts/geo/page-context.mjs

# Doctor + gate (with registry metrics)
node scripts/geo/doctor.mjs --json | jq '.report.registry_counts'
node scripts/geo/gate.mjs --json
```

---
## 16. Future Extensions (Post Phase 3)

| Feature | Rationale |
|---------|-----------|
| Distance-based dynamic adjacency augmentation | Reduce manual adjacency curation for new regions. |
| Weighted anchor template rotation via engagement metrics | Improve CTR & internal link effectiveness. |
| Geospatial clustering (DBSCAN or H3 cells) to propose new clusters | Automate early cluster definitions. |
| API endpoint exposing backlog JSON to internal dashboards | Visibility for content ops. |
| ML scoring for conversion potential (tie into business metrics) | Prioritize pages with higher ROI probability. |

---
## 17. Glossary (Phase 3 Additions)
| Term | Definition |
|------|------------|
| Registry | Authoritative mapping suburb slug → intent state & metadata |
| Promotion Pressure | Count of times a suburb appears as discarded promotion candidate across pages |
| Adoption Suggestion | Automated recommendation to escalate candidate → staged/published |
| Orphan | Suburb with coordinates / cluster membership but no registry entry |
| Backlog Score | Composite score ranking candidate suburbs by multi-signal importance |

---
## 18. Final Notes
The registry approach enforces *explicit intent* over *implicit inference*. This lowers cognitive load, improves auditability, and converts organic signal (promotions, gaps) into a structured, trackable roadmap for geographic expansion.

_End of Phase 3 Technical Plan._

---

## 19. Front-End (Astro) Integration & Props Model (Added Post-Review)

### 19.1 Goals
1. Make page rendering consume a **single canonical props object** derived from registry + page-context.
2. Support incremental adoption: existing pages remain unaffected until `GEO_USE_REGISTRY=1` is globally enabled or per-build.
3. Expose backlog/adoption hints to templates without creating runtime coupling (keep static export deterministic).

### 19.2 Proposed Export Surfaces
Add `src/gen/geoRegistryPages.ts` (generated when registry enabled):
```ts
// Auto-generated (Phase 3)
export type RegistryPageEntry = {
  slug: string;
  state: 'published' | 'staged';
  tier: 'core' | 'expansion' | 'support';
  cluster: string|null;
  firstSeen?: string;
  stagedAt?: string;
  adoption?: { score: number; promotionPressure: number };
};
export const REGISTRY_PAGES: RegistryPageEntry[] = [/* sorted by cluster, then slug */];
```

`page-context.mjs` will optionally enrich each `GeoPageCtx` with:
```ts
registry: { state: 'published' | 'staged'; tier: string; adoptionScore?: number }
```

### 19.3 Astro Usage Pattern
Inside an Astro collection or dynamic `[slug].astro` route:
```ts
import { GEO_PAGE_CTX } from '../gen/geoPageContext';
import { REGISTRY_PAGES } from '../gen/geoRegistryPages';

export async function getStaticPaths() {
  return REGISTRY_PAGES.filter(p => p.state === 'published').map(p => ({ params: { slug: p.slug } }));
}

export async function get({ params }) {
  const ctx = GEO_PAGE_CTX[params.slug];
  if(!ctx) return { body: '404', status: 404 };
  return { props: { geo: ctx } };
}
```

### 19.4 Feature Flags & Fallback
| Flag | Behavior |
|------|----------|
| `GEO_USE_REGISTRY=0` | Continue using historic coverage+tiers selection; `REGISTRY_PAGES` not emitted. |
| `GEO_USE_REGISTRY=1` | Use registry states; fail if required generated file missing. |
| `GEO_REGISTRY_WARN_ONLY=1` | Log mismatches instead of failing page build (transitional). |

### 19.5 Build Performance Consideration
Static path generation now iterates `REGISTRY_PAGES` (size = published + staged). At current scale (< 500) negligible. Add soft budget: warn if > 3000 published (action: introduce pagination / on-demand ISR style approach if platform migrates to adapter supporting it).

### 19.6 SSR / Edge Future Compatibility
If moving to partial SSR, emit a lean JSON index: `public/geo/registry-index.json` containing only essential fields for client-side search modules; keep heavy analytics (promotion detail) server-only.

---
## 20. Upstream Strategic Extensions (Forward-Looking)

| Theme | Extension | Rationale |
|-------|-----------|-----------|
| Content Ops | Auto-open issue / ticket when adoption suggestion persists 3 runs | Ensures backlog movement. |
| Personalization | Track link click events keyed by neighbor slug (privacy-safe aggregated) to feed template CTR weighting | Promote effective anchors. |
| Geospatial Quality | Introduce distance sanity: fail if edge distance > configurable km threshold (except allowlist bridges) | Prevent accidental far links. |
| Search UX | Expose registry search API (local JSON) for user suburb finders | Improves navigation & conversion. |
| Multi-Service Scaling | Per-service overlays referencing the *same* registry states but tagging service compatibility | Avoid duplicating intent across verticals. |
| Data Provenance | Embed upstream source (e.g. ABS code) in registry entry signals meta | Future auditing / third-party enrichment. |

---
## 21. Performance & Budgets

| Component | Budget | Measurement Source |
|-----------|--------|--------------------|
| `doctor.mjs` total | < 120ms local | `report.meta.timings.doctor_ms` |
| `page-context` generation | < 200ms | Add timing field `meta.timings.pageContext_ms` |
| Backlog scoring | < 50ms | `__reports/geo-backlog.json.meta.timings.scoring_ms` |
| Registry parse + validation | < 40ms | `registry-health.mjs` timings |

Fail soft (warn) above budgets; allow policy escalation.

---
## 22. Error Modes & Fallback Strategies

| Failure Mode | Detection | Fallback | Escalation |
|--------------|-----------|----------|------------|
| Registry JSON malformed | JSON.parse error | Abort CI (exit 2) | Manual fix; cannot proceed. |
| Missing registry (flag enabled) | File not found | Fail gate | Add migration script step. |
| Orphan published (no coords) | validate-registry | Fail gate | Provide removal or add coords. |
| Deprecated still linked | linking_gate check | Fail after grace | Run prune script, re-gen context. |
| Adoption suggestions file missing | adoption-suggest script skip | Continue (warn) | Ensure script part of pipeline. |
| Score normalization divide-by-zero | Candidate set empty | Return empty backlog | None needed. |
| Promotions count regression (sudden drop) | Backlog diff > threshold | Warn (potential data wipe) | Inspect promotions aggregator history. |

---
## 23. Migration Playbook (Detailed)

| Step | Command | Expected Artifact | Rollback |
|------|---------|------------------|----------|
| 1 Seed registry | `node scripts/geo/migrate-registry.mjs --write` | `suburbs.registry.json` | Delete file, rerun. |
| 2 Shadow health | `node scripts/geo/registry-health.mjs --json` | `__reports/geo-registry.json` | Ignore file. |
| 3 Add doctor counts | `node scripts/geo/doctor.mjs` | `report.registry_counts` | Revert doc patch. |
| 4 Enable backlog | `node scripts/geo/report-backlog.mjs` | `__reports/geo-backlog.json` | Remove script. |
| 5 Toggle registry use | `GEO_USE_REGISTRY=1 node geo_linking_pack/scripts/geo/page-context.mjs` | Page universe stable | Set flag 0. |
| 6 Turn on warnings | `node scripts/geo/gate.mjs` | coverage / orphan warnings | Disable policy entries. |
| 7 Fail enforcement | Adjust policy -> fail | Gate failure if issues | Revert policy. |

---
## 24. Telemetry & Feedback Loop (Optional Phase 3.5)

Instrumentation suggestions (deferred until privacy/legal cleared):
1. Add data-attribution `data-geo-anchor="{from}:{to}:{templateId}"` on rendered links.
2. Lightweight client script batches click counts (hourly) → local aggregated log.
3. Offline job merges counts and updates a `template_ctr` histogram influencing future template selection (tie-break when diversity equal).

No runtime ML—just heuristic weighting (e.g., template weight = sqrt(CTR)).

---
## 25. Astro Props: Example End-to-End Object

```json
{
  "slug": "ripley",
  "tier": "expansion",
  "cluster": "ipswich",
  "registry": { "state": "candidate", "adoptionScore": 0.82 },
  "neighborsPrimary": ["springfield", "springfield-lakes", "karalee"],
  "neighborsPrimaryPromoted": [],
  "promotionsDiscarded": 3,
  "anchorDiversity": 0.91,
  "linkVariants": [ { "neighbor": "springfield", "text": "Cleaning in springfield — book today", "templateId": "nearby-1" } ]
}
```

---
## 26. Open Questions Added (Post Review)

| Question | Proposed Handling |
|----------|-------------------|
| Should staged pages be indexable? | Default: add `<meta robots="noindex">` until published. |
| How to version anchor templates for A/B? | Append `templateVersion` field; maintain mapping in generated context. |
| Multi-region timezones for timestamps? | Store UTC only; render locale-specific in UI if needed. |
| Access control for registry edits? | Enforce CODEOWNERS + optional signing commit hook (future). |
| Partial cluster onboarding? | Allow cluster with 0 published; backlog weights coverage gap high. |

---
## 27. Implementation Delta Summary (New vs Original Plan)
Added sections: 19–26 (Astro integration, strategic extensions, performance budgets, error modes, migration playbook, telemetry, props example, extra open questions). No breaking changes; enriches specificity and front-end contract.

