#!/usr/bin/env bash
# implement-packs-and-seeds.sh
# One-shot writer that generates two wrapper scripts and a seed generator:
#   scripts/implement-lift-pack.sh
#   scripts/implement-visibility-pack.sh
#   scripts/seed-smoke-from-coverage.mjs
#
# Idempotent: safe to re-run. Requires Node ≥20.

set -euo pipefail
ROOT_DIR=${1:-.}
SCRIPTS_DIR="$ROOT_DIR/scripts"
SUITE_REL="scripts/transparent-suite.mjs"

mkdir -p "$SCRIPTS_DIR"

need_node20() {
  if ! command -v node >/dev/null 2>&1; then
    echo "[setup] Node is required (>=20)" >&2; exit 1; fi
  v=$(node -p "process.versions.node.split('.')")
  major=$(node -p "process.versions.node.split('.')[0]")
  if [ "$major" -lt 20 ]; then
    echo "[setup] Node $(node -v) detected; please use Node 20.x" >&2; exit 2; fi
}

write_seed_js() {
  cat > "$SCRIPTS_DIR/seed-smoke-from-coverage.mjs" <<'NODEEOF'
#!/usr/bin/env node
/**
 * seed-smoke-from-coverage.mjs
 * Generates __geo/smoke.seeds.json from live coverage config.
 * Looks for (in order):
 *   - src/data/serviceCoverage.json  (Object<serviceId, string[] suburbSlugs>)
 *   - src/data/areas.clusters.json + src/data/suburbs*.{json,geojson}
 * Fallback services: ['spring-clean','bathroom-deep-clean']
 */
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.argv[2] || '.';
const OUTDIR = path.join(ROOT, '__geo');
const ensure = (p)=>{fs.mkdirSync(p,{recursive:true})};
const rel = (p)=>path.relative(ROOT,p).replaceAll('\\','/');

async function readJson(p){ try { return JSON.parse(await fsp.readFile(p,'utf8')); } catch { return null; } }
function asFeatures(input){ if(!input) return []; if(input.type==='FeatureCollection') return input.features||[]; if(Array.isArray(input)) return input.map(x=>({type:'Feature',properties:x,geometry:null})); return []; }
function propsOf(f){ return f.properties||{}; }

async function findFirst(paths){ for (const p of paths){ const abs=path.join(ROOT,p); if (fs.existsSync(abs)) return abs; } return null; }

const svcCoveragePath = await findFirst(['src/data/serviceCoverage.json']);
const clustersPath = await findFirst(['src/data/areas.clusters.json','src/data/clusters.json']);
const suburbsPath = await findFirst(['src/data/suburbs_enriched.geojson','src/data/suburbs.geojson','src/data/suburbs_enriched.json','src/data/suburbs.json']);

const servicesDefault = ['spring-clean','bathroom-deep-clean'];

const seeds = new Set();
if (svcCoveragePath) {
  const cov = await readJson(svcCoveragePath);
  for (const [svc, arr] of Object.entries(cov||{})) {
    for (const sub of (arr||[])) {
      const s = String(sub).toLowerCase();
      seeds.add(`/services/${svc}/${s}/`);
      seeds.add(`/suburbs/${s}/`);
    }
  }
} else {
  // Build from clusters + suburb list
  const clusters = clustersPath ? (await readJson(clustersPath)) : {};
  const features = suburbsPath ? asFeatures(await readJson(suburbsPath)) : [];
  const allSubs = new Set();
  for (const f of features) {
    const p = propsOf(f); const key = (p.slug||p.name_official||p.name||'').toLowerCase().trim();
    if (key) allSubs.add(key);
  }
  const sampleSubs = Array.from(allSubs).slice(0, 50); // cap
  for (const svc of servicesDefault) {
    for (const s of sampleSubs) {
      seeds.add(`/services/${svc}/${s}/`);
    }
  }
  for (const s of sampleSubs) seeds.add(`/suburbs/${s}/`);
}

ensure(OUTDIR);
const outFile = path.join(OUTDIR,'smoke.seeds.json');
await fsp.writeFile(outFile, JSON.stringify(Array.from(seeds).sort(), null, 2)+'\n','utf8');
console.log(rel(outFile));
NODEEOF
  chmod +x "$SCRIPTS_DIR/seed-smoke-from-coverage.mjs"
}

write_lift_wrapper() {
  cat > "$SCRIPTS_DIR/implement-lift-pack.sh" <<'SHEOF'
#!/usr/bin/env bash
# implement-lift-pack.sh — wires transparent suite + runs geo doctor/build/guard/smoke
set -euo pipefail
ROOT=${1:-.}
SUITE="$ROOT/scripts/transparent-suite.mjs"
if [ ! -f "$SUITE" ]; then echo "[lift] Missing $SUITE. Please add it first." >&2; exit 1; fi
node "$SUITE" bootstrap --root "$ROOT"
# Optional: do a build first if you want guard to scan dist; comment out if CI builds separately
if [ ! -d "$ROOT/dist" ]; then echo "[lift] Building site…"; npm run build --silent || npx astro build; fi
node "$SUITE" geo:all --root "$ROOT" --out "$ROOT/__geo" --strict
echo "[lift] Done. See __geo/REPORT.md"
SHEOF
  chmod +x "$SCRIPTS_DIR/implement-lift-pack.sh"
}

write_visibility_wrapper() {
  cat > "$SCRIPTS_DIR/implement-visibility-pack.sh" <<'SH2EOF'
#!/usr/bin/env bash
# implement-visibility-pack.sh — post-build visibility gates + seeded smoke checks
set -euo pipefail
ROOT=${1:-.}
MAX_MISSING=${MAX_MISSING:-0}   # threshold for missing canonical/JSON-LD
SUITE="$ROOT/scripts/transparent-suite.mjs"
SEED_GEN="$ROOT/scripts/seed-smoke-from-coverage.mjs"
if [ ! -f "$SUITE" ]; then echo "[vis] Missing $SUITE. Please add it first." >&2; exit 1; fi
if [ ! -d "$ROOT/dist" ]; then echo "[vis] Building site…"; npm run build --silent || npx astro build; fi

# Run core visibility CI (canonical + JSON-LD)
node "$SUITE" vis:ci --root "$ROOT" --out "$ROOT/__geo" --strict --max-missing "$MAX_MISSING"

# Generate service/suburb seeds from live coverage and verify presence in dist
if [ -f "$SEED_GEN" ]; then
  SEEDS_FILE=$(node "$SEED_GEN" "$ROOT")
  echo "[vis] Seeds file: $SEEDS_FILE"
  MISSING=0
  while IFS= read -r url; do
    # strip quotes/commas in case of raw JSON lines
    clean=${url//\"/}
    clean=${clean//,/}
    clean=${clean//[\[\]]/}
    clean=$(echo "$clean" | sed 's/^ *//;s/ *$//')
    [ -z "$clean" ] && continue
    path_in_dist="$ROOT/dist/${clean#/}/index.html"
    if [ ! -f "$path_in_dist" ]; then
      echo "[vis] MISSING: $clean -> $path_in_dist" >&2
      MISSING=$((MISSING+1))
    fi
  done < <(jq -r '.[]' "$SEEDS_FILE" 2>/dev/null || cat "$SEEDS_FILE")
  if [ "$MISSING" -gt 0 ]; then
    echo "[vis] Seeded smoke check failed: $MISSING page(s) missing in dist" >&2
    exit 3
  fi
else
  echo "[vis] Seed generator not found ($SEED_GEN); skipping seeded smoke check."
fi

echo "[vis] Visibility checks passed. Snapshot + report in __geo/"
SH2EOF
  chmod +x "$SCRIPTS_DIR/implement-visibility-pack.sh"
}

need_node20
write_seed_js
write_lift_wrapper
write_visibility_wrapper

echo "[ok] Wrote:"
echo "  - $SCRIPTS_DIR/seed-smoke-from-coverage.mjs"
echo "  - $SCRIPTS_DIR/implement-lift-pack.sh"
echo "  - $SCRIPTS_DIR/implement-visibility-pack.sh"
echo "Usage:"
echo "  bash implement-packs-and-seeds.sh ."
echo "  scripts/implement-lift-pack.sh ."
echo "  MAX_MISSING=0 scripts/implement-visibility-pack.sh ."
