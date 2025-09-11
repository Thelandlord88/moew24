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
