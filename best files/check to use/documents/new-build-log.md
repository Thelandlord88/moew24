# New Build Log (Static Build Architecture) — 2025-08-24

Purpose: Concise, authoritative snapshot of everything the current build emits (what pages, why they exist, and which source/data/script files drive them). Replaces ad-hoc notes and supersedes the earlier mixed SSR + static approach. For a fully enumerated per-route listing see `build-list.md`; this document focuses on structured categories, provenance, and rationale.

---
## 1. High-Level Overview

The site now ships as a fully static Astro + Netlify build with:
- Canonical service, area, and blog routes pre-rendered.
- Pattern-based synonym redirects handled purely by static Netlify rules (no SSR endpoints).
- Deterministic JSON-LD (single emitter per page) with post-build hash capture for drift detection.
- Guard scripts enforcing internal link presence, redirect block integrity, legacy folder removal, schema validity, and absence of deprecated SSR synonym endpoints.

---
## 2. Page Inventory Summary (Counts)

| Category | Pattern / Example | Approx Count | Generation Mode | Notes |
|----------|-------------------|--------------|-----------------|-------|
| Root Landing | `/` | 1 | Static | Home marketing page |
| Core Utility | `/privacy`, `/terms`, `/gallery`, `/quote` | 4 | Static | Legal, gallery, lead capture |
| Sitemap | `/sitemap.xml` | 1 | Endpoint (Astro) | Dynamic XML output |
| Service Hubs | `/services/[service]/` | 3 | Static | One per service (bond, spring, bathroom) |
| Service × Suburb | `/services/[service]/[suburb]/` | 187 (total) | Static | Coverage-driven; majority bond-cleaning |
| Area Index | `/areas/` | 1 | Static | Lists clusters |
| Area Clusters | `/areas/[cluster]/` | 3 | Static | Ipswich, Brisbane, Logan |
| Area Suburb Pages | `/areas/[cluster]/[suburb]/` | ~180 | Static | Mirrors coverage for cluster browsing |
| Blog Root | `/blog/` | 1 | Static | Aggregated entry |
| Blog Cluster Indexes | `/blog/[cluster]/` | 3 | Static | Region-specific filtered lists |
| Blog Category Pages | `/blog/[cluster]/category/[category]/` | 15 (3×5) | Static | Cluster × category matrix |
| Blog Posts | `/blog/[cluster]/[slug]/` | 33 (11×3 clusters) | Static | Each post duplicated per canonical cluster context |
| Checklist Variant | `/services/bond-cleaning/[suburb]/checklist` | Subset | Static | Converted acceptance / long-form content |
| UI Sandbox (review) | `/ui/` | 1 | Static | Internal showcase (consider gating) |
| Redirect Rules | See `_redirects` | 1 block + patterns | Edge redirect | Includes pattern synonym lines + legacy canonicalization |

Total HTML pages (with JSON-LD) observed in build: 376
Pages with internal link audit coverage: 375 (home + all spokes, etc.)
Schema hash entries recorded: 376

---
## 3. Detailed Page Categories

### 3.1 Root & Core Utility
- Source: `src/pages/index.astro`, `privacy.astro`, `terms.astro`, `gallery.astro`, `quote.astro`.
- Why: Brand presence, legal compliance, conversion (quote form, gallery trust signals).
- Data Inputs: Minimal; uses site config (`siteConfig.ts`) & static content JSON (cards, FAQs).

### 3.2 Services
- Hub Pattern: `/services/[service]/` — `src/pages/services/[service]/index.astro`
  - Builds via `getStaticPaths()` enumerating `services.json`.
  - Purpose: Consolidated service overview + popular suburbs panel (top 3 coverage intersections).
- Spoke Pattern: `/services/[service]/[suburb]/` — `src/pages/services/[service]/[suburb].astro`
  - Paths generated from cartesian of services × coverage map (`serviceCoverage.json`).
  - Enrichments: Cross-service navigation (precomputed map), Related links guard, Acceptance content, Deterministic schema graph.
- Special: Checklist variant pages reuse the service layout; they appear where extended acceptance / checklist content is required.

### 3.3 Areas (Clusters)
- Patterns: `/areas/`, `/areas/[cluster]/`, `/areas/[cluster]/[suburb]/`
- Sources: `src/pages/areas/index.astro`, `src/pages/areas/[cluster]/index.astro`, nested suburb page.
- Data: `areas.clusters.json` (clusters + suburb arrays) acts as authoritative taxonomy.
- Why: Alternative discovery path (geo-first) improving internal link diversity and dwell time.

### 3.4 Blog
- Root: `/blog/` — cluster overview / general guides listing.
- Cluster Index: `/blog/[cluster]/` — region-specific filtered topics.
- Category Pages: `/blog/[cluster]/category/[category]/` — taxonomy slice per region.
- Posts: `/blog/[cluster]/[slug]/` — content contextualized by cluster; cluster alias redirect rules ensure canonical slug usage.
- Data: `topics.json` for post metadata; cluster resolution via `geoHandler`.
- Why: SEO authority building, localized relevance; replicating posts per cluster ensures internal linking parity and cluster-specific navigation context.

### 3.5 Redirects
- `public/_redirects` holds:
  - Legacy cluster / blog alias normalization: e.g., `%20` encodings & old naming patterns → canonical cluster.
  - Legacy service path canonicalization (`/services/:service/:cluster/:suburb/*` → `/services/:service/:suburb`).
  - Synonym pattern block (auto-managed) mapping search-intent variants (e.g., `/bond-cleaners/:suburb`) → canonical service pages.
- No SSR synonym endpoint files remain (guard enforced).

### 3.6 Support / Sandbox
- `/ui/` page: design / component playground (evaluate whether to exclude from production or disallow in `robots.txt`).

---
## 4. Data Sources & Purpose

| File | Purpose | Key Consumers |
|------|---------|---------------|
| `src/data/services.json` | Defines each service (slug, title, checklist) | Service hubs & spokes, schema builders |
| `src/data/serviceCoverage.json` | Service → list of suburb slugs | Static path generation for service spokes; tests sample coverage |
| `src/data/suburbs.json` | Curated suburb metadata | Popular areas snippet, potential future geo context |
| `src/content/areas.clusters.json` | Cluster → suburbs taxonomy | Area pages, cluster resolution, blog cluster iteration |
| `src/data/topics.json` | Blog topics/posts metadata | Blog root, cluster, category, post pages |
| `src/data/synonyms.map.json` | Alias service terms → canonical service slugs | Redirect generator & tests |
| `reviews` data (loader) | Consolidated customer review data | Service spokes schema (AggregateRating / Review nodes) |
| Various `faq.service-*.json` | Service-specific FAQs | Service hubs & selected spokes |

---
## 5. Build & Guard Scripts

| Script | Stage | Responsibility | Effect on Build Integrity |
|--------|-------|----------------|---------------------------|
| `expand-coverage.mjs` | Prebuild | Normalize/expand coverage map | Ensures no missing intended service pages |
| `build-cross-service-map.mjs` | Prebuild | Precompute cross-service navigation data | Deterministic nav (no runtime flakiness) |
| `generate-synonym-redirects.mjs` | Prebuild / manual | Insert pattern block into `_redirects` | One source of truth for synonym redirects |
| `verify-redirects-block.mjs` | Prebuild / CI | Assert pattern lines match map | Prevents drift or manual edits |
| `assert-no-ssr-synonym-pages.mjs` | Prebuild | Fail if deprecated SSR files exist | Enforces static approach |
| `assert-no-legacy-folders.mjs` | Prebuild | Prevent resurrection of legacy blog folders | Canonical cluster hygiene |
| `audit-routes.mjs` | Prebuild | Detect collisions/missing | Early failure signal |
| `consolidate-ld.mjs` | Postbuild | Merge stray JSON-LD scripts | Guarantees single `<script>` per page |
| `audit-related-links.mjs` | Postbuild | Enforce related links caps | UX relevance & SEO cleanliness |
| `check-internal-links.mjs` | Postbuild | Verify all internal anchors resolve | Blocks broken links deployment |
| `audit-internal-links.mjs` | Postbuild | Ensure each page has ≥1 internal link | Crawl depth & SEO guard |
| `audit-cross-links.mjs` | Postbuild | Validate cross-service link panel logic | Prevents empty or mis-targeted panels |
| `extract-ld-hashes.mjs` | Postbuild | Generate schema hash map | Enables drift detection & baselining |
| `schema-baseline.mjs` / `schema-diff.mjs` | Manual / CI | Manage and compare schema hash baselines | Detect unintended structured data changes |

---
## 6. Component & Utility Roles (Condensed)

| Area | Files | Why They Matter |
|------|-------|-----------------|
| Layouts | `MainLayout.astro`, `ServiceLayout.astro` | Unified head/meta & JSON-LD emission slot |
| Schema Builders | `seoSchema.js`, `SchemaGraph.astro` | Pure functions & single emitter; predictable graph |
| Navigation | `ServiceNav.astro`, `crossService.ts`, `serviceNav.adapter.ts` | Deterministic cross-service linking & popular suburbs |
| URL & Slug Utils | `paths.ts`, `url.ts`, `slugify.js`, `str.ts` | Centralizes path generation & normalization |
| Geo Logic | `geoHandler.ts`, `clusterMap.ts`, `repSuburb` helpers | Cluster resolution & representative suburb selection |
| Redirect Serving (dev) | `serve-with-redirects.mjs` | Local Netlify-style redirect emulation for E2E tests |
| Tests (E2E) | `synonym-redirects.spec.ts`, `redirects-legacy.spec.ts`, `nav-landmarks.spec.ts`, etc. | Guard core routing, accessibility, redirects |
| Tests (Unit) | `aliases.spec.ts`, `repSuburb.spec.ts` | Validate mapping & selection algorithms |

---
## 7. Dependency Flow (Conceptual)

Data JSON → Prebuild Scripts (coverage expansion, cross-service map, redirects) → Static Path Generation (Astro pages) → Layouts & Components (UI + Schema) → Postbuild Audits (links, schema, redirects) → Hash Baseline (optional CI drift detection).

Redirect logic is now entirely outside runtime code paths (static file + test harness), shrinking surface area for regressions.

---
## 8. Change Log vs Previous Architecture

| Aspect | Before | Now | Benefit |
|--------|--------|-----|---------|
| Synonym Redirects | SSR endpoints per alias (prerender=false) | Single static pattern block + generator | Smaller attack/config surface; testable offline; faster CI |
| Cross-Service Links | Runtime logic & potential empties | Prebuilt deterministic JSON map | Eliminates flakiness & random output |
| JSON-LD Emission | Mixed emitters in components | Single consolidated emitter + hash auditing | Predictable structure; drift detection |
| Redirect Testing | Partial / failing under static server (404) | Local Netlify-style redirect emulator + data-driven spec | Realistic 301 validation without SSR |
| Legacy Slug Hygiene | Stray empty alias folders existed | Guard ensures absence & static redirects enforce canonical | Prevents accidental reintroduction |
| Schema Drift Detection | Manual spot checks | Automated hash extraction & baseline diff | Faster detection of inadvertent changes |
| Internal Link Assurance | Present but subject to variability | Strict audits with deterministic panels | Stable SEO crawl equity |
| Build Guardrails | Disparate scripts | Cohesive pre/post pipeline with enforced order | Predictable, fail-fast build lifecycle |

---
## 9. Why This Setup Is Better

1. Single Source of Truth for Redirects: Alias→canonical map feeds generation & verification; no duplicated logic spread across SSR endpoints.
2. Deterministic Output: All cross-service + related links derived prebuild — zero runtime variance, dramatically reducing flaky tests.
3. Reduced Surface Area: Eliminating SSR synonym endpoints removes server path handling logic entirely, improving performance and security posture.
4. Faster CI & Local Feedback: Pattern-based redirect block shrinks `_redirects`, speeding up validation and reducing diff noise.
5. Schema Integrity: Central emission plus hash baselining exposes subtle structured data regressions early (before search index impact).
6. Strong SEO Guardrails: Mandatory internal link presence, related link caps, alias canonicalization, and robots disallowance for legacy/aliases preserve crawl budget and canonical focus.
7. Easier Onboarding: Clear separation (data → generation → pages → audits) with documented scripts and a smaller mental model for synonym handling.
8. Safer Refactors: Guard scripts (`assert-no-ssr-synonym-pages`, `assert-no-legacy-folders`, `verify-redirects-block`) block regressions at commit/build time.
9. Extensibility: Expanded/Pattern dual-mode generator enables future enumeration (if needed) without changing verification ethos (keeps pattern as contract).
10. Observability & Drift Detection: Schema hash + LD source reporting provide low-friction diagnostics after each build.

---
## 10. Future Opportunities
- Consider gating `/ui/` behind env or excluding from production sitemap.
- Integrate `schema:diff` into CI (non-blocking warnings initially) for tighter structured data governance.
- Add Lighthouse/A11y budgets for performance regression detection.
- Document explicit service coverage deltas (e.g., per-service page counts) via a small script emitting a coverage summary JSON.

---
## 11. Summary

The migration from scattered SSR synonym endpoints and mixed JSON-LD emission to a fully static, pattern-managed redirect and schema architecture has produced a leaner, faster, and more reliable build. Redirect logic is declarative and testable; page generation is data-driven; audits enforce SEO and UX invariants; and structured data drift can be programmatically detected. This holistic shift reduces operational risk, simplifies developer cognition, and positions the project for safer iteration and scaling.

> In short: fewer moving parts, stronger guarantees, clearer sources of truth.
