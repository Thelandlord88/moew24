# Troubleshoot Log

Date: 2025-08-24

## Issue 1: Synonym Redirect Tests Failing (All 404 Instead of 301)

### Symptoms
- Playwright test `tests/e2e/synonym-redirects.spec.ts` reported 404 for every expected 301.
- Attachments (screenshots, video, trace) captured for each failure.

### Root Cause
The Playwright configuration (`playwright.config.ts`) uses a `webServer` command:
```
node scripts/serve-with-redirects.mjs -d dist -p 4322
```
This serves the static `dist/` output only. The synonym redirect endpoints (e.g. `src/pages/bond-cleaners/[suburb].ts`) are SSR endpoints (`prerender = false`) and are *not* emitted into `dist/`. When hitting those paths against a static server, 404 is returned (no file present) – expected under static serving.

### Why It Emerged Now
We added a redirect parity test without adjusting the server mode to one that can execute SSR logic. Previously no test targeted these SSR-only routes.

### Options
1. Keep SSR endpoints (requires SSR runtime in tests):
   - Add a second Playwright project or separate config that runs `astro dev` (or `astro preview` with SSR adapter) to exercise endpoints.
   - Pros: Central redirect logic stays in code; easy to unit test finder logic.
   - Cons: Slower test spin-up; increases complexity with dual server modes.
2. Convert redirects to static Netlify rules (`public/_redirects` / `netlify.toml`).
   - Pros: Works under static server (current serving approach), simplifies CI.
   - Cons: Add duplication risk if logic (slug resolution) evolves; need script to generate rules from single source of truth.
3. Hybrid: Keep a canonical redirect map JSON → generate SSR endpoints (for local dev flexibility) *and* Netlify redirects at build time.
   - Pros: Single config, resilience if one path misconfigured.
   - Cons: Slight build complexity.

### Interim Mitigation
- Mark redirect test as skipped or conditionally run only when an SSR-capable server is active (env flag) to keep current pipelines green.

### Recommended Path
Adopt Option 2 (static Netlify redirects) if synonyms are purely canonical alias rewrites without dynamic logic beyond slug normalization. Otherwise implement an SSR test project.

### Action Items
- [ ] Decide strategy (static vs SSR) — see checklist updates.
- [ ] If staying SSR, add a `redirects.dev.config.ts` that spins up `astro dev` for those tests only.
- [ ] If moving static, implement generator script (reads service alias → target suburb mapping) and append to `_redirects`.
- [ ] Temporarily skip failing test to unblock CI (document skip reason in code).

## Issue 2: Legacy Empty Blog Cluster Folders Present

### Symptoms
Empty directories found under `src/pages/blog/` for `brisbane-west`, `brisbane_west`, and `ipswich-region`.

### Impact
- Route namespace clutter; increases risk of accidentally adding content under deprecated slugs.
- Potential confusion about which cluster slugs are canonical.

### Root Cause
Historical/placeholder folders retained after slug normalization decisions; never populated with index pages.

### Recommendation
Delete folders; add explicit redirects (or 410 responses if policy set) from old slugs to canonical cluster slug in `public/_redirects`.

### Action Items
- [ ] Remove folders.
- [ ] Add redirect or 410 entries per policy.
- [ ] Update README (Blog section) to reflect retired slugs.

## Issue 3: Public `/ui` Page Unverified Purpose

### Symptoms
`src/pages/ui.astro` exists (purpose not documented in README) and may be deployed.

### Impact
Potential exposure of internal component playground or experimental UI to crawlers/users.

### Recommendation
Decide if page should be:
1. Deleted (if internal only),
2. Moved under a dev-only path gated by env, or
3. Documented and intentionally styled as a public showcase.

### Action Items
- [ ] Confirm intention.
- [ ] Apply chosen disposition.
- [ ] If retained, add to build list with rationale.

## Issue 4: ESLint Peer Dependency Conflict (Resolved 2025-08-24)

### Summary
Initial install produced ERESOLVE due to `eslint@9.x` with `eslint-plugin-unused-imports@3.x` (peer pinned to ESLint 8). Upgraded plugin to `^4.1.4` and bumped ESLint to `^9.34.0`.

### Current State
Install succeeds; large unused import / var noise has since been cleaned (baseline now near-zero after cleanup pass). Config updated to disable base `no-unused-vars`, rely on `unused-imports/no-unused-imports` (error for unused imports) and `unused-imports/no-unused-vars` (currently warn) + TypeScript variant.

### Next Steps
- (DONE) Bulk cleanup pass to reduce warnings.
- Raise severity of variable unused warnings to error (pending strategic decision once stability confirmed).
- (DONE) Remove deprecated `.eslintignore` (merged into flat config ignores) to eliminate migration warning.

### Action Items
- [x] Cleanup unused vars (achieved near-zero baseline).
- [ ] Escalate remaining unused var warnings to errors (post observation window).
- [x] Remove `.eslintignore` (migrated patterns into flat config).

## Issue 5: Node Runtime Mismatch & Outdated Data Validation Script (Resolved 2025-08-24)

### Symptoms
- Running `npm run dev` (predev hook) produced a SyntaxError: `Unexpected identifier 'assert'` in `scripts/validate-data.js`.
- Engines in `package.json` specify `>=20 <21`, but environment used Node v22.17.0.

### Root Cause
- Legacy version of `scripts/validate-data.js` relied on JSON import assertions (`import x from './file.json' assert { type: 'json' }`) executed directly by Node (not bundled). Node 22 tightened / changed handling relative to expected environment; script design coupled to ESM assertion style unnecessarily.
- Engines mismatch allowed a newer Node to run unvetted code path.

### Resolution
- Rewrote `scripts/validate-data.js` to read JSON via `fs.readFileSync` + `JSON.parse` (no import assertions, no dynamic ESM complexities). Added structural validation, summary output, non‑zero exit on failure.
- Confirmed clean execution: `[data:ok] {"suburbs":8,"services":3,...}`.

### Follow-Ups
- Decide whether to: (a) enforce Node 20 in dev (nvm / Volta / CI), or (b) relax engines field to include 22 after broader smoke tests.
- (Optional) Migrate remaining JSON import assertions used in runtime Node scripts (Astro / Vite handled ones are fine) if any appear outside the bundler pipeline.

### Action Items
- [x] Modernize validation script (remove import assertions).
- [ ] Align Node version policy (enforce 20 or broaden to 22 after test matrix run).
- [ ] CI check to warn if actual Node version drifts from `engines`.

## Issue 6: Header Component ReferenceError (Resolved 2025-08-24)

### Symptoms
- Console / dev server errors: `logoSrc is not defined` originating from `src/components/Header.astro:37`.

### Root Cause
- Refactor introduced `_logoSrc` variable while template still referenced `logoSrc`.
- Client-side script also referenced undeclared identifiers (`btn`, `menu`, etc.) after variable renaming to underscore-prefixed variants.

### Resolution
- Updated template to use `_logoSrc`.
- Fixed script: consistently referenced `_btn`, `_menu`, `_open`, `_close` in event listener.
- Restored prop destructuring to `currentSuburb` / `suburbs` (without underscore) to match template usage.

### Action Items
- [x] Patch component.
- [ ] Add lightweight component smoke test (render Header in isolation & assert logo img present) to prevent regression.

## Additional Observations
- Baseline lint now effectively clean (unused imports/vars addressed). Remaining plan: optionally escalate residual warnings to errors.
- `.eslintignore` removed; flat config ignore list authoritative.
- Consider adding a pre-commit hook or CI step to run `node scripts/validate-data.js` explicitly (already invoked via `predev`, but not yet guaranteed in all pipelines).

## Proposed Next Steps Snapshot
| Step | Priority | Owner | Notes |
|------|----------|-------|-------|
| Decide redirect hosting strategy | P0 | TBD | Blocks fixing failing test |
| Implement chosen fix | P0 | TBD | Either new static rules or SSR test server |
| Suppress/resolve ESLint ignore warning | P0 | TBD | Add `ignorePatterns` only; remove `.eslintignore` | 
| Unused vars cleanup pass | P1 | TBD | Then escalate to error |

---
