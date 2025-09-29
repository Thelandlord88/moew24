#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

# Create a Daedalus files folder with all Daedalus-related files copied (not symlinked)

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DAEDALUS_DIR="$ROOT/Daedalus files"

rm -rf "$DAEDALUS_DIR"
mkdir -p "$DAEDALUS_DIR"

copy_file() {
  # $1 src (root-relative), $2 dest (relative under Daedalus files)
  local src_rel="$1" dest_rel="$2"
  local src="$ROOT/${src_rel#./}" dest="$DAEDALUS_DIR/${dest_rel#./}"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "Copied: $src_rel -> $dest_rel"
  else
    echo "Missing: $src_rel"
  fi
}

copy_dir() {
  # $1 src dir (root-relative), $2 dest dir (relative under Daedalus files)
  local src_rel="$1" dest_rel="$2"
  local src="$ROOT/${src_rel#./}" dest="$DAEDALUS_DIR/${dest_rel#./}"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -r "$src"/* "$dest"/ 2>/dev/null || true
    echo "Copied directory: $src_rel -> $dest_rel"
  else
    echo "Missing directory: $src_rel"
  fi
}

echo "Creating Daedalus files collection..."

# Core Daedalus engine
copy_file scripts/daedalus/cli.mjs cli.mjs
copy_dir scripts/daedalus/core core
copy_dir scripts/daedalus/pipelines pipelines
copy_dir scripts/daedalus/plugins plugins
copy_dir scripts/daedalus/util util
copy_dir scripts/daedalus/tools tools

# Configuration files
copy_file daedalus.config.json daedalus.config.json
copy_file daedalus.personality.json daedalus.personality.json
copy_file daedalus.personality.backup.json daedalus.personality.backup.json

# Documentation specifically about Daedalus
copy_file docs/DAEDALUS_TUTORIAL.md docs/DAEDALUS_TUTORIAL.md
copy_file AI_AGENT_ONBOARDING_GUIDE.md docs/AI_AGENT_ONBOARDING_GUIDE.md
copy_file AI_WORKFLOW_DEBRIEF.md docs/AI_WORKFLOW_DEBRIEF.md

# Root AI helper scripts related to Daedalus
copy_file ai-enhance-daedalus.mjs ai-enhance-daedalus.mjs
copy_file ai-enterprise-deployment.mjs ai-enterprise-deployment.mjs
copy_file ai-fix-gates.mjs ai-fix-gates.mjs
copy_file ai-geo-builder.mjs ai-geo-builder.mjs

# Data files that Daedalus uses
copy_file src/data/areas.adj.json data/areas.adj.json
copy_file src/data/areas.clusters.json data/areas.clusters.json
copy_file src/data/suburbs.meta.json data/suburbs.meta.json
copy_file src/data/services.json data/services.json
copy_file src/data/cluster_map.json data/cluster_map.json

# API endpoints for Daedalus system
copy_file src/pages/api/systems/daedalus.json.js api/daedalus.json.js
copy_file src/pages/api/systems/manifest.json.js api/manifest.json.js

# Daedalus profiles and personalities
copy_file profiles/daedalus.json profiles/daedalus.json
copy_file personalities/daedalus.learning.personality.v1_0_1.json personalities/daedalus.learning.personality.v1_0_1.json

# Daedalus level variants (if they exist)
if [[ -d "$ROOT/daedalus_level3" ]]; then
  copy_dir daedalus_level3 level3
fi
if [[ -d "$ROOT/daedalus_level4_schema" ]]; then
  copy_dir daedalus_level4_schema level4_schema
fi

# Create a README for the Daedalus files collection
cat > "$DAEDALUS_DIR/README.md" <<'MD'
# Daedalus Files Collection

This folder contains all files related to the Daedalus system - a comprehensive geo-aware page generation and link optimization engine.

## Structure

- **cli.mjs** - Command line interface for Daedalus
- **core/** - Core engine files (context, pipeline, plugins system)
- **pipelines/** - Pipeline definitions (geo-build.mjs)
- **plugins/** - All Daedalus plugins for various processing steps
- **util/** - Utility functions (logging, etc.)
- **tools/** - Additional tools (policy-sweeper.mjs)
- **data/** - Input data files (adjacency, clusters, suburbs metadata)
- **api/** - API endpoints for system health and status
- **profiles/** - Daedalus personality profiles
- **personalities/** - Learning personality configurations
- **docs/** - Documentation and guides
- **ai-*.mjs** - Root-level AI helper scripts
- **level3/**, **level4_schema/** - Advanced Daedalus variants (if present)

## Quick Start

From this directory:
```bash
node cli.mjs build
```

Or with specific options:
```bash
node cli.mjs build --strict=true --cap=2 --neighborsMax=4
```

See docs/DAEDALUS_TUTORIAL.md for comprehensive usage instructions.

## Configuration

- **daedalus.config.json** - Main configuration
- **daedalus.personality.json** - Personality settings

This is a complete, self-contained copy of all Daedalus-related files.
MD

echo ""
echo "Daedalus files collection created at: $DAEDALUS_DIR"
echo "Total files and directories copied. Check the README.md for usage instructions."
