#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

# Create a browsable bundle of Daedalus + Hunter related files without moving originals.
# Uses symlinks so builds and imports remain intact.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BUNDLE_DIR="$ROOT/bundles/daedalus-hunter"

rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/{engine/core,engine/pipelines,engine/util,analysis/plugins,health/api,personalities,personalities/pack,scripted,scripted/hunter,docs}"

link_into() {
  # $1 src (absolute or root-relative), $2 dest (relative under bundle)
  local src="$1"; local dest="$2"
  if [[ "$src" != /* ]]; then src="$ROOT/${src#./}"; fi
  local dest_path="$BUNDLE_DIR/$dest"
  mkdir -p "$(dirname "$dest_path")"
  ln -srf "$src" "$dest_path"
}

# Engine core
link_into scripts/daedalus/cli.mjs               engine/cli.mjs
link_into scripts/daedalus/core/context.mjs      engine/core/context.mjs
link_into scripts/daedalus/core/pipeline.mjs     engine/core/pipeline.mjs
link_into scripts/daedalus/core/plugins.mjs      engine/core/plugins.mjs
link_into scripts/daedalus/util/log.mjs          engine/util/log.mjs
link_into scripts/daedalus/pipelines/geo-build.mjs engine/pipelines/geo-build.mjs

# Analysis-focused plugins + tools
link_into scripts/daedalus/tools/policy-sweeper.mjs        analysis/policy-sweeper.mjs
for p in 02-derive-graph 05-internal-links 07-auto-fix-graph 08-optimize-links 09-run-summary; do
  link_into "scripts/daedalus/plugins/${p}.mjs" "analysis/plugins/${p}.mjs"
done

# Health (quality gates + system API health endpoints)
link_into scripts/daedalus/plugins/06-quality-gates.mjs     health/quality-gates.mjs
for f in daedalus.json.js hunter.json.js manifest.json.js; do
  link_into "src/pages/api/systems/${f}" "health/api/${f}"
done

# Personalities (profiles + main personalities)
for f in daedalus.json hunter.json manifest.json; do
  link_into "profiles/${f}" "personalities/${f}"
done
for f in daedalus.learning.personality.v1_0_1.json hunter.learning.personality.v1_0_1.json; do
  if [[ -f "$ROOT/personalities/${f}" ]]; then link_into "personalities/${f}" "personalities/${f}"; fi
done
# Pack profiles (if present)
for f in daedalus.json hunter.json manifest.json; do
  if [[ -f "$ROOT/personalities/daedalus_personalities_pack/profiles/${f}" ]]; then
    link_into "personalities/daedalus_personalities_pack/profiles/${f}" "personalities/pack/${f}"
  fi
done

# AI helper scripts at repo root
for f in ai-enhance-daedalus.mjs ai-enterprise-deployment.mjs ai-fix-gates.mjs ai-geo-builder.mjs; do
  if [[ -f "$ROOT/${f}" ]]; then link_into "$f" "scripted/${f}"; fi
done

# Hunter-related script utilities (involvement with Daedalus)
for f in enhance-hunter.mjs personality-loader.mjs test-suite.mjs \
         intelligence-analyzer.mjs intelligence-analyzer-v2.mjs intelligence-analyzer-v2.1.mjs intelligence-analyzer-v2.2.mjs \
         evolution-engine-v2.mjs evolution-engine-v3.mjs; do
  if [[ -f "$ROOT/scripts/personalities/${f}" ]]; then
    link_into "scripts/personalities/${f}" "scripted/hunter/${f}"
  fi
done

# Docs (selected overviews)
for f in README.md docs/README.md docs/DAEDALUS_TUTORIAL.md AI_AGENT_ONBOARDING_GUIDE.md AI_WORKFLOW_DEBRIEF.md; do
  if [[ -f "$ROOT/${f}" ]]; then link_into "$f" "docs/$(basename "$f")"; fi
done

echo "Bundle created at: $BUNDLE_DIR"
