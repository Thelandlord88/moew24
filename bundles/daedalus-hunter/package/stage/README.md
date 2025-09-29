# One N Done — Upstream Blog + Geo Suburbs

A production-ready Astro 5 system with:
- Tailwind v4 via `@tailwindcss/postcss`
- Geo suburb architecture (clusters, adjacency, proximity)
- Per-suburb service pages for **Bathroom Deep Clean** and **Spring Clean**
- LocalBusiness / Service JSON-LD, canonical URLs, sitemap
- Transparent Lift Pack guardrails (anchor diversity, schema↔UI lockstep, no hidden keywords, no UA DOM)
- Geo Doctor + SEO DOM scanner (happy-dom) + Playwright smoke

## Quick Start
```bash
npm install
npx playwright install
npm run geo:doctor
npm run dev
# build + audit
npm run build
npm run seo:report
npm run inv:anchors && npm run inv:lockstep && npm run inv:no-ua && npm run inv:no-hidden && npm run inv:sitemap && npm run inv:similar
````

## Owner must supply / maintain

* `src/data/areas.clusters.json`  → clusters + suburbs with **lat/lng per suburb**
* `src/data/cluster_map.json`     → cluster → region mapping (e.g., brisbane/ipswich/logan)
* `src/data/areas.adj.json`       → adjacency per suburb (improves nearby quality)
* `src/data/proximity.json`       → curated nearby lists (optional; overrides)
* `src/data/geo.config.json`      → ranking weights & nearby limit; regions list
* `src/data/business.json`        → NAP for LocalBusiness JSON-LD
* `src/content/posts/*.md`        → blog posts with `region ∈ {brisbane, ipswich, logan}`

### File shapes

* **areas.clusters.json**

```json
{ "clusters":[{ "slug":"brisbane","name":"Brisbane","suburbs":[
  {"slug":"annerley","name":"Annerley","lat":-27.51,"lng":153.03}
]}]}
```

* **cluster\_map.json**

```json
{ "brisbane":"brisbane","ipswich":"ipswich","logan":"logan" }
```

* **areas.adj.json**

```json
{ "annerley":["woolloongabba","fairfield"] }
```

* **proximity.json**

```json
{ "nearby": { "annerley":[{"slug":"fairfield","name":"Fairfield"}] } }
```

## CI guardrail

Use `npm run guard:all` to validate geo + build + SEO + invariants in one shot (configured as Netlify build command).
