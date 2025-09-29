# Daedalus: Local Pipeline Tutorial (Zero-Internet Friendly)

This tutorial shows you how to run the Daedalus pipeline locally, offline, and with clear, copyable commands. It explains what each step does, where files go, and how to get reports and visible changes.


## Quick start (copy/paste)

```bash
# From the repo root
cd /workspaces/moew24

# 1) Build with full pipeline (pages + reports)
node scripts/daedalus/cli.mjs build

# 2) Build with strict policy (reciprocity, tighter caps) for visible link changes
node scripts/daedalus/cli.mjs build --strict=true --cap=2 --neighborsMax=4

# 3) Target one page to iterate fast
node scripts/daedalus/cli.mjs build --only=bond-cleaning/springfield-lakes

# 4) View reports
ls -1 __reports/daedalus
sed -n '1,120p' __reports/daedalus/summary.txt
sed -n '1,120p' __reports/daedalus/link-optimization.json
```


## What Daedalus is (code-level)

- Entry: `scripts/daedalus/cli.mjs` (Node ESM)
- Core: `scripts/daedalus/core/`
  - `context.mjs` → loads config/datasets, builds targets (service × suburb)
  - `plugins.mjs` → loads/executes plugins with lifecycle hooks
  - `pipeline.mjs` → selects steps based on mode (plan/graph/build)
- Pipeline: `scripts/daedalus/pipelines/geo-build.mjs`
  - Steps (in order):
    1. `01-load-geo` → sanity counts
    2. `02-derive-graph` → graph hygiene (nonreciprocal/islands)
    3. `07-auto-fix-graph` → fixes reciprocity/islands, updates adjacency + report
    4. `05-internal-links` → weighted neighbor selection
    5. `08-optimize-links` → rebalances inbound links (cap), writes optimization report
    6. `03-emit-jsonld` → structured data per page
    7. `04-write-pages` → writes Astro pages with JSON‑LD and nearby areas
    8. `06-quality-gates` → writes issues/links/metrics
    9. `09-run-summary` → writes a human-friendly summary
- Tools:
  - `scripts/daedalus/tools/policy-sweeper.mjs` → tries weight variants and ranks fairness/locality


## Outputs and where they go

- Pages:
  - `src/pages/services/<service>/<suburb>/index.astro`
  - Nearby areas reflect the internal-links/optimizer selections
- Reports: `__reports/daedalus/`
  - `summary.txt` / `summary.json` → run overview (pages, links, metrics, sample pages)
  - `issues.json` → hygiene issues
  - `links.json` → per-page neighbor selections
  - `metrics.json` → counts + key gauges
  - `auto-fix.json` → reciprocity/island fixes including changes applied
  - `link-optimization.json` → substitutions/removals & before/after inbound Gini
  - `policy.sweep.json` / `.md` → weight sweep ranking (if ran)


## Running modes and flags

- Modes
  - `plan` / `graph` → runs analysis steps only (no JSON‑LD/pages)
  - `build` → full pipeline (JSON‑LD + pages + reports)

- Common flags (CLI args override config policies)
  - `--only=<service>/<suburb>` → build a single target
  - `--cluster=<clusterId>` → restrict targets by cluster
  - `--outDir=<path>` → write pages to a custom directory (e.g. `tmp/services`)
  - Policy flags:
    - `--strict=true` → enforce reciprocity, constrain neighbor counts
    - `--reciprocity=true` → require reciprocal adjacency for internal links
    - `--cap=<n>` → global inbound link cap for fair distribution
    - `--neighborsMax=<n>` / `--neighborsMin=<n>` → control list length

Examples:

```bash
# Analysis only (fast):
node scripts/daedalus/cli.mjs plan

# Full build with fair linking and clearly visible changes:
node scripts/daedalus/cli.mjs build --strict=true --cap=1 --neighborsMax=3 --neighborsMin=1

# Write pages to a temp, ignored folder (keeps git clean):
node scripts/daedalus/cli.mjs build --outDir=tmp/services
```


## Offline operation (no internet)

Once `node_modules` is present, the pipeline runs fully offline: all inputs and outputs are local files.

- Optional one-time prep (while online) to cache dependencies:

```bash
# Install dependencies once and cache locally
npm config set cache .npm-cache
npm ci

# Later/on the same machine you can re-install without the internet:
# npm ci --offline
```

- Run everything offline:

```bash
# Full build (offline once node_modules exist)
node scripts/daedalus/cli.mjs build

# Strict demo run to produce clear link changes/removals
node scripts/daedalus/cli.mjs build --strict=true --cap=1 --neighborsMax=3 --neighborsMin=1

# Review reports (offline)
ls -1 __reports/daedalus
sed -n '1,120p' __reports/daedalus/summary.txt
sed -n '1,200p' __reports/daedalus/link-optimization.json
```


## Policy Sweeper (tiny) — explore weights offline

```bash
# Run the weight sweeper and print JSON to stdout
node scripts/daedalus/tools/policy-sweeper.mjs --variants=small --json

# Artifacts
ls -1 __reports/daedalus | sed -n '1,50p'
```

The sweeper ranks by:
- Inbound Gini (fairness, lower is better)
- Avg distance in km (locality, lower is better)
- Cluster purity (higher is better)


## File map (you’ll touch these most)

- CLI: `scripts/daedalus/cli.mjs`
- Core: `scripts/daedalus/core/{context,pipeline,plugins}.mjs`
- Pipeline: `scripts/daedalus/pipelines/geo-build.mjs`
- Plugins (extensible):
  - `01-load-geo.mjs`
  - `02-derive-graph.mjs`
  - `07-auto-fix-graph.mjs`
  - `05-internal-links.mjs`
  - `08-optimize-links.mjs`
  - `03-emit-jsonld.mjs`
  - `04-write-pages.mjs`
  - `06-quality-gates.mjs`
  - `09-run-summary.mjs`
- Tools: `scripts/daedalus/tools/policy-sweeper.mjs`
- Datasets (inputs): `src/data/areas.adj.json`, `src/data/areas.clusters.json`, `src/data/suburbs.meta.json`
- Generated pages: `src/pages/services/<service>/<suburb>/index.astro`
- Reports: `__reports/daedalus/`


## Make changes and see them

- Adjust adjacency or meta, re-run build, then diff:

```bash
git --no-pager status --porcelain
```

- If you want generated files ignored during experiments, either:

```bash
# Use a temp outDir that’s already ignored by .gitignore
node scripts/daedalus/cli.mjs build --outDir=tmp/services
```

or add ignore patterns yourself (optional):

```bash
# Example .gitignore additions (optional)
__reports/
.astro/
```


## Troubleshooting

- “Cannot find module” or ESM import errors
  - Ensure Node 18+ and run from repo root
  - Make sure `node_modules` exists (`npm ci`) before going offline
- No pages generated
  - You ran `plan`/`graph` mode. Use `build`
  - Your filters excluded all targets (`--only`, `--cluster`)
- Optimizer didn’t change anything
  - Use stricter flags: `--strict=true --cap=1 --neighborsMax=3 --neighborsMin=1`
- Too many untracked files from page gen
  - Use `--outDir=tmp/services` to write to a temp, ignored folder


## Extend it (optional)

- Add a new plugin under `scripts/daedalus/plugins/NN-your-plugin.mjs`
- Insert it into `scripts/daedalus/pipelines/geo-build.mjs` where appropriate
- Use hooks: `init`, `beforeAll`, `eachNode`, `afterAll`

```js
export default {
  id: '10-my-plugin',
  async beforeAll(ctx) { /* prep */ },
  async eachNode(ctx, node) { /* per target */ },
  async afterAll(ctx) { /* write reports */ }
};
```


## One-liners you’ll reuse

```bash
# Full build with strict + cap
node scripts/daedalus/cli.mjs build --strict=true --cap=2 --neighborsMax=4

# Single target
node scripts/daedalus/cli.mjs build --only=bond-cleaning/springfield-lakes

# Temp outDir (keep git clean)
node scripts/daedalus/cli.mjs build --outDir=tmp/services

# Inspect reports
ls -1 __reports/daedalus | sed -n '1,50p'
sed -n '1,120p' __reports/daedalus/summary.txt
sed -n '1,200p' __reports/daedalus/link-optimization.json
```

You’re set. Run builds, read the reports, and iterate—all locally and without internet.
