#!/usr/bin/env bash
# merge_linking_ctx.sh — merge astro_props_linking_pack + geo_page_ctx_bundle into current repo
set -euo pipefail

PACK_PROPS="${1:-./astro_props_linking_pack.zip}"
PACK_CTX="${2:-./geo_page_ctx_bundle.zip}"

echo ">> Using props pack: ${PACK_PROPS}"
echo ">> Using ctx bundle: ${PACK_CTX}"

# unzip with overwrite (-o) but keep backups of any existing files
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

unzip -q -o "$PACK_PROPS" -d "$tmpdir/props"
unzip -q -o "$PACK_CTX"   -d "$tmpdir/ctx"

# Stage into repo root
rsync -a "$tmpdir/props/" ./
rsync -a "$tmpdir/ctx/"   ./

# Merge package.json scripts (alias geo:ctx to geo:pagectx if missing jq)
if command -v jq >/dev/null 2>&1; then
  echo ">> Merging package.json scripts with jq"
  tmp_pkg="$(mktemp)"
  jq '
    .scripts = (.scripts // {}) + {
      "geo:pagectx": (.scripts["geo:pagectx"] // "node scripts/geo/page-context.mjs"),
      "geo:pagectx:check": (.scripts["geo:pagectx:check"] // "node scripts/geo/page-context.mjs --check-only"),
      "geo:pagectx:stats": (.scripts["geo:pagectx:stats"] // "node scripts/geo/page-context.mjs --stats"),
      "geo:ctx": (.scripts["geo:ctx"] // "node scripts/geo/build-page-context.mjs"),
      "geo:adj": (.scripts["geo:adj"] // "node scripts/geo/build-adjacency.mjs"),
      "geo:full": (.scripts["geo:full"] // "npm run geo:adj && npm run geo:ctx")
    }
  ' package.json > "$tmp_pkg" && mv "$tmp_pkg" package.json
else
  echo ">> jq not found; ensure these entries exist in package.json scripts:"
  cat <<'EOF'
"geo:pagectx": "node scripts/geo/page-context.mjs",
"geo:pagectx:check": "node scripts/geo/page-context.mjs --check-only",
"geo:pagectx:stats": "node scripts/geo/page-context.mjs --stats",
"geo:ctx": "node scripts/geo/build-page-context.mjs",
"geo:adj": "node scripts/geo/build-adjacency.mjs",
"geo:full": "npm run geo:adj && npm run geo:ctx"
EOF
fi

echo ">> Done. Next steps:"
echo "   1) npm run geo:adj"
echo "   2) npm run geo:pagectx  # or npm run geo:ctx"
echo "   3) ls -1 src/gen/ __reports/ | sed -n '1,120p'"
