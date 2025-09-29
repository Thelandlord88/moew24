Welcome aboard! This repo has a lot of moving parts (Astro SSR/SSG, Tailwind, structured data, route generators, audits, and data-driven content). This guide tells you:

What’s here and why

Exactly which commands to run (dev, build, generate, test, audit)

How content is generated (from JSON/CSV → pages/components)

Strengths to lean on and weak spots to avoid breaking

Rules of the road (SEO, routing, schema, performance)

What will happen next (near-term roadmap & gotchas)

Use this as your day-one checklist and ongoing reference.

0) System prerequisites

Node 20.x (do not use 21+ unless told otherwise)

pnpm or npm (repo typically uses npm, commands below assume npm)

(Local-only/optional) If working with vector tiles: tippecanoe and tile-join CLIs

node -v     # should be v20.x
npm -v

1) Quick start commands (copy/paste)
# Install deps
npm install

# Start local dev server (Astro)
npm run dev    # or: npm start

# Lint & fix
npm run lint
npm run lint:fix

# Typecheck (Playwright config may launch Astro)
npm run typecheck

# Run tests (includes Playwright when configured)
npm test

# Build production site (includes prebuild hooks)
npm run build


If the dev server dies immediately and Playwright logs “Process from config.webServer exited early”, it usually means required data files are missing (see §7 “Common failure modes”).

2) Important scripts you’ll see (what they do)

Names may vary slightly; use npm run to list all scripts.

predev / dev / start
Boots Astro dev via a small guard/port chooser. Fails fast if critical data is missing.

pages:discover / pages:to-tests / pages:promote
Page-mapping utilities. Discover generated pages, turn them into test routes, and promote passing routes live.

build
Production build. In our setup, build may run consolidation scripts (e.g., consolidate LD-JSON, audit internal links).

generate:suburb-sites
Generates static microsite pages from the suburbs CSV (see §5). These write under public/microsites/ so Netlify will deploy them.
You can parametrize:

SERVICE_SLUG=bond-cleaning SITE_ORIGIN=https://onendonebondclean.com.au npm run generate:suburb-sites


quarantine:* / legacy:find / schema:hash / verify:*
Utility/audit scripts for code hygiene, schema hashing, or file quarantining. Run them on feature branches before PRs.

3) Directory & data model (what lives where)

src/pages/services/[service]/[suburb].astro
Dynamic route that renders service × suburb content. This is the canonical page for SEO (preferred over any auxiliary microsite).

Data dump/Map data important/suburbs_enriched.csv
The authoritative suburb dataset (names, slugs, LGA, centroid lat/lon, postcode, state). Do not move or rename without updating generators.

data/*.json and src/data/*.json
JSON data sources used by generators/components (e.g., tag graphs, related links).

Rule: We keep .json files even if TypeScript exists—TS models complement; they don’t replace data files. Scripts and tests expect these JSONs to exist.

scripts/*.mjs
Node-based generators/auditors (content audits, schema consolidation, related links, microsite generation, tiles build).

src/lib/*.ts / src/lib/*.js
Client and server utilities (schema emitters, quoting logic, etc.).
Important: There is one official JSON-LD emitter path (schema consolidation). Don’t add parallel emitters unless explicitly asked.

public/
Static assets shipped as-is (favicons, tiles, microsites, _headers if used).

4) Golden rules (before you edit anything)

One canonical URL per topic.
The dynamic route /services/[service]/[suburb]/ is the canonical. If you generate helper pages (microsites), they must set a <link rel="canonical" href=".../services/.../"> or noindex.

Don’t delete .json data files because a .ts version “exists.”
Generators, audits, and tests often read JSON directly. Treat JSON files as runtime inputs, TS as types/helpers.

Keep the single JSON-LD pipeline.
We consolidate schema after build. Don’t create a competing schema emitter—extend the existing one.

Mind build-only tools.
CLIs like tippecanoe don’t exist on Netlify by default. Gate those steps with env flags and commit outputs if needed.

Respect audits.
We fail the build if content is below quality bars (e.g., word count, internal links). If a page is thin, fix content or exclude it from that audit intentionally.

5) Content generation flows you’ll touch
A) Canonical service × suburb pages (Astro)

Source of truth: CSV + JSON (graph/related links)

Renderer: src/pages/services/[service]/[suburb].astro

Data access: Either via filesystem imports at build time or through a helper that reads CSV/JSON and exposes it to getStaticPaths() / page props.

Structured data: Pass service/suburb to the central schema emitter.

B) Microsites (optional helpers)

Command: npm run generate:suburb-sites

Output: public/microsites/{slug}/index.html

Purpose: Lightweight, crawlable “satellite” pages that canonicalize to the main service × suburb route.

Rule: Keep them simple; let the main Astro page be the source of depth (copy, CTAs, forms, imagery).

C) Related links (adjacency)

Build a related-links.json (neighbors) from the tag graph. The component reads it and renders “Nearby suburbs we serve.” Keep consistent with tests/audits.

6) SEO / performance rules (non-negotiables)

Structured data
Use the single pipeline (Organization/LocalBusiness + Service + Place + WebPage) with @id links tying nodes together.

Canonical & robots

Main pages: canonical to themselves.

Microsites: canonical → main page OR noindex,follow.

OpenGraph/Twitter
Every indexable page: title, description, url; image when available.

Internal links
Within <main>, at least 3 internal links to relevant pages (services, nearby suburbs, blog content). Audits may enforce this.

Content depth
Aim for 700+ words unique content per indexable page. Thin pages make audits/builds fail.

CSS & color system
We use semantic CSS variables (e.g., --brand-accent) layered over Tailwind tokens. Changing the Tailwind palette won’t override existing literal CSS vars—update the variables where defined.

JS weight
Prefer Astro islands and zero/low JS where possible. Avoid shipping heavy third-party maps globally—scope them to pages that need them.

7) Common failure modes (and quick fixes)

Dev server exits instantly / Playwright complains about early exit

Likely missing src/data/* or CSV JSONs that imports expect.

Fix: ensure Data dump/Map data important/suburbs_enriched.csv exists and any required src/data/*.json are present.

Build fails on audits

Error from “audit content” script showing { words, links } too low for a page.

Fix: expand copy, add in-content internal links.

Netlify ignores headers

If _headers sits at repo root and isn’t copied to publish dir, it won’t apply.

Fix: put headers in public/_headers or netlify.toml.

Tiles build breaks CI

tippecanoe not installed on Netlify.

Fix: guard with LOCAL_TILES=1 env var locally; commit generated tiles under public/tiles/ if they’re static.

Duplicate schema warnings

Multiple emitters wrote JSON-LD.

Fix: remove extra emitters, feed data into the central schema component only.

8) How to add/modify suburbs & services

Add or edit suburb data
Update suburbs_enriched.csv (keep columns consistent: slug,name_official,lga,centroid_lat,centroid_lon,postcode,state).

(Optional) Update tag graph
If using a data/tag.json graph, add suburb entities and covers/nearby edges.

Regenerate helpers

Related links: run the related-links builder (if present).

Microsites: npm run generate:suburb-sites.

Build
npm run build (ensure no audit failures).

Test
npm test and manually hit a few routes:
/services/bond-cleaning/{suburb}/ and /microsites/{suburb}/ (if used).

9) Coding standards & PR process

Branch names: feature/…, fix/…, content/…

Commits: concise imperative subject + details in body (mention scripts touched).

PR checklist:

✅ npm run lint clean

✅ npm test green

✅ npm run build locally (or PR build) green

✅ No duplicate JSON-LD emitters

✅ Canonical/robots tags correct

✅ New data files committed (*.json, CSVs) and referenced correctly

✅ If adding map tiles, either gated or assets committed under public/tiles/

10) Strengths to lean on

Data-driven pages: We can scale suburb/service coverage by editing CSV/JSON and letting generators fill in the rest.

Single schema pipeline: Clean, deduped JSON-LD across the site.

Audits: Automated guardrails for internal links and content depth keep SEO quality high.

Dynamic routing: One canonical page pattern (/services/[service]/[suburb]/) simplifies IA and crawl depth.

11) Weak spots to treat with care

Deleting “redundant” JSONs
→ Don’t. Even if a TS utility exists, some scripts and tests read JSON directly.

Adding second schema emitters
→ Will cause duplication and schema drift. Extend the existing emitter only.

Generating duplicate routes
→ If you write static files under src/pages/services/..., they’ll clash with the dynamic [service]/[suburb] route. Prefer feeding data into getStaticPaths().

External CLIs in CI
→ Don’t assume tippecanoe is available on Netlify. Gate or prebuild locally and commit artifacts.

CSV parsing
→ Always use a robust CSV parser (quoted commas, newlines). Avoid split(',').

Paths with spaces
→ The CSV directory has spaces (Data dump/Map data important/). Always resolve paths with Node’s path API; don’t shell-glue strings.

12) Useful one-liners & examples
# List available scripts
npm run

# Regenerate microsites with explicit origin/service
SERVICE_SLUG=bond-cleaning SITE_ORIGIN=https://onendonebondclean.com.au \
  npm run generate:suburb-sites

# Guarded tiles build (local only)
LOCAL_TILES=1 node scripts/build-tiles.mjs

# Run content audit after build (if not already chained)
node scripts/audit-content.mjs

# Create a quick JSON pretty-print from a CSV row selection (example pattern)
node -e "const fs=require('fs');const {parse}=require('csv-parse/sync');\
const rows=parse(fs.readFileSync('Data dump/Map data important/suburbs_enriched.csv','utf8'),{columns:true});\
console.log(JSON.stringify(rows.find(r=>r.slug==='ipswich'),null,2))"

13) Near-term roadmap (what will happen next)

Unify data ingestion: Move CSV/JSON reading to a single helper used by getStaticPaths() and schema emission to eliminate drift.

Strengthen audits: Expand link/content audits to cover duplicate titles/descriptions and missing canonical tags.

Gate heavy steps: Ensure tile building & other heavy tasks are strictly opt-in via env flags; commit outputs when needed.

Content expansion: Lift thin pages over the word/link thresholds and wire related-links consistently.

14) When in doubt (decision tree)

Does this change create a second place to define the same truth?
→ Don’t. Feed the existing pipeline.

Will search engines see two URLs with the same content?
→ Add canonical or noindex on the auxiliary URL.

Is a JSON file “unused” because TS exists?
→ Assume it’s still used until you verify all generators/tests.

Does a new feature require a CLI at build time?
→ Gate with env or prebuild locally and commit artifacts.

Keep this close. If you’re about to remove a JSON, add a schema emitter, or generate new routes directly under src/pages/services/…, stop and check this guide first.
