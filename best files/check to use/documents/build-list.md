# Build List & Page Architecture

Date: 2025-08-24

Purpose: Comprehensive inventory of every page (route) we build or serve (static, SSR redirect, or legacy placeholder), naming rationale, generation logic, and connected source files (UI → data → utilities). Use this to maintain a clean IA, prevent accidental route bloat (e.g., unwanted clusters like `brisbane-west`), and drive deprecation/redirect tasks.

---
## Legend
- Type: `static` (fully pre-rendered at build), `endpoint` (SSR TypeScript endpoint), `redirect` (static Netlify rule), `legacy` (candidate for removal), `dynamic-param` (parameterized pattern).
- Status Flags: `KEEP`, `REVIEW`, `REMOVE`, `MIGRATE`.
- Canonical Pattern Notation: `[]` = dynamic segment.

---
## 1. Core Marketing Pages (Static)
| Route | Type | Source | Rationale | Status |
|-------|------|--------|-----------|--------|
| `/` | static | `src/pages/index.astro` | Primary landing / brand introduction | KEEP |
| `/privacy` | static | `src/pages/privacy.astro` | Legal requirement | KEEP |
| `/terms` | static | `src/pages/terms.astro` | Legal requirement | KEEP |
| `/gallery` | static | `src/pages/gallery.astro` | Social proof / visual trust | KEEP |
| `/quote` | static | `src/pages/quote.astro` | Lead gen conversion point | KEEP |
| `/sitemap.xml` | endpoint | `src/pages/sitemap.xml.ts` | SEO discoverability | KEEP |

## 2. Service Hub Pages
Pattern: `/services/[service]/`
| Pattern | Type | Source | Build Logic | Naming Logic | Status |
|---------|------|--------|-------------|--------------|--------|
| `/services/[service]/` | static dynamic-param | `src/pages/services/[service]/index.astro` | `getStaticPaths()` iterates `services.json` | Slug matches canonical service keyword (consistent with search intent) | KEEP |

Notes:
- Title/description conditional for spring-cleaning (bespoke copy) else generic pattern.
- Popular Areas list limited to top 3 intersect of coverage + known suburbs.

## 3. Service × Suburb Pages
Pattern: `/services/[service]/[suburb]/`
| Pattern | Type | Source | Build Logic | Naming Logic | Status |
|---------|------|--------|-------------|--------------|--------|
| `/services/[service]/[suburb]/` | static dynamic-param | `src/pages/services/[service]/[suburb].astro` | Nested loops over `services.json` × coverage map (fallback all suburbs when coverage missing) | Suburb slug = lowercased hyphenated suburb name; service slug stable | KEEP |

Special Behaviors:
- Legacy cluster URL form `/services/:service/:cluster/:suburb` 301 handled in frontmatter logic.
- JSON-LD single emitter via `<Schema>` with aggregated review nodes.
- Cross-service navigation & popular suburbs computed statically from prebuilt JSON maps.

## 4. Area Cluster Pages
Pattern: `/areas/[cluster]/`
| Pattern | Type | Source | Build Logic | Naming Logic | Status |
|---------|------|--------|-------------|--------------|--------|
| `/areas/` | static | `src/pages/areas/index.astro` | Lists clusters from `areas.clusters.json` | Path root describing function | KEEP |
| `/areas/[cluster]/` | static dynamic-param | `src/pages/areas/[cluster]/index.astro` | `getStaticPaths()` enumerates clusters | Cluster slug from curated JSON (geo grouping) | KEEP |
| `/areas/[cluster]/[suburb]/` | static dynamic-param | `src/pages/areas/[cluster]/[suburb]/index.astro` | Static paths from cluster suburb list | Suburb slugs local to cluster; reuse canonical suburb slug to avoid duplicates | KEEP |

## 5. Blog Pages
Pattern roots: `/blog/`, `/blog/[cluster]/`, `/blog/[cluster]/category/[category]/`, `/blog/[cluster]/[slug]/`
| Pattern | Type | Source | Build Logic | Naming Logic | Status |
|---------|------|--------|-------------|--------------|--------|
| `/blog/` | static | `src/pages/blog/index.astro` | Clusters from `areas.clusters.json` | Root blog index | KEEP |
| `/blog/[cluster]/` | static dynamic-param | `src/pages/blog/[cluster]/index.astro` | Similar cluster enumeration | Localized blog index | KEEP |
| `/blog/[cluster]/category/[category]/` | static dynamic-param | `src/pages/blog/[cluster]/category/[category].astro` | Categories per cluster (source TBD) | Category slug from curated taxonomy | KEEP |
| `/blog/[cluster]/[slug]/` | static dynamic-param | `src/pages/blog/[cluster]/[slug].astro` | Post frontmatter (not shown here) | Slug matches post file slug for stable linking | KEEP |

### Blog Legacy / Unwanted Folders
| Route Folder | Contents | Issue | Recommendation | Status |
|--------------|----------|-------|----------------|--------|
| `/blog/brisbane-west/` | (empty) | Unwanted legacy cluster placeholder | Remove folder + add (or retain) redirect/410 policy | REMOVE |
| `/blog/brisbane_west/` | (empty) | Snake_case duplicate risk | Remove folder; guard against snake_case variants | REMOVE |
| `/blog/ipswich-region/` | (empty) | Legacy alias style (`-region`) | Remove folder; ensure redirect rule exists | REMOVE |

Action: These empty folders currently do nothing but risk accidental static generation later. Removing eliminates noise and accidental linking. Add or retain explicit `_redirects` lines if historical links existed.

## 6. Synonym Redirect Endpoints (SSR currently)
| Pattern | Type | Source | Target Canonical Logic | Recommendation |
|---------|------|--------|------------------------|----------------|
| `/bond-cleaners/[suburb]/` | endpoint | `src/pages/bond-cleaners/[suburb].ts` | 301 → `/services/bond-cleaning/[suburb]/` | Migrate to static redirect rule generation |
| `/end-of-lease-cleaning/[suburb]/` | endpoint | `src/pages/end-of-lease-cleaning/[suburb].ts` | 301 → bond-cleaning service + suburb | Migrate |
| `/exit-clean/[suburb]/` | endpoint | `src/pages/exit-clean/[suburb].ts` | 301 → bond-cleaning | Migrate |
| `/house-cleaning/[suburb]/` | endpoint | `src/pages/house-cleaning/[suburb].ts` | 301 → spring-cleaning | Migrate |
| `/deep-cleaning/[suburb]/` | endpoint | `src/pages/deep-cleaning/[suburb].ts` | 301 → spring-cleaning | Migrate |
| `/bathroom-cleaning/[suburb]/` | endpoint | `src/pages/bathroom-cleaning/[suburb].ts` | 301 → bathroom-deep-clean | Migrate |
| `/shower-screen-restoration/[suburb]/` | endpoint | `src/pages/shower-screen-restoration/[suburb].ts` | 301 → bathroom-deep-clean | Migrate |

Migration Plan Summary:
- Replace SSR endpoints with generated Netlify `_redirects` entries: `/<alias>/<suburb>/ /services/<canonical>/<suburb>/ 301`.
- Source-of-truth JSON map (service alias → canonical service).
- Script enumerates suburbs (from coverage or global suburb list) and emits deterministic lines.
- Benefit: removes SSR requirement; Playwright static server can test redirects; eliminates 404 test failures.

## 7. Redirects & Legacy Canonicalisation
| Path Pattern | Mechanism | File | Purpose |
|--------------|-----------|------|---------|
| `/services/:service/:cluster/:suburb/*` | Netlify redirect | `public/_redirects` or `netlify.toml` | Strip cluster segment legacy format |
| Blog cluster aliases (e.g. `ipswich-region`) | Netlify redirect (planned) | `_redirects` | Normalise cluster slug |
| Synonym service aliases | (Currently SSR) | See above | Consolidate variants | To migrate |

## 8. Support / Utility Pages
| Route | Type | Source | Notes |
|-------|------|--------|-------|
| `/ui` | static | `src/pages/ui.astro` | Likely component playground/dev aid (review for prod exclusion) |

Status: Evaluate if `/ui` should ship publicly; if internal only, gate or remove.

## 9. Data Sources Feeding Builds
| Data File | Role | Consumed By |
|-----------|------|------------|
| `src/data/services.json` | List of services (slug, title, checklist, description) | Service hubs & service×suburb pages |
| `src/data/serviceCoverage.json` | Map service → allowed suburb slugs | Service×suburb static path generation |
| `src/data/suburbs.json` | Curated suburb objects (slug, name) | Service hubs (popular areas), service×suburb pages |
| `src/content/areas.clusters.json` | Clusters with suburb arrays | Area pages, blog cluster index, cross-service logic |
| FAQ JSON files (`faq.service-*.json`) | Service-specific FAQs | Service hub pages |
| Reviews source (`src/server/reviews.js` + data) | Review aggregation | Schema graph & potential rating nodes |

## 10. Core UI / Layout Components
| Component | Role | Referenced In |
|-----------|------|--------------|
| `MainLayout.astro` | Global shell (head/meta) | Root, legal, gallery, blog index |
| `ServiceLayout.astro` | Service×suburb page shell | `services/[service]/[suburb].astro` |
| `ServiceNav.astro` | Cross-service + popular suburbs nav | Injected in service layout slot |
| `Schema.astro` / `SchemaGraph.astro` | JSON-LD single emitter | Service & service×suburb pages |
| `FaqBlock.astro` | Renders FAQ lists | Service hub pages |
| `Footer.astro` | Site-wide footer links | Layouts |

## 11. Supporting Lib & Utility Files
| File | Responsibility |
|------|---------------|
| `src/lib/crossService.ts` | Derives cross-service links for given suburb & service |
| `src/lib/serviceNav.adapter.ts` | Transforms data into UI card model & popular suburb list |
| `src/lib/seoSchema.js` | Pure builders for JSON-LD graph nodes |
| `src/lib/url.ts` | Absolute URL helper (SITE handling) |
| `src/utils/geoHandler.ts` | Cluster resolution for legacy redirect logic |
| `src/utils/slugify.js` | Normalises names to slugs |
| `src/server/reviews.js` | Fetch/merge/threshold review data |

## 12. Build / Guard Scripts (Affecting Routes)
| Script | Stage | Effect |
|--------|-------|-------|
| `scripts/expand-coverage.mjs` | Prebuild | Ensures coverage map completeness |
| `scripts/audit-routes.mjs` | Prebuild | Detects collisions/missing routes |
| `scripts/consolidate-ld.mjs` | Postbuild | Ensures single JSON-LD per page |
| `scripts/check-internal-links.mjs` | Postbuild | Blocks broken internal links |
| `scripts/audit-related-links.mjs` | Postbuild | Enforces related link caps |

## 13. Observed Issues & Recommendations (from this audit)
| Issue | Impact | Recommendation | File/Area |
|-------|--------|---------------|-----------|
| Empty legacy blog folders (`brisbane-west`, `brisbane_west`, `ipswich-region`) | Route clutter, risk of accidental future content | Delete folders; add explicit redirect or 410 policy | `src/pages/blog/*` |
| SSR synonym endpoints causing 404 in static tests | Failing Playwright suite; unnecessary SSR overhead | Migrate to static `_redirects` generation | Endpoint folders |
| `/ui` page shipping publicly? | Possible exposure of internal playground | Confirm need or remove from build | `src/pages/ui.astro` |

## 14. Migration Plan Snapshot
1. Remove empty blog legacy folders.
2. Add/update `_redirects` for any removed aliases (or 410 if policy chosen).
3. Introduce `synonyms.map.json` (alias → canonical service) + generator script to emit redirect lines for each suburb.
4. Delete SSR synonym endpoint folders after redirect parity confirmed.
5. Update Playwright redirect tests to read from generated map ensuring coverage.
6. Gate or remove `/ui` route.

---
## File Relationship Diagram (Conceptual)

Data JSON (services.json, serviceCoverage.json, suburbs.json, areas.clusters.json, reviews data)
  → Static Path Builders (`getStaticPaths()` in service & area pages)
    → Page Components (`[service]/index.astro`, `[service]/[suburb].astro`, areas, blog)
      → Layouts (`MainLayout`, `ServiceLayout`)
        → UI Components (`ServiceNav`, `FaqBlock`, `Footer`)
          → Utilities (`crossService.ts`, `serviceNav.adapter.ts`, `slugify.js`, `geoHandler.ts`)
            → Schema Builders (`seoSchema.js` + `Schema.astro` emitter)

Redirect Layer (current SSR endpoints) → To be replaced by Generated `_redirects` via synonyms map → Netlify Edge/CDN.

---
## Connected Files Brief (How They Work)
- `crossService.ts`: Loads precomputed map (or derives) to select related services and local guide link; deterministic to avoid runtime variation.
- `serviceNav.adapter.ts`: Presentation adapter turning raw link data into UI-friendly card arrays and popular suburb subsets.
- `seoSchema.js`: Exports pure functions returning JSON-LD node objects; no side-effects; combined into single `@graph` per page.
- `reviews.js`: Fetches and merges review samples; filters to threshold before adding AggregateRating.
- `geoHandler.ts`: Provides cluster resolution used for redirecting legacy URL forms and potentially for adjacency logic.
- `slugify.js`: Normalizes arbitrary names → URL-safe lowercase hyphenated slugs to maintain consistent route generation.
- `expand-coverage.mjs`: Ensures all necessary suburb pages are generated even if coverage JSON is sparse; prevents missing long-tail pages.

---
## Next Actions Auto-Filed
See appended entries in `checklist.md` (P0/P1) and `troubleshoot.md` (issue log) based on issues above.

