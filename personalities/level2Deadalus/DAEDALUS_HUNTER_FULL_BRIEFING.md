
# Daedalus & Hunter — Full Implementation Briefing (How & Why)

> **Audience:** Autonomous Agent implementing upgrades without human hand-holding.  
> **Prime Directive:** Use **Daedalus ideology** — prefer upstream fixes; make humans and machines more intelligent; keep every change **measurable, reversible, auditable**.  
> **Companion:** **Hunter** enforces evidence, eliminates failure classes, and blocks regressions.

---

## Table of Contents
1. Executive Summary
2. Core Ideology & Operating Rules
3. Repo Assumptions & Artifacts
4. Phase 1 — Data‑Change Incremental Builds (+ accurate `lastmod`)
5. Phase 2 — Data Coverage & Sanity Gate (Hunter)
6. Phase 3 — HTML/CSS/JS Size‑Budget Gate (Hunter)
7. Phase 4 — Policy Sweeper Integration + Decision Records
8. Phase 5 — Service‑Specific Policy Overrides
9. Phase 6 — Anchor‑Text Intelligence for Internal Links
10. Phase 7 — Schema Breadth: Breadcrumbs & Collections
11. Phase 8 — Dataset Versioning, ETag/Last‑Modified for `/api/agents/*`
12. Phase 9 — Prefetch Top Neighbors (UX)
13. Phase 10 — “Machine Facts” Evidence Panel (non‑prod)
14. Phase 11 — Canary/Shadow Builds
15. Phase 12 — Guardrailed Autopilot
16. Phase 13 — Observability Dashboard
17. Release Workflow (End‑to‑End)
18. Rollback & Recovery
19. Appendices (Templates, Configs, Checklists)

---

## 1) Executive Summary (Why This Matters)

- **Speed:** Rebuild only what changed; CI becomes 2–5× faster. Sitemaps reflect *true* freshness so crawlers focus on changed URLs.
- **Coverage:** Link policy becomes **fair** (low Gini), **local** (shorter avg km), and **cluster‑pure** — tail suburbs don’t get starved.
- **Correctness:** Structured data is validated with gates; data coverage is enforced; page size budgets prevent silent bloat.
- **Clarity:** Every policy tweak writes a **Decision Record** (DR). You can approve/rollback by reading one file.
- **Leverage:** One graph powers SEO, UX, and ops. HTML for people; JSON‑LD & APIs for agents.

---

## 2) Core Ideology & Operating Rules

- **Evidence over assumptions.** Every proposal ships with **metrics & diffs**.
- **Upstream first.** Fix data/policy before touching generators; never hand‑edit outputs.
- **Determinism.** Same inputs ⇒ same artifacts. Hash datasets; pin versions.
- **Human & machine parity.** HTML matches what JSON‑LD & APIs assert.
- **Reversibility.** Small, measured deltas; always leave a rollback trail.
- **Hunter’s law.** If it failed once, it becomes a **named failure class** with a gate.

---

## 3) Repo Assumptions & Artifacts

- **Config:** `daedalus.config.json` (policies, services, CLI metadata).  
- **Data:** `src/data/areas.clusters.json`, `areas.adj.json`, `suburbs.meta.json`, `adjacency.distances.json`.
- **Plugins:** `scripts/daedalus/plugins/*.mjs` (Levels 1–4 + `08-validate-schema.mjs` already added).
- **Tools:** `scripts/daedalus/tools/policy-sweeper.mjs` (v2 with HTML report).
- **APIs:** `/api/agents/*`, `/api/systems/*` (personalities; manifest).
- **Reports:** `__reports/daedalus/*` (metrics, issues, sweeps, schema.validation).
- **CLI scripts:** `package.json` with `daedalus:*` scripts.

> **Agent autonomy:** Choose sequence; ensure each phase ends with reports + DRs.

---

## 4) Phase 1 — Data‑Change Incremental Builds (+ accurate `lastmod`)

### Why
Stop rebuilding untouched pages; produce honest `lastmod` → crawlers prioritize changed URLs.

### What
- Create `.daedalus/state.json` caching **file hashes** and **per‑target hashes**.
- During build:
  1) Hash inputs (`src/data/*`, policy config).  
  2) For each target (service×suburb), compute a **target signature** from the inputs it depends on (cluster id, adjacency, meta slice, policy).  
  3) If unchanged since last run → **skip page emission**; else rebuild.
- Set sitemap `lastmod` using the **max source hash time** per URL.

### Where (files to add/extend)
- `scripts/daedalus/util/hash.mjs` (stable sha256 helper)
- `scripts/daedalus/cli.mjs` (load/save state; skip unchanged)
- `scripts/daedalus/plugins/04-write-pages.mjs` (respect “skip” flag)
- `scripts/daedalus/plugins/07-sitemap-robots.mjs` (use target lastmod)

### Acceptance
- Rebuild touches only changed pages (verify by count).  
- `public/sitemap-daedalus-*.xml` shows realistic `lastmod` deltas.  
- `__reports/daedalus/metrics.json` contains: `rebuiltCount`, `skippedCount`, `avgBuildMsPerTarget`.

---

## 5) Phase 2 — Data Coverage & Sanity Gate (Hunter)

### Why
Schema quality depends on inputs. Missing coords/postcodes cause invalid JSON‑LD and broken locality metrics.

### What
Add `05a-validate-data.mjs` **before** JSON‑LD emission:
- Warn/Error if:  
  - coords coverage < threshold (e.g., 90%)  
  - postcode missing for any active suburb  
  - adjacency islands without whitelist  
  - self‑distance anomalies or impossible distances
- Output `__reports/daedalus/data.validation.json`.

### Where
- `scripts/daedalus/plugins/05a-validate-data.mjs` (new)
- `scripts/daedalus/pipelines/geo-build.mjs` — insert after `02-derive-graph`

### Acceptance
- Gate fails on poor coverage; gives actionable suburb lists.  
- JSON‑LD validator (08) sees near‑zero errors after data fix.

---

## 6) Phase 3 — HTML/CSS/JS Size‑Budget Gate (Hunter)

### Why
Silent bloat tanks Core Web Vitals and crawl budget.

### What
Add `06a-size-budgets.mjs` **after write**:
- Read built files in `public/services/*/*/index.html` (+ assets if any).  
- Enforce thresholds from `daedalus.config.json`:
  ```json
  { "budgets": { "htmlKb": 85, "cssKb": 30, "jsKb": 0 } }
  ```
- Fail or warn when exceeded; write `__reports/daedalus/size.budgets.json`.

### Where
- `scripts/daedalus/plugins/06a-size-budgets.mjs` (new)
- Config: `daedalus.config.json` → `budgets` block

### Acceptance
- Build blocks on regressions; reports show top offenders and diffs.

---

## 7) Phase 4 — Policy Sweeper Integration + Decision Records

### Why
Policy tuning must be **measured** and **explainable**.

### What
- **Already present:** tiny sweeper with JSON/MD/HTML output.  
- **Extend:** `scripts/daedalus/cli.mjs sweep` subcommand (or via npm scripts).  
- **Auto‑DR:** On `sweep --apply` create `decisions/YYYY‑MM‑DD-<slug>.md`:
  - **Assumptions/Evidence/Decision/Actions/Risks/Next checks**
  - Include top table from `policy.sweep.md` and the chosen variant.

### Where
- `scripts/daedalus/cli.mjs` (add `sweep` + `sweep --apply`)
- `decisions/` folder (git‑tracked)

### Acceptance
- Each policy change PR includes a DR and sweeper artifacts.

---

## 8) Phase 5 — Service‑Specific Policy Overrides

### Why
“Bond cleaning” wants ultra‑local links; other services may want reach.

### What
- Config supports `policies.byService[serviceId]`:
  ```json
  { "policies": {
    "scoring": { "weightCluster": 1.1, "weightDistance": 1.3, "distanceScaleKm": 8, "weightReciprocalEdge": 0.7, "weightHubDamping": 0.6 },
    "byService": {
      "bond-cleaning": { "distanceScaleKm": 6, "weightDistance": 1.4, "globalInboundCap": 10 }
    }
  }} 
  ```
- Merge order: `global → byService → CLI flags`.

### Where
- `05-internal-links.mjs` (read effective policy per target service)
- Sweeper accepts `--service=<id>`

### Acceptance
- Sweeper shows better fairness/locality for targeted services without hurting global breadth.

---

## 9) Phase 6 — Anchor‑Text Intelligence for Internal Links

### Why
Better anchors improve relevance & UX without extra pages.

### What
- Add `anchorTemplates` per relation type:
  ```json
  { "anchorTemplates": {
     "sameCluster": ["{service} near {suburb}", "Local cleaners in {suburb}"],
     "bridgeCluster": ["Explore {service} in {neighbor}"],
     "hubToTail": ["Closest option: {neighbor}"]
  }}
  ```
- Selection rule: shorter distance ⇒ “near” templates; cross‑cluster ⇒ “explore”.  
- Keep a small set (3–5) to avoid over‑randomization.

### Where
- `05-internal-links.mjs` (choose text when writing link slots)
- No change to JSON‑LD (anchors are HTML concern)

### Acceptance
- Pages show varied, descriptive anchors; no repetition errors.

---

## 10) Phase 7 — Schema Breadth: Breadcrumbs & Collections

### Why
Stronger site graph signals; better machine navigation.

### What
- **BreadcrumbList** on service×suburb pages:
  - `Home → Service → Suburb`
- `/service-areas/` emits **CollectionPage** with `hasPart` clusters; each cluster emits a `Place` with stable `@id`.

### Where
- `03-emit-jsonld.mjs` — extend per page; extend `/service-areas/` generator
- Keep `Dataset` + `DataDownload` references intact

### Acceptance
- Rich results tests show valid BreadcrumbList; validator stays green.

---

## 11) Phase 8 — Dataset Versioning & Caching

### Why
Bots and tools should avoid re‑downloading unchanged graphs.

### What
- Compute `dataset.version` and `dataset.sha256` from input hashes.  
- Serve `/api/agents/*` with `ETag` and `Last-Modified`.  
- Add `version` to `Dataset` JSON‑LD and append `?v=<hash>` to `DataDownload` URLs if desired.

### Where
- `/api/agents/*.json.js` (set headers; include version fields)
- `03-emit-jsonld.mjs` (include `version`, keep `distribution` stable)

### Acceptance
- Conditional GETs (If‑None‑Match) return 304 for unchanged; Dataset shows version.

---

## 12) Phase 9 — Prefetch Top Neighbors

### Why
Snappier navigation from a suburb page.

### What
- In the HTML `<head>`, emit up to 2 neighbors as:
  ```html
  <link rel="prefetch" href="/services/{svc}/{neighbor}/">
  ```

### Where
- `04-write-pages.mjs` (head injection) or the Astro template

### Acceptance
- Lighthouse shows reduced TTI on neighbor clicks; no excessive prefetching.

---

## 13) Phase 10 — “Machine Facts” Evidence Panel (non‑prod)

### Why
Authors debug faster when the page explains itself.

### What
- Collapsible panel (staging only) listing: cluster, neighbors, scores, coordinates.  
- Toggle via env flag `DAEDALUS_EVIDENCE=1`.

### Where
- Astro page template with conditional render

### Acceptance
- Panel renders in staging; absent in production builds.

---

## 14) Phase 11 — Canary/Shadow Builds

### Why
Try risky policies on 10% of targets before rollout.

### What
- CLI flag `--canary=0.1` picks deterministic subset by hashing suburb id.  
- Build and write reports side‑by‑side: `__reports/daedalus/canary/*` vs baseline.  
- Promote if sweeper metrics improve and gates stay green.

### Where
- `scripts/daedalus/cli.mjs` (target selection & routing to temp outDir)
- Reports aggregator

### Acceptance
- Canary reports show clear comparison; promotion/abort rule documented in DR.

---

## 15) Phase 12 — Guardrailed Autopilot

### Why
Gradual self‑tuning without self‑harm.

### What (rules)
- Consider auto‑apply only when:
  - **All** gates green (data, schema, sizes).
  - Sweeper improves **≥2 of 3** metrics (fairness/locality/purity) and regresses none beyond tolerance.
  - Change within **±5%** bounds of current weights.
  - **Hunter sign‑off** is recorded (DR updated).

### Where
- `cli.mjs autopilot` subcommand; or GitHub Action with checks

### Acceptance
- Auto‑PRs with DRs; easy revert button; no silent merges.

---

## 16) Phase 13 — Observability Dashboard

### Why
Close the loop; end debates with graphs.

### What
- Static dashboard in `__reports/ui/index.html` plotting:
  - inbound Gini, avg km, cluster purity, indexation breadth, tail entries, build counts
- Read JSON from `__reports/daedalus/*` to avoid a server.

### Where
- `scripts/daedalus/tools/build-dashboard.mjs` (simple HTML+JS)

### Acceptance
- Dashboard opens locally; trends readable across builds.

---

## 17) Release Workflow (End‑to‑End)

1. **Fetch & hash inputs** → update state.  
2. **Data gate (05a)** → block on coverage/sanity failures.  
3. **Policy sweeper (optional)** → consider small variant; if adopting, create DR.  
4. **Generate** (skip unchanged targets).  
5. **Validate schema (08)**; **size budgets**.  
6. **Emit sitemaps/robots** (use `lastmod`).  
7. **Publish APIs** (`/api/agents/*` with ETag/Last‑Modified).  
8. **Reports** (metrics, schema, sweeps).  
9. **Review** DR + reports → merge or roll back.  
10. **Monitor** dashboard; compare week‑over‑week trends.

---

## 18) Rollback & Recovery

- Revert DR PR → restores previous policy.  
- Re‑run build with previous state file (deterministic).  
- If data corruption: restore from prior `src/data/*` snapshot; rebuild; validator must pass 0 errors.

---

## 19) Appendices

### A) Decision Record Template
```
# Decision Record — Policy Change
Date: YYYY‑MM‑DD
Change: Describe the weight/cap deltas
Assumptions:
Evidence: (paste from policy.sweep.md/json)
Decision:
Actions:
Risks:
Next checks: (what we’ll measure next build)
```

### B) Size Budgets Config
```json
{
  "budgets": {
    "htmlKb": 85,
    "cssKb": 30,
    "jsKb": 0
  }
}
```

### C) Canary Selection (Deterministic)
```
subset = hash(suburbId) % 1000 < floor(1000 * canaryFraction)
```

### D) Policy Weights Cheat‑Sheet
- **weightCluster**: higher → more intra‑cluster links (risk: echo chambers)
- **weightDistance** & **distanceScaleKm**: higher/shorter scale → more local (risk: isolation)
- **weightReciprocalEdge**: boosts two‑way links (risk: ringiness)
- **weightHubDamping**: penalizes hubs (risk: too strong → starved hubs)
- **globalInboundCap**: fairness cap (risk: too low → under‑link central nodes)

### E) KPI Targets (initial)
- Inbound **Gini ≤ 0.30**
- **Avg km** 4–8 (inner metro), 8–15 (outer)
- **Cluster purity ≥ 0.75**
- **Schema errors = 0**, **coverage ≥ 90%** coords
- **No size budget violations**

### F) Agent Operating Notes
- Prefer config & data edits; avoid code forks unless a new generic capability is added.  
- Every PR: include **reports paths** and (if policy changed) a **DR**.  
- When in doubt: run a **canary**; let Hunter decide with evidence.

---

**End of Briefing — Build boldly, measure always, and keep everything reversible.**
