# Build & Guard Failures — Troubleshooting Playbook

This project ships with several fast, deterministic gates to keep builds stable: schema & graph validation, parity checks, CSS governance, dynamic route safety, and a smoke crawler. This playbook shows how to read the logs, what each failure means, and the exact command to fix it.

## TL;DR

**Run**: `npm run prebuild && npm run build`

- If the failure mentions **cssBas### Gotchas: JSON import attributes ✅ **FIXED**

### ~~Symptom (warning)~~

~~[vite] tried to import ".../adjacency.json" with "type": "json" attributes,
but elsewhere with no attributes~~

### ~~Fix~~

~~Make all JSON imports consistent — remove `assert { type: 'json' }` across the repo~~

**Status**: ✅ All JSON import attributes have been standardized to bare imports across the codebase.r make the baseline hash-tolerant
- If it mentions **adjacency or clusters** → normalize or fix edges  
- If it mentions **parity** → diff precompute vs runtime and resolve mismatches
- If it mentions **ts-node on Node 22** → switch to tsx or .mjs

## Table of contents

1. [Environment & runtimes](#environment--runtimes)
2. [Data validation (Zod)](#data-validation-zod)
3. [Graph & adjacency](#graph--adjacency)
   - [Integrity (graph-sanity)](#integrity-graph-sanity)
   - [Symmetry (adjacency-symmetry)](#symmetry-adjacency-symmetry)
   - [Fixer (fix-adjacency)](#fixer-fix-adjacency)
4. [Cross-service parity & buildability](#cross-service-parity--buildability)
5. [Dynamic route guard](#dynamic-route-guard)
6. [FAQ compiler/verify](#faq-compilerverify)
7. [CSS governance](#css-governance)
   - [One-global](#one-global)
   - [Baseline](#baseline)
   - [Duplicates](#duplicates)
   - [Budgets](#budgets)
8. [Smoke crawler](#smoke-crawler)
9. [Link checker & LD consolidation](#link-checker--ld-consolidation)
10. [Common exit codes & meanings](#common-exit-codes--meanings)
11. [Gotchas: JSON import attributes](#gotchas-json-import-attributes)
12. [Daily workflow checklist](#daily-workflow-checklist)

---

## Environment & runtimes

**Node**: Pin the same version locally and in CI/Netlify.

Add one (choose your favorite):
- `.nvmrc` → `20`
- `package.json` → `"engines": { "node": "20.x" }`
- `netlify.toml` → `[build.environment] NODE_VERSION = "20"`

**ESM + TS**: Prefer `tsx` over `ts-node` for CLI scripts on Node ≥ 18.
- In package.json scripts: `tsx tools/your-script.ts`
- For pure JS tools use `.mjs` (Node ESM).

**Paths**: Typescript paths (`~/*`) are supported by `tsconfig-paths/register` or native with `moduleResolution: "NodeNext"`.

---

## Data validation (Zod)

### What you see

```
validate-data.zod OK
```

or failures like:

```
clusters.json schema invalid: ...
Unknown coverage tokens:
[service] 'Brisbane West' → 'brisbane-west'
```

### Meaning
Your core JSONs must match strict shapes and semantics:
- `areas.clusters.json` (either union shape A or B)
- `serviceCoverage.json`
- `adjacency.json` (two supported shapes)

### Fix now
- **Typos** → correct tokens or slugify inputs.
- **Unknown coverage token** → ensure it's either a suburb or a cluster slug.

### Fix right
Enable strict authoring later:
```bash
STRICT_MODE=1 npm run lint:data
```
This enforces author-written slugs (kebab-case) instead of auto-slugifying.

### Commands
```bash
npm run lint:data
```

---

## Graph & adjacency

### Integrity (graph-sanity)

#### What you see

```
🔍 Checking adjacency vs cluster integrity...
✅ Graph data integrity OK
```

or:

```
MISSING NODE: st-lucia-qld
CROSS EDGE: redbank-plains(ipswich) -> kenmore(brisbane)
```

#### Meaning
Every adjacency entry must map to a known suburb & cluster; no cross-cluster edges.

#### Fix now
Use the fixer (below) with `--write` to normalize and mirror edges; drop cross edges.

#### Fix right
Update your source adjacency so it's consistent with clusters (no cross links).

#### Commands
```bash
npm run lint:graph
```

### Symmetry (adjacency-symmetry)

#### What you see

```
adjacency-symmetry OK
```

or:

```
ASYM: kenmore lists indooroopilly but indooroopilly does not list kenmore
```

#### Meaning
If the graph is intended to be undirected, every edge must be mirrored.

#### Fix now
```bash
npm run fix:adjacency:write
```

#### Commands
```bash
npm run lint:adj
```

### Fixer (fix-adjacency)

#### What you see

```
fix-adjacency summary: { ... "mirrored_edges_added": 53, ... }
```

#### Meaning
The fixer normalized keys/values to slugs, added missing mirrors, dropped forbidden cross-cluster edges (if configured).

#### Commands
```bash
npm run fix:adjacency     # dry-run
npm run fix:adjacency:write
```

---

## Cross-service parity & buildability

### What you see

```
diff-cross-service OK (sample)
```

or:

```
[preonly] kenmore -> spring-cleaning/forest-lake
[adapteronly] kenmore -> spring-cleaning/kenmore
```

### Meaning
Runtime adapter (`getCrossServiceItemsForSuburb`) doesn't match precomputed `crossServiceMap.json`, or a page would be generated that isn't buildable (no coverage token path).

### Fix now
Rebuild the map (prebuild does this): `npm run build:map`

If still mismatched, check:
- `serviceCoverage.json` expansion
- Nearby BFS returning a fallback not present in coverage expansion

### Fix right
Keep coverage expansion logic & BFS consistent and deterministic.

When changing logic, regenerate the map and update tests.

### Commands
```bash
npm run lint:cross                 # sample locally
FULL_PARITY=1 npm run lint:cross   # full (use in CI)
```

---

## Dynamic route guard

### What you see

```
🛡️  Checking dynamic routes...
✅ All dynamic routes look good
```

or:

```
UNTRACKED dynamic file: src/pages/services/[service]/[suburb].astro
Missing getStaticPaths or prerender=false: ...
```

### Meaning
Every dynamic page is either SSG with `getStaticPaths()` or explicitly SSR (`export const prerender = false`) and tracked in git.

### Fix now
- Add `getStaticPaths` (for SSG) or `prerender=false` (for pure SSR).
- Ensure the file is committed.

### Commands
```bash
npm run guard:routes
```

---

## FAQ compiler/verify

### What you see

```
[faqs] Wrote ...faqs.compiled.json
✅ FAQ verification passed! ... Warnings: N
```

### Meaning
Warnings are okay (non-fatal); a failure means either invalid structure or missing required fields.

### Commands
```bash
npm run build:faqs
npm run verify:faqs
```

---

## CSS governance

### One-global

#### What you see

```
[cssOneGlobal] One global bundle ✓ index.XYZ.css: 1/1
```

#### Meaning
Global styles are consolidated in one big chunk; others are route-scoped.

#### Fix now
If it fails, eliminate extra global imports or move them to route bundles.

#### Commands
```bash
GUARD_MODE=ci node scripts/guard/run-css-one-global.mjs
```

### Baseline

#### What you see (failure)

```
[cssBaseline] ❌ New CSS file appeared: index.CB4C9mE7.css (87.7KB)
```

#### Meaning
Chunk hash changed (rename) or size drifted beyond tolerance vs baseline. On Netlify this often happens because minifier order differs from local.

#### Fix now (accept rename)
```bash
npm run build
npm run css:baseline:write
git add tools/baseline/css.json && git commit -m "chore(css): refresh baseline" && git push
```

#### Fix right (recommended) ✅ **IMPLEMENTED**
~~Use a hash-tolerant baseline checker that ignores file names and compares size multisets & totals within a tolerance.~~ **This project now uses a hash-tolerant baseline checker that ignores file names and compares size multisets & totals within a tolerance.**

The current baseline checker (`tools/check-css-baseline.mjs`) treats hash renames as acceptable noise and only fails on real regressions:
- File count changes
- Total size changes beyond 2KB tolerance  
- Individual file size changes beyond 1KB tolerance

#### Commands
```bash
npm run css:baseline:check
npm run css:baseline:write
# 🆕 Enhanced version with semantic diff
npm run css:baseline:enhanced
```

### Duplicates

#### What you see

```
[audit-css-duplicates] ✅ Only one large CSS file contains global classes.
```

or a list of duplicate signatures across files.

#### Fix
Consolidate global classes into the main bundle; avoid duplicating utility layers.

#### Commands
```bash
node scripts/audit-css-duplicates.mjs
```

### Budgets

#### What you see

```
[audit-css-budgets] { totalKB, maxKB, largest: [...] }
[audit-css-budgets] ✅ Budgets OK
```

#### Fix
If failing, reduce CSS or raise budgets with justification.

#### Commands
```bash
node scripts/audit-css-budgets.mjs
```

---

## Smoke crawler

### What you see

```
smoke-crawl OK
```

or:

```
Smoke crawl failures:
404 /services/bond-cleaning/.../
```

### Meaning
After build, a small set of important pages should 200. Local-guides 404s are tolerated by design (optional feature).

### Fix
Ensure the route exists in `getStaticPaths` output (precompute/coverage), and the page renders without runtime errors.

### Commands
```bash
npm run build && npm run smoke:crawl
```

---

## Link checker & LD consolidation

### What you see

```bash
node scripts/consolidate-ld.mjs
node scripts/audit-related-links.mjs
npm run check:links
```

### Meaning
Structured data and internal link integrity. Failures point to missing or malformed JSON-LD blocks or broken internal links.

### Common Failure: Service/Suburb Page Mismatches ✅ **FIXED**

**Previous Issue**: 
```
❌ Missing file for link: /services/bond-cleaning/booval/ -> dist/services/bond-cleaning/booval/index.html
❌ Missing file for link: /services/spring-cleaning/springfield/ -> dist/services/spring-cleaning/springfield/index.html
```

**Root Cause**: `getStaticPaths` in `src/pages/services/[service]/[suburb].astro` was using `allSuburbs()` (8 popular suburbs) but link generation used `serviceCoverage.json` (187 combinations).

**Solution Applied**: Updated `getStaticPaths` to use `serviceCoverage.json` for consistency.
- **Before**: 8 service pages for popular suburbs only
- **After**: 190 service pages for all covered suburbs
- **Result**: New suburbs automatically get service pages when added to coverage

### Fix
Update or remove invalid LD blocks; correct link slugs.

### Commands
```bash
npm run check:links
```

---

## Common exit codes & meanings

- **Exit 1**: Generic failure from a guard or script (baseline mismatch, schema invalid, parity mismatch, link check fail, etc.).
- **Exit 2**: Netlify/Vite/adapter wrapping of a non-zero exit; often the same as Exit 1 but surfaced during a particular stage (e.g., "Build script returned non-zero exit code: 2").

### ts-node ESM loader error:

```
TypeError: Unknown file extension ".ts" ...
```

Switch the script to `tsx` or convert to `.mjs`.

### Runtime loader fixes

**Prefer**:
```json
{ "scripts": {
  "lint:data": "tsx tools/validate-data.zod.ts",
  "lint:adj":  "node tools/adjacency-symmetry.mjs",
  "lint:cross":"tsx tools/diff-cross-service.ts"
}}
```

**Avoid** `node -r ts-node/register` on Node 20/22 unless you configure `ts-node/esm` correctly.

---

## Top 7 repo-specific checks & fixes ✅ **ALL IMPLEMENTED**

### 1. **Pin Node everywhere (Netlify + local)** ✅ **COMPLETE**

**Status**: Node.js 20 pinned in:
- ✅ `.nvmrc` → `20`
- ✅ `package.json` → `"engines": { "node": "20.x" }`  
- ✅ `netlify.toml` → `[build.environment] NODE_VERSION = "20"`

### 2. **Make every CLI script either `.mjs` or `tsx`** ✅ **COMPLETE**

**Status**: All 12 TypeScript tools converted from ts-node shebangs to tsx:
- ✅ `tools/validate-data.zod.ts`, `tools/diff-cross-service.ts`, etc.
- ✅ All package.json scripts use `tsx` for .ts files, `node` for .mjs files
- ✅ No remaining ts-node/register patterns

### 3. **Unify JSON import style** ✅ **COMPLETE**

**Status**: All JSON import assertions removed:
- ✅ Static imports: 8 files cleaned (`repSuburb.ts`, `geoHandler.js`, etc.)
- ✅ Dynamic imports: 2 files cleaned (`repSuburb.ts`, `nearbyCovered.ts`)
- ✅ No remaining `assert { type: 'json' }` patterns in codebase

### 4. **CSS baseline: hash-tolerant scope alignment** ✅ **COMPLETE**

**Status**: Both writer and checker scan `dist/_astro` only:
- ✅ Hash-tolerant comparison (ignores file names, compares size multisets)
- ✅ Tolerance: ±2KB total, ±1KB per file
- ✅ No more "New CSS file appeared" noise from renames

### 5. **Netlify build command: fail fast** ✅ **COMPLETE**

**Status**: Updated netlify.toml to include prebuild:
```toml
[build]
command = "npm run build:faqs && npm run prebuild && npm run build"
```
- ✅ Data/graph validation fails fast before expensive Astro build
- ✅ CSS baseline check uses hash-tolerant version

### 6. **Parity checks: sample locally, full in CI** ✅ **COMPLETE**

**Status**: Optimized for deployment speed:
- ✅ Local: `npm run lint:cross` (sample)
- ✅ CI: `FULL_PARITY=1 npm run lint:cross` (full)
- ✅ Netlify: focused on build + ship

### 7. **Exit code understanding** ✅ **DOCUMENTED**

**Status**: All exit patterns documented and resolved:
- ✅ Exit 1: CSS baseline hash rename → fixed with hash-tolerant checker
- ✅ Exit 2: Netlify wrapper for underlying exit 1 → resolved
- ✅ JSON import warnings → eliminated with consistent imports

---

## Daily workflow checklist

### Prebuild (fast data & graph gates)
```bash
npm run prebuild
```

### Build
```bash
npm run build
```

### Parity (local sample)
```bash
npm run lint:cross
```
(In CI, use full: `FULL_PARITY=1 npm run lint:cross`.)

### CSS baseline
```bash
npm run css:baseline:check
```

If it fails due to a rename:
```bash
npm run css:baseline:write && git add tools/baseline/css.json && git commit -m "chore(css): refresh baseline"
```

### 🆕 CSS Evolution Analysis
```bash
npm run css:baseline:enhanced  # Smart baseline check with semantic diff
npm run css:diff -- old.css new.css  # Manual comparison when needed
```

### Optional smoke
```bash
npm run smoke:crawl
```

---

## Appendix: Typical "fix now vs fix right"

| Gate | Fix now (green quickly) | Fix right (future-proof) |
|------|-------------------------|---------------------------|
| CSS baseline | Refresh baseline | Use hash-tolerant checker; stabilize CSS import order |
| Parity | Rebuild map, re-run | Align runtime adapter & precompute logic; add tests |
| Adjacency | Run fixer `--write` | Update source data; authors keep mirrors |
| JSON imports | Remove `assert {...}` | Enforce lint rule or grep in prebuild |
| ts-node errors | Swap to `tsx` | Migrate all tool scripts to `.ts` + `tsx` or `.mjs` |

---

## Questions or new failure types?

Add a short snippet to this doc with the log pattern and the one-liner fix so future contributors can self-serve.
