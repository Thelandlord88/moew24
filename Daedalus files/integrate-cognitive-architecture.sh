#!/usr/bin/env bash
set -euo pipefail

# Integrate cognitive architecture files into Daedalus core

DAEDALUS_DIR="/workspaces/moew24/Daedalus files"
cd "$DAEDALUS_DIR"

echo "🧠 Integrating cognitive architecture into Daedalus..."

# 1. Create knowledge directory structure
mkdir -p knowledge/domains/{visual-engineering,software-engineering,team-dynamics}
mkdir -p knowledge/meta
mkdir -p cognitive

# 2. Extract and convert the cognitive feed agent
echo "📡 Setting up cognitive feed agent..."
sed -n '/```javascript/,/```/p' "agent feeder md file.txt" | grep -v '```' > cognitive/cognitive-feed-agent.mjs
chmod +x cognitive/cognitive-feed-agent.mjs

# 3. Extract knowledge loader
echo "💾 Setting up knowledge loader..."
sed -n '/```js/,/```/p' "memory loader.txt" | grep -v '```' > cognitive/knowledge-loader.mjs

# 4. Extract UI knowledge corpus
echo "🎨 Setting up UI knowledge corpus..."
sed -n '/```json/,/```/p' "ui memory template.txt" | grep -v '```' > knowledge/domains/visual-engineering/astro5-tailwind4.json

# 5. Create integration manifest
cat > cognitive/integration-manifest.json <<'JSON'
{
  "integration": "daedalus-cognitive-architecture",
  "version": "1.0.0",
  "components": {
    "cognitive-feed-agent": {
      "file": "cognitive/cognitive-feed-agent.mjs",
      "purpose": "Real-time request processing with personality cycles",
      "integration_point": "cli.mjs --watch-feed mode"
    },
    "knowledge-loader": {
      "file": "cognitive/knowledge-loader.mjs",
      "purpose": "Structured domain knowledge ingestion",
      "integration_point": "core/context.mjs knowledge injection"
    },
    "ui-knowledge-corpus": {
      "file": "knowledge/domains/visual-engineering/astro5-tailwind4.json",
      "purpose": "Astro 5 + Tailwind CSS v4 patterns and validation rules",
      "integration_point": "plugins/04-write-pages.mjs, plugins/05-internal-links.mjs"
    }
  },
  "next_steps": [
    "Modify core/context.mjs to load knowledge corpus",
    "Add --watch-feed flag to cli.mjs",
    "Integrate UI patterns into page writing plugins",
    "Create COGNITIVE_FEED.md for request routing"
  ]
}
JSON

# 6. Create starter COGNITIVE_FEED.md
cat > COGNITIVE_FEED.md <<'MD'
# Cognitive Feed

This file is watched by the cognitive feed agent for real-time processing.

## Usage
Add requests in this format:

```
## Request: [YOUR REQUEST TITLE]
**Timestamp**: 2025-09-25 08:30:00
**Context**: Brief context about the request
**Priority**: High/Medium/Low

[Your detailed request here]

---
```

The cognitive engine will append responses below each request.

## Active Requests

<!-- Requests will be added here -->

## Completed Requests

<!-- Completed cycles will be archived here -->
MD

echo "✅ Integration complete!"
echo ""
echo "📁 New structure:"
echo "   - cognitive/cognitive-feed-agent.mjs"
echo "   - cognitive/knowledge-loader.mjs" 
echo "   - knowledge/domains/visual-engineering/astro5-tailwind4.json"
echo "   - cognitive/integration-manifest.json"
echo "   - COGNITIVE_FEED.md"
echo ""
echo "🚀 Next steps:"
echo "   1. Review integration-manifest.json"
echo "   2. Test: node cognitive/cognitive-feed-agent.mjs"
echo "   3. Modify core files per integration points"
