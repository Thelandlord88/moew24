# Daedalus — Level 1 (Geo Builder, Hunter‑grade Discipline)

Daedalus is a plugin‑driven geo **builder** that turns your datasets (clusters, adjacency, meta) into
deterministic **service × suburb** Astro pages with JSON‑LD, internal links, and quality gates.

## Commands

```bash
# Dry planning (graph hygiene + internal link plan + reports, no page writes)
node scripts/daedalus/cli.mjs plan

# Full build (loads → derive → internal-links → jsonld → write → gates → report)
node scripts/daedalus/cli.mjs build

# Build one target
node scripts/daedalus/cli.mjs build --only=bond-cleaning/springfield-lakes

# Filter by cluster id
node scripts/daedalus/cli.mjs build --cluster=ipswich
```

Reports are written to `__reports/daedalus/`:
- `metrics.json` (counts)
- `issues.json` (nonreciprocal edges, islands)
- `links.json` (per-page neighbors plan)

Generated pages go to `src/pages/services/<service>/<suburb>/index.astro` (unless `--outDir`).

## File expectations

Daedalus expects (relative to repo root):

```
src/data/areas.clusters.json
src/data/areas.adj.json
# optional
src/data/suburbs.meta.json
```

Example inputs are in `example-data/`. Copy them to `src/data/` to try immediately:

```bash
mkdir -p src/data
cp -n example-data/* src/data/
```

## Netlify integration (example)

Add a dedicated build step so the pages exist before Astro’s build:

**Option A — `netlify.toml`**
```toml
[build]
command = "node scripts/daedalus/cli.mjs build && npm run build"
publish = "dist"
```

**Option B — npm scripts**
```json
{
  "scripts": {
    "prebuild": "node scripts/daedalus/cli.mjs build",
    "build": "astro build"
  }
}
```

> Ensure your project is ESM (`"type": "module"`) so `.mjs` works.

## Package.json additions

Merge the following into your `package.json`:
```json
{
  "type": "module",
  "scripts": {
    "daedalus:plan": "node scripts/daedalus/cli.mjs plan",
    "daedalus:build": "node scripts/daedalus/cli.mjs build"
  }
}
```

## Philosophy

- **Upstream‑curious**: never hand‑edit generated pages; fix inputs or generator logic.
- **Deterministic**: identical inputs → identical outputs; reports are diff‑friendly.
- **Guardrailed**: quality gates detect class issues (reciprocity, islands) early.

---

© You. Go ship it.
