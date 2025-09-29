# Cross-service Linking — Technical Deep Dive

This document expands the earlier summary and captures the technical "what/why/how" in depth. It documents the code style, data flow, precise file relationships, decisions made, the current end state, gaps that remain, and a step-by-step plan to migrate to SSR if desired.

---

## Short plan / checklist (what I'll cover)

- [x] Why the change was necessary (what broke) and the general approach
- [x] File-level map: who reads/writes what and how modules interact
- [x] Data shapes and sample payloads for the key functions and files
- [x] Coding style & conventions used across the repo (TS/ESM, slug rules, naming)
- [x] End result (concrete artifacts, invariants and acceptance criteria)
- [x] Remaining work / technical debt / follow-ups
- [x] Full SSR migration plan with exact changes and risks
- [x] Extra useful additions (tests, debug commands, monitoring)

---

## 1) Problem summary, high-level approach

What broke
- The static `crossServiceMap.json` contained many cross-cluster fallbacks (e.g. Brisbane → Ipswich), while the runtime adapter and product policy expect same-cluster fallback only. That produced inconsistent link behaviour, and the build precomputed map could emit links to routes that don't belong to the same cluster.

Why it matters
- Inconsistent links confuse users and cause guard scripts to flag regressions. It also allowed generation of cross-cluster links which are a policy violation.

High-level fix applied
- Centralize cluster/suburb data parsing into a canonical provider.
- Enforce same-cluster only fallbacks at precompute time: remove global deterministic fallback from `scripts/build-cross-service-map.mjs` so the static map contains only `here` or `nearby` within the same cluster.
- Add a small tool suite (graph-sanity, check-buildable, diff-cross-service) to detect regressions and to validate parity between runtime adapter and precomputed map (adapter comparison left as next step to import safely at runtime).

---

## 2) Files & data flow (who talks to who)

This section lists the files we changed/added and the core read/write interactions. The arrows show direction (reads → source):

- `scripts/build-cross-service-map.mjs` (precompute)
  - reads: `src/data/serviceCoverage.json`, `src/data/adjacency.json`, `src/content/areas.clusters.json` (or `src/data/cluster_map.json` if present)
  - writes: `src/data/crossServiceMap.json`
  - behaviour: deterministic builder that prefers adjacency within same cluster, then any covered suburb in same cluster, and (after fix) returns null if none found — no global fallback.

- `src/lib/links/knownSuburbs.ts` (canonical provider)
  - reads: `src/content/areas.clusters.json` (array form)
  - exports: `getKnownSuburbSlugs(): Set<string>`, `findClusterSlugForSuburb(suburb): string | null`, `inSameCluster(a,b): boolean`, `getSuburbsInCluster(clusterSlug)`
  - responsibility: canonical slugification and cluster mapping for all other modules.

- `src/lib/links/nearby.ts` (runtime same-cluster picker)
  - reads: `src/data/adjacency.json` (structure: { slug: { adjacent_suburbs: string[], nearest_nonsiblings?: string[] } })
  - uses: `inSameCluster` from `knownSuburbs.ts`
  - exports: `pickNearbyCoveredInSameCluster(service, suburb, checker)` async and a sync variant
  - responsibility: BFS inside a cluster to find the closest suburb that covers a service.

- `src/lib/links/index.ts` (façade)
  - re-exports knownSuburb helpers and nearby pickers
  - defines `isServiceCovered(service, suburb)` using `src/data/serviceCoverage.json` directly (coverage is an in-repo JSON)
  - adds helpers `getLocalGuidesLink` (singular) and `getLocalGuidesLinks` (plural convenience) that wrap `src/utils/internalLinks` (legacy adapter). This clarifies singular-vs-plural API shapes.

- `src/utils/internalLinksAdapter.ts` and `src/utils/internalLinks.ts` (existing adapter code)
  - these are consumer/producer code points used by pages/components.
  - after the change, pages should import from `src/lib/links` façade instead of directly from `internalLinks` where possible.

- Components that consume cross/related links (read-only):
  - `src/components/CrossServiceLinks.astro` — uses the precomputed map or adapter to present cross-service items
  - `src/components/RelatedGrid.astro`, `RelatedLinks.astro`, `ServiceNav.astro` — all expect arrays of Link-like items; some call `getLocalBlogLink()` and previously assumed array-shape (caused `.map()` errors) — these were addressed by documenting/normalizing singular vs plural functions.

- Analysis tools (new):
  - `tools/graph-sanity.mjs` — validates adjacency ↔ clusters integrity
  - `tools/check-buildable.mjs` — computes "buildable" pairs (the same pairs used for getStaticPaths) and verifies static map + components don't emit unbuildable links
  - `tools/diff-cross-service.mjs` — scans `src/data/crossServiceMap.json` and reports cross-cluster fallbacks and top mismatches
  - `scripts/guard-dynamic.mjs` — verifies dynamic pages have `getStaticPaths` or `export const prerender = false` and param consistency

---

## 3) Code style & conventions

- Language: TypeScript for library code (`.ts`) and ESM JavaScript (`.mjs`) for scripts to keep Node compatibility in tooling. Components are `.astro` files.
- Module format: ESM (imports with `import` and top-level `export`); scripts use `.mjs` so Node executes them as ES modules.
- Type style: lightweight TS types and `any`/`Record` in scripts where necessary. New `src/lib/links` code uses typed exports to clarify contract shapes.
- Slug rules (canonical): `slugify()` / `norm()` used across tools
  - Lowercase
  - Replace whitespace with `-`
  - Remove/replace non-alphanumeric with `-`
  - Collapse `-+` into single `-`
  - Trim leading/trailing hyphens
- Data location conventions:
  - `src/content/*` = source canonical content authored/curated (e.g. `areas.clusters.json`) 
  - `src/data/*` = generated or precomputed runtime-friendly data (`crossServiceMap.json`, `serviceCoverage.json`, `adjacency.json`)
  - `scripts/*` = build-time precompute utilities (run before `astro build`)
  - `tools/*` = analysis/validator tools (run during CI or locally)

---

## 4) Key data shapes & sample payloads

- adjacency.json (excerpt)
```json
"brookwater": { "adjacent_suburbs": ["springfield-lakes","springfield","augustine-heights"], "nearest_nonsiblings": [] }
```
- areas.clusters.json (repo uses an array structure):
```json
{
  "clusters": [
    { "slug": "ipswich", "name": "Ipswich", "suburbs": ["Ipswich","Springfield Lakes","Brookwater"] },
    { "slug": "brisbane", "name": "Brisbane", "suburbs": [ ... ] }
  ]
}
```
- serviceCoverage.json (format)
```json
{
  "bond-cleaning": ["brookwater","springfield"],
  "spring-cleaning": ["ipswich","brookwater"],
  "bathroom-deep-clean": ["ipswich"]
}
```
- crossServiceMap.json (new format produced by builder)
```json
{
  "brookwater": {
    "bond-cleaning": [
      { "label":"Spring Cleaning (nearby)", "href":"/services/spring-cleaning/springfield-lakes/", "here":false, "data": { "service":"spring-cleaning","suburb":"springfield-lakes","source":"nearby" } }
    ]
  }
}
```
- Known-suburb provider exports (JS signature)
```ts
getKnownSuburbSlugs(): Set<string>
findClusterSlugForSuburb(suburb: string): string | null
inSameCluster(a: string, b: string): boolean
```
- Nearby picker contract
```ts
// async checker pattern (so it can call coverage lookups that may be IO-bound)
pickNearbyCoveredInSameCluster(service: string, suburb: string, checker: { isServiceCovered(service, suburb): boolean })
// returns { suburb: string, distance: number } | null
```

---

## 5) What the end result is (concrete invariants)

- crossServiceMap.json contains only `here` or `nearby` links where `nearby` targets are guaranteed to be inside the *same cluster* as the source suburb.
- The canonical suburb/cluster mapping is centralized in `src/lib/links/knownSuburbs.ts` and slug rules are consistently applied.
- The builder script (`scripts/build-cross-service-map.mjs`) fails fast when required inputs are missing and no longer emits cross-cluster fallbacks.
- The toolchain (`npm run lint:all`) bundles the route guard, graph sanity validator, buildable link verifier, and cross-service diff to assert repository invariants pre-merge.

Acceptance criteria satisfied
- Zero cross-cluster entries in `src/data/crossServiceMap.json` (verified)
- All emitted URLs are validated against buildable pairs (verified)
- Graph adjacency and cluster definitions consistent (verified)

---

## 6) What more is needed (short-term / medium-term tasks)

Short-term (small, low-risk)
- Update call-sites to import from `src/lib/links` façade instead of `src/utils/internalLinks` where appropriate.
- Replace any direct cluster parsing code to use `getKnownSuburbSlugs()` and `findClusterSlugForSuburb()`.
- Audit components that call `getLocalBlogLink()` and ensure they use `getLocalGuidesLink()` (singular) or `getLocalGuidesLinks()` (plural) to avoid `.map()` on string errors.
- Add lightweight unit tests for `knownSuburbs` and `nearby` behaviour (happy paths + one cross-cluster case)

Medium-term
- Integrate adapter comparison into `tools/diff-cross-service.mjs` by importing runtime adapter functions safely (use a small shim or a bundler-friendly import). This will let us assert parity between runtime and precompute.
- Add a small snapshot test that compares a sample of `getCrossServiceItems()` output to the map for the same suburbs.
- Add structured logs and telemetry to detect newly introduced cross-cluster output in PRs beyond CI scripts (e.g., GitHub action comment or SARIF output)

Long-term / Optional
- Reconsider whether global fallback is desired behind a feature flag. If kept, it must be explicit and annotated in the crossServiceMap item (e.g., global:true). The current policy is same-cluster only.
- Add a small cache or TTL-backed API to serve cross-service map at runtime (for SSR or dynamic builds).

---

## 7) SSR migration plan (if you want everything SSR instead of static)

Why someone would want SSR
- Serve freshest data (service coverage may change frequently)
- Avoid large precompute steps during build and reduce stale precomputed maps
- Easier to support dynamic user-specific or geo-aware decisions at request time

High-level migration steps

1. Decide the SSR deployment target
   - Node adapter (serverless or long-running Node), or
   - Netlify Functions / Edge / Cloudflare Workers (requires adaptation of platform APIs)
   - Current `astro.config.mjs` is configured for `output: 'static'` and Netlify adapter. For SSR you must change `output` to `server` and pick a suitable adapter. Example: `adapter-node` or `@astrojs/netlify` with `edgeMiddleware`/server support.

2. Make pages non-prerendered where needed
   - For each dynamic page that should be SSR, set `export const prerender = false;` (or remove `getStaticPaths` where you want per-request rendering).
   - Example: `src/pages/services/[service]/[suburb].astro` — set `export const prerender = false;` and ensure code paths do not rely on static-only data.

3. Move precompute logic into a runtime layer
   - Option A: Keep `scripts/build-cross-service-map.mjs` and run it in CI to produce `crossServiceMap.json` and read it at SSR runtime (fast). This keeps behaviour identical but still allows fresh regeneration on deploy.
   - Option B: Replace precompute with a runtime service/layer that computes `getCrossServiceItems()` on demand using the same algorithms (BFS, same-cluster checks). Implement caching (in-memory for node, or Redis/edge cache) to avoid heavy repeated computation.

4. Make data files available at runtime
   - Ensure `src/data/*.json` (coverage, adjacency, clusters) are bundled or loaded from a fast data store (S3, KV) so they are accessible at runtime.

5. Update tooling and CI
   - Update `scripts/guard-dynamic` to expect SSR settings where appropriate.
   - Add tests to validate SSR route responses (integration tests hitting a local dev server or using Playwright).

6. Performance & caching
   - Add an LRU cache for nearby pickers and `crossServiceMap` lookups.
   - Consider per-cluster precompute: compute map per cluster on deploy then serve merged results.
   - Use CDN caching for pages when possible and revalidate on content or coverage changes.

7. Security & platform concerns
   - Ensure the serverless runtime has access to any data files or secrets (DB). Avoid exposing admin-only endpoints.
   - Watch cold-starts on serverless platforms; pre-warm caches or use a persistent node process for heavy workloads.

Practical checklist to switch one page to SSR
- [ ] Change `export const prerender = false` at top of page
- [ ] Ensure any code relying on static-only functions (like direct `import` of `crossServiceMap.json`) is robust when files are loaded at runtime (prefer dynamic import or fs read in server context)
- [ ] Add server-side caching for `pickNearby` operations
- [ ] Run `npm run build && node ./start-server.js` (or equivalent adapter start) locally and run integration tests

Risks and mitigations
- Risk: Increased cost and complexity for runtime. Mitigate with caching and partial precompute.
- Risk: Longer response times on first requests. Mitigate with warming and CDN cache.

---

## 8) Useful developer commands and debug checks

- Rebuild cross-service map (enforces same-cluster):
```bash
npm run build:map
```

- Run full validation suite (route guard, graph, buildable, cross diff):
```bash
npm run lint:all
```

- Check the static map for cross-cluster entries (quick grep):
```bash
jq -r 'to_entries[] | select(.value != null) | .key as $s | .value | to_entries[] | .value[] | select(.href | test("/services/")) | {from:$s, href:.href}' src/data/crossServiceMap.json | head -n 40
```

- Run one tool directly (graph sanity):
```bash
node tools/graph-sanity.mjs
```

- Quick sanity: check a sample suburb using the runtime picker (pseudo):
```js
// node REPL in project root
import { pickNearbyCoveredInSameCluster } from './src/lib/links/nearby.js';
import { isServiceCovered } from './src/lib/links/index.js';
await pickNearbyCoveredInSameCluster('spring-cleaning','brookwater', { isServiceCovered });
```

---

## 9) Tests & monitoring I recommend adding

- Unit tests (vitest or jest)
  - knownSuburbs: slug normalization, cluster lookup
  - nearby: BFS that returns same-cluster result and returns null when none in-cluster
  - build-cross-service-map: small fixture test that the builder returns only same-cluster picks

- Integration tests
  - Compare adapter `getCrossServiceItems(suburb)` versus `crossServiceMap.json` for 20 random suburbs; fail on mismatches.

- CI monitoring
  - Add a required job `npm run lint:all` for branches targeting `main`.
  - Optionally, produce a small PR comment with a diff summary from `tools/diff-cross-service.mjs` showing top mismatches.

- Runtime alerts
  - If migrating to SSR, add an alert for any runtime-generated cross-cluster link (should remain 0). Emit counts to logs/telemetry.

---

## 10) What extra info was useful and was added here

- The exact file-by-file call graph and read/write relationships.
- Canonical slug rules and how they are applied consistently.
- Data shapes and sample payloads for the main JSON artifacts and function contracts.
- A practical SSR migration path with exact changes to config and pages and performance/cost tradeoffs.
- Commands and quick debugging snippets to reproduce the checks locally.

---

## 11) Final notes & recommended next steps (concise)

- Merge the current fixes (branch `fix/service-layout-hardening`) to `main` after CI passes. CI should run `npm run lint:all` and fail if regressions reappear.
- Update components to consistently import from `src/lib/links` façade and standardize `getLocalGuidesLink` vs `getLocalGuidesLinks` usage.
- Add the test suite outlined above and wire the integration diff into CI (adapter comparison is the only remaining parity check to make runtime==precompute).
- If you plan an SSR migration, start with a hybrid approach: keep the precompute step but serve the JSON from a runtime endpoint with caching. This reduces risk and allows later removal of the precompute step.

If you want, I can now:
- Create the unit tests and a small integration test harness for adapter-vs-map parity.
- Convert example pages to SSR and demonstrate one working route locally.
- Update specific components to import the new façade and fix singular/plural API call sites.

Which of the above shall I do next?
