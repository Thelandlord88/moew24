#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

# Packages Daedalus + Hunter essentials into:
#  - bundles/daedalus-hunter/package/daedalus-hunter-starter.tar.gz
#  - bundles/daedalus-hunter/package/daedalus_hunter_boot.sh (self-extracting)

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT_DIR="$ROOT/bundles/daedalus-hunter/package"
STAGE_DIR="$OUT_DIR/stage"
ARCHIVE="$OUT_DIR/daedalus-hunter-starter.tar.gz"
BOOT="$OUT_DIR/daedalus_hunter_boot.sh"

rm -rf "$OUT_DIR"
mkdir -p "$STAGE_DIR"

copy_file() {
  # $1 src (root-relative), $2 dest (root-relative inside stage)
  local src_rel="$1" dest_rel="$2"
  local src="$ROOT/${src_rel#./}" dest="$STAGE_DIR/${dest_rel#./}"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
  fi
}

# Engine core
copy_file scripts/daedalus/cli.mjs               scripts/daedalus/cli.mjs
copy_file scripts/daedalus/core/context.mjs      scripts/daedalus/core/context.mjs
copy_file scripts/daedalus/core/pipeline.mjs     scripts/daedalus/core/pipeline.mjs
copy_file scripts/daedalus/core/plugins.mjs      scripts/daedalus/core/plugins.mjs
copy_file scripts/daedalus/util/log.mjs          scripts/daedalus/util/log.mjs
copy_file scripts/daedalus/pipelines/geo-build.mjs scripts/daedalus/pipelines/geo-build.mjs

# Analysis plugins + tool
for p in 02-derive-graph 05-internal-links 07-auto-fix-graph 08-optimize-links 09-run-summary 06-quality-gates; do
  copy_file "scripts/daedalus/plugins/${p}.mjs" "scripts/daedalus/plugins/${p}.mjs"
done
copy_file scripts/daedalus/tools/policy-sweeper.mjs scripts/daedalus/tools/policy-sweeper.mjs

# Systems health API
for f in daedalus.json.js hunter.json.js manifest.json.js; do
  copy_file "src/pages/api/systems/${f}" "src/pages/api/systems/${f}"
done

# Personalities & profiles
for f in daedalus.json hunter.json manifest.json; do
  copy_file "profiles/${f}" "profiles/${f}"
done
for f in daedalus.learning.personality.v1_0_1.json hunter.learning.personality.v1_0_1.json; do
  copy_file "personalities/${f}" "personalities/${f}"
done
for f in daedalus.json hunter.json manifest.json; do
  copy_file "personalities/daedalus_personalities_pack/profiles/${f}" "personalities/daedalus_personalities_pack/profiles/${f}"
done

# Root AI helper scripts
for f in ai-enhance-daedalus.mjs ai-enterprise-deployment.mjs ai-fix-gates.mjs ai-geo-builder.mjs; do
  copy_file "$f" "$f"
done

# Hunter utilities
for f in enhance-hunter.mjs personality-loader.mjs test-suite.mjs \
         intelligence-analyzer.mjs intelligence-analyzer-v2.mjs intelligence-analyzer-v2.1.mjs intelligence-analyzer-v2.2.mjs \
         evolution-engine-v2.mjs evolution-engine-v3.mjs; do
  copy_file "scripts/personalities/${f}" "scripts/personalities/${f}"
done

# Docs
for f in README.md docs/README.md docs/DAEDALUS_TUTORIAL.md AI_AGENT_ONBOARDING_GUIDE.md AI_WORKFLOW_DEBRIEF.md; do
  copy_file "$f" "$f"
done

# Starter README
cat > "$STAGE_DIR/DAEDALUS_HUNTER_STARTER.md" <<'MD'
# Daedalus + Hunter Starter

This package contains the Daedalus engine, analysis plugins, health endpoints, profiles/personality JSONs, and Hunter utilities. Extract into a new repo root.

Quick start:
- Node 18+
- Install your own package.json and dependencies as needed
- Run: node scripts/daedalus/cli.mjs build

Included:
- scripts/daedalus/**
- src/pages/api/systems/**
- profiles/** and personalities/** (selected)
- scripts/personalities/** (hunter utilities)
- ai-*.mjs at repo root
- docs (tutorial + guides)
MD

# Create archive
(cd "$STAGE_DIR" && tar -czf "$ARCHIVE" .)

# Generate self-extracting boot script
cat > "$BOOT" <<'BOOT'
#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

DEST="${1:-.}"
ARCHIVE_NAME="daedalus-hunter-starter.tar.gz"
echo "[boot] Extracting Daedalus + Hunter starter into: $DEST"
mkdir -p "$DEST"
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BELOW__$/ {print NR + 1; exit 0; }' "$0")
tail -n +$PAYLOAD_LINE "$0" | base64 -d > "$DEST/$ARCHIVE_NAME"
tar -xzf "$DEST/$ARCHIVE_NAME" -C "$DEST"
rm -f "$DEST/$ARCHIVE_NAME"
echo "[boot] Done. Contents extracted under $DEST/"
exit 0
__PAYLOAD_BELOW__
BOOT

# Append base64 payload
base64 "$ARCHIVE" >> "$BOOT"
chmod +x "$BOOT"

echo "Packaged: $ARCHIVE"
echo "Boot script: $BOOT"
