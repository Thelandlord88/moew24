# Non‑Blog Tests & Scripts Report (Focus: important vs unused)

Date: 2025-09-07

Objective
- Get important non-blog scripts/tests working. Move non-essential to an “unused” list.

## Executive summary
- Important & working: css size/usage, tokens export, FAQs build, internal links/cross-links postbuild, schema and site checks, typecheck.
- Important & broken (fix recommended): ESLint config, Jest tests, allowlist regex, site audit actions.
- Non-critical/low value for now (propose unused): unit tests placeholder, some dev-only helpers.

## Run results snapshot
- PASS: css:size, contrast:audit, tokens:export, css:usage, env:print, build:faqs, ai:clean:strays, report:unused-js, quarantine:dryrun, verify:yaml, typecheck
- WARN: validate:footer (server not running)
- FAIL: ai:site:audit, ai:site:audit:add-helper (see __ai/site-audit.txt)
- FAIL: unused:allowlist (regex from glob)
- FAIL: lint (ESLint v9 requires eslint.config.js)
- FAIL: test:unit (no unit tests)
- FAIL: test:jest (3 suites failed)
- FAIL: test:faqs (JSON import assertion under Node 22)

## What’s important (keep & fix)
1) Lint (eslint)
- Why: baseline quality gate; CI-standard.
- Issue: No eslint.config.js (flat config).
- Fix: add flat config with current rule set and ignores. Keep minimal initially.

2) Jest tests OR consolidate to Vitest
- Why: test coverage on utilities is useful.
- Issue: Jest suites failing due to parser/config. Vitest unit suite is empty.
- Fix options:
  - A) Migrate jest tests to Vitest (reuse vitest.config.mts aliases). Recommended.
  - B) Add Babel/Jest config to parse ESM/TS modern syntax.

3) unused:allowlist
- Why: controls quarantine safety; should run cleanly.
- Issue: RegExp from glob '**' => invalid pattern.
- Fix: use micromatch/isMatch on paths instead of RegExp or escape asterisks.

4) ai:site:audit actions
- Why: canonical/sitemap/absolute URLs correctness.
- Issue: 3 criticals (see appendix). Not a script error; content/config follow-ups needed.

5) test:faqs (data validation)
- Why: keeps FAQs shape valid.
- Issue: Node 22 import attributes not handled as expected.
- Fix: switch to fs.readFileSync + JSON.parse.

## What’s not important (move to unused for now)
- test:unit (no tests present) — mark unused until real unit tests exist.
- validate:footer: warn-only unless server present (keep as optional local check).
- jest test duplicates if we migrate to Vitest — mark Jest as unused afterwards.

## Actions I propose (fast, minimal)
- Add eslint.config.js (flat), basic rules + ignores.
- Patch build-unused-allowlist.mjs to use micromatch for includes/excludes.
- Update validate-faqs.js & validate-data.js to load JSON via fs.
- Mark non-critical scripts “unused” in this file; optionally hide them from CI.

## Q&A (asked and answered by the system)
1) Do we need ESLint fixed now?
- Yes. It’s an important guardrail and quick to wire with a flat config.

2) Do we need jest or vitest? Which is simpler?
- Simplest: migrate existing jest tests to Vitest; config already exists and matches path aliases.

3) Is the allowlist generation blocking?
- Medium. It fails now; quick micromatch fix makes it reliable. Worth fixing.

4) Should we care about validate:footer now?
- Low. It’s informative without a running server. Keep as warn-only.

5) Are the site audit criticals real blockers?
- They indicate hard-coded origins and missing SITE usage in some helpers. Not blocking builds but good to fix this week.

## Appendix A — Site audit criticals
From __ai/site-audit.txt
- Hard-coded origins:
  - https://site.com (FeatureCardGrid.astro)
  - https://deno.land (scripts/guard-deno.js)
  - https://vercel.com / https://via.placeholder.com (src/utils/ogImage.ts)
- Canonical/sitemap emitters not referencing import.meta.env.SITE
  - src/pages/sitemap.xml.ts, src/lib/seoSchema.js

## Appendix B — Suggested “unused for now” list
- test:unit (until real tests exist)
- jest tests (post Vitest migration)
- validate:footer (dev-only)

---
If you want, I can implement the ESLint flat config, patch allowlist, and switch FAQ/data validators to fs+JSON, then rerun this batch to target green status.
