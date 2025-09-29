## AI Coding Agent Instructions (July22)
Purpose: Ship geo + content + CSS/linking changes safely by extending existing guardrails (never bypassing them) and eliminating problem classes (Upstream‑Curious: Box → Closet → Policy).

1. Hunter‑First (NON‑NEGOTIABLE)
  - Run: `npm run hunt:ci` before coding. Read `__reports/hunt/master.json` then any `critical` module reports (e.g. `runtime_ssr.json`, `accessibility.json`, `security.json`).
  - If a class issue exists, design a fix + invariant (test / hunter) BEFORE feature work.
  - Add new detectors as `hunters/<name>.sh` (exit codes: 0 clean / 1 warn / 2 critical) writing JSON to `__reports/hunt/`.

2. Upstream‑Curious Loop
  - Box (symptom) → Closet (architectural source) → Policy (invariant / hunter / test) → Proof (was failing, now enforced).
  - Prefer deletion / consolidation over adding flags. Avoid duplicate sources of truth.

3. Core Domains & Single Sources
  - Geo lifecycle: `src/data/suburbs.registry.json` (state machine), `src/data/areas.clusters.json` (clusters), adjacency graph (`src/data/adjacency.json`).
  - Page content: `src/content/suburbs/*.md|json` (staged → published via scripts, NEVER manual mass edits in registry without `promote` script).
  - Linking façade: `src/lib/links/index.ts` (only entry for service / nearby / guides links). Do not resurrect legacy helpers.
  - CSS baseline: `__reports/css-baseline.json` (hash‑agnostic). Update intentionally: `npm run css:baseline:update`.
  - Cross‑service precompute: `scripts/build-cross-service-map.mjs` → `crossServiceMap.json` (runtime parity tested by `lint:cross`).

4. High‑Risk Invariants (never break silently)
  - Adjacency symmetry (use `npm run fix:adjacency:write` if needed).
  - Registry state transitions only via `npm run geo:scaffold|readiness|publish` commands.
  - One global CSS bundle (guard: `npm run css:assert:one-global`).
  - Buildable links (script `lint:buildable`) & internal link presence (`check-internal-links.mjs`).
  - JSON‑LD single emitter (`Schema.astro`) + post‑build consolidation safety net.

5. Geo Workflow (authoring)
  1 Inventory: `npm run geo:backlog`
  2 Scaffold: `npm run geo:scaffold -- --slugs=slug-a,slug-b`
  3 Enrich content (word count, images, local intro, nearby block)
  4 Audit: `npm run geo:readiness -- --state=staged --check-links --stable-json`
  5 Publish: `npm run geo:publish -- --slugs=...` (score ≥70)
  6 Gate: `npm run geo:gate` (review new failures; justify or fix)

6. Modifying Data / Adding Fields
  - Maintain backward compatibility. If a report JSON shape changes, update parity logic & tests in same commit.
  - Commit only relevant regenerated reports (avoid noisy unrelated churn).

7. Writing Code
  - Use absolute `~/` imports; kebab‑case slugs; avoid placeholders `{{suburb}}`.
  - Keep script outputs deterministic (add `--stable-json` where provided).
  - When adding a hunter: small, composable shell; JSON schema: `{ "timestamp", "module", "critical_issues", "warning_issues", "findings": { ... } }`.

8. Testing & Verification
  - Fast geo tests: `npm run test:geo`; unit: `npm run test:unit`; full E2E: `npm test`.
  - CSS guardrails auto-run in `npm run build`; to update baseline do it explicitly then commit.
  - Blog base safety: `npm run ai:blog:verify` (default) & `BLOG_BASE=/guides/ npm run ai:blog:verify:ext` before PR.

9. Policy Changes / Thresholds
  - Edit `geo.policy.json` sparingly; prefer feature flags (e.g. `GEO_PARTIAL_OK`) over deleting rules; document rationale in PR description.

10. Common Pitfall Avoidance
  - Do NOT hand‑edit generated artifacts as a “fix.” Change the generator or add a hunter.
  - Don’t introduce new link helpers—extend the façade.
  - Avoid adding SSR features that would require an adapter unless justified; prefer static generation.

11. Quick Command Cheat Sheet
```bash
npm run hunt:ci
npm run geo:scaffold -- --slugs=example
npm run geo:readiness -- --state=staged --check-links --stable-json
npm run geo:publish -- --slugs=example
npm run geo:gate && npm run geo:parity
npm run css:baseline:check && npm run css:assert:one-global
```

12. PR Expectations
  - One logical change set (geo pages, CSS tweak, or linking improvement) + passing hunters + updated baseline/tests + rationale (Box→Closet→Policy) in description.

Reference deep dives: `README.md`, `think_about_it.md`, `hunt.sh`, `hunters/*.sh`.
