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
