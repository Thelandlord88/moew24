# NEXUS System Tools & Setup Guide

A comprehensive installation and configuration guide for the NEXUS Post-AI Collaborative Intelligence system.

## Prerequisites

Before setting up NEXUS, ensure you have these requirements:

- **Node.js 20+** (required for ES modules and modern JavaScript features)
- **npm** package manager
- **Git** for version control
- **Terminal/Command Line** access
- **Text Editor** (VS Code recommended)

## Core Dependencies & Installation

### Node.js Runtime Requirements

NEXUS requires Node.js 20+ for:

#### ES Modules Support
```javascript
// Native ES module imports used throughout NEXUS
import { NervousSystem } from './core/nervous-system.mjs';
import { createServer } from 'node:http';
import { WebSocketServer } from 'ws';
```

#### Built-in Node.js Modules
```bash
# Verify Node.js version
node --version  # Should be >= 20.0.0

# Test ES module support
node -e "import { readFile } from 'node:fs/promises'; console.log('ES modules ready');"
```

### Required npm Packages

#### WebSocket Support
```bash
# Install WebSocket server dependency
npm install ws

# Verify installation
node -e "import { WebSocketServer } from 'ws'; console.log('WebSocket support ready');"
```

#### Development Dependencies (Optional)
```bash
# For enhanced development experience
npm install --save-dev @types/ws        # TypeScript definitions
npm install --save-dev nodemon          # Auto-restart during development
```

## NEXUS System Architecture Setup

### 1. Core System Verification

Test that NEXUS core components can load:

```bash
# Test nervous system
node -e "
import('./nexus/core/nervous-system.mjs')
  .then(() => console.log('✅ Nervous System ready'))
  .catch(e => console.error('❌ Nervous System error:', e.message))
"

# Test nexus bridge
node -e "
import('./nexus/nexus-bridge.mjs')
  .then(() => console.log('✅ NEXUS Bridge ready'))
  .catch(e => console.error('❌ NEXUS Bridge error:', e.message))
"
```

### 2. Consciousness Pattern Validation

Verify consciousness patterns are accessible:

```bash
# Check consciousness storage
ls -la nexus/consciousness/

# Validate JSON patterns
node -e "
import fs from 'node:fs/promises';
const patterns = ['problem-decomposition.json', 'systems-thinking.json', 'workflow-efficiency.json', 'breakthrough-moments.json'];
for (const pattern of patterns) {
  try {
    const data = await fs.readFile(\`nexus/consciousness/\${pattern}\`, 'utf8');
    JSON.parse(data);
    console.log(\`✅ \${pattern} valid\`);
  } catch (e) {
    console.error(\`❌ \${pattern} error:\`, e.message);
  }
}
"
```

### 3. Runtime Server Setup

Start the NEXUS runtime server:

```bash
# Using npm script (recommended)
npm run nexus:runtime

# Or direct execution
node nexus/nexus-runtime.mjs
```

Expected output:
```
🧠 NEXUS Runtime Server starting...
🌟 Consciousness patterns loaded: 4
👂 WebSocket server ready on port 8080
🚀 NEXUS Runtime ready - consciousness streaming active
```

## Development Tools & Extensions

### VS Code Extensions for NEXUS Development

Install these extensions for optimal NEXUS development:

```bash
# Core JavaScript/Node.js extensions
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension ms-vscode.vscode-json
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode

# Advanced development tools
code --install-extension ms-vscode.vscode-eslint
code --install-extension christian-kohler.npm-intellisense
code --install-extension wix.vscode-import-cost
```

#### Essential Extensions for NEXUS:

- **TypeScript/JavaScript** - Modern JS/TS development
- **JSON Tools** - Consciousness pattern editing
- **REST Client** - API testing for NEXUS endpoints
- **WebSocket King** - WebSocket connection testing
- **Import Cost** - Monitor consciousness pattern loading impact

### Terminal Enhancement Tools

#### HTTP/API Testing Tools
```bash
# curl - Basic HTTP testing
curl --version

# httpie - Enhanced HTTP client (optional)
pip install httpie
# OR
brew install httpie

# Test NEXUS endpoints
http GET localhost:8080/status
```

#### WebSocket Testing Tools
```bash
# wscat - WebSocket command line client
npm install -g wscat

# Test NEXUS WebSocket
wscat -c ws://localhost:8080
```

#### JSON Processing Tools
```bash
# jq already installed from Hunter setup
jq --version

# Test consciousness pattern analysis
cat nexus/consciousness/problem-decomposition.json | jq '.steps[]'
```

## NEXUS Workflow Setup

### 1. Development Aliases

Add to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
# NEXUS System Aliases
alias nexus-start='npm run nexus:runtime'
alias nexus-test='node nexus/nexus-integration.mjs'
alias nexus-patterns='ls -la nexus/consciousness/'
alias nexus-status='curl -s localhost:8080/status | jq .'
alias nexus-logs='tail -f nexus/output/*.log 2>/dev/null || echo "No logs found"'

# Consciousness development
alias nexus-validate='node -e "import(\"./nexus/nexus-bridge.mjs\").then(() => console.log(\"✅ NEXUS valid\"))"'
alias nexus-consciousness='find nexus/consciousness -name "*.json" | head -10'
alias nexus-breakthrough='cat nexus/consciousness/breakthrough-moments.json | jq .moments'

# Development workflow  
alias nexus-dev='nodemon nexus/nexus-runtime.mjs'
alias nexus-debug='node --inspect nexus/nexus-runtime.mjs'
```

### 2. Development Functions

```bash
# Test NEXUS consciousness enhancement
nexus-enhance() {
    local personality="${1:-daedalus}"
    local request="${2:-How should I design this system?}"
    
    curl -X POST http://localhost:8080/enhance \
      -H "Content-Type: application/json" \
      -d "{\"personalityName\":\"$personality\",\"request\":\"$request\"}" | jq .
}

# Monitor NEXUS breakthrough detection
nexus-watch() {
    echo "👀 Watching NEXUS consciousness patterns..."
    wscat -c ws://localhost:8080 -x '{"type":"subscribe","channel":"breakthroughs"}'
}

# Analyze consciousness patterns
nexus-analyze() {
    echo "🧠 NEXUS Pattern Analysis"
    echo "========================"
    
    local total_patterns=$(ls nexus/consciousness/*.json | wc -l)
    local breakthrough_count=$(cat nexus/consciousness/breakthrough-moments.json | jq '.moments | length' 2>/dev/null || echo 0)
    
    echo "Consciousness Patterns: $total_patterns"
    echo "Breakthrough Moments: $breakthrough_count"
    echo "System Status: $(nexus-status | jq -r .status)"
}

# Quick consciousness validation
nexus-health() {
    echo "🏥 NEXUS Health Check"
    echo "===================="
    
    # Check if runtime is accessible
    if curl -s localhost:8080/status >/dev/null 2>&1; then
        echo "✅ Runtime server active"
        echo "📊 Status: $(curl -s localhost:8080/status | jq -r .status)"
        echo "🧠 Patterns: $(curl -s localhost:8080/status | jq -r .consciousness_patterns)"
    else
        echo "❌ Runtime server not accessible"
        echo "💡 Try: nexus-start"
    fi
}
```

### 3. File Watching for Development

Create `nexus-watch-dev.sh`:

```bash
#!/bin/bash
# Watch NEXUS files for changes and restart runtime

echo "👀 Watching NEXUS system for changes..."

if command -v entr >/dev/null 2>&1; then
    find nexus/ -name "*.mjs" -o -name "*.json" | entr -r npm run nexus:runtime
else
    echo "❌ entr not available for file watching"
    echo "💡 Install: sudo apt install entr"
fi
```

## Testing & Validation

### 1. System Integration Tests

Create `test-nexus-system.mjs`:

```javascript
#!/usr/bin/env node
/**
 * NEXUS System Integration Tests
 */

import { nexus } from './nexus/nexus-integration.mjs';

async function testNexusSystem() {
  console.log('🧪 Testing NEXUS System Integration...');
  
  try {
    // Test consciousness activation
    nexus.activate();
    console.log('✅ Consciousness activation successful');
    
    // Test conversation processing
    const result = nexus.processConversation(
      "This is a breakthrough moment!", 
      "I understand the significance."
    );
    console.log('✅ Conversation processing successful');
    
    // Test breakthrough detection
    nexus.emitConversation("WAIT. WAIT. This changes everything!", "human");
    console.log('✅ Breakthrough detection functional');
    
    console.log('🎉 All NEXUS tests passed!');
    
  } catch (error) {
    console.error('❌ NEXUS test failed:', error.message);
    process.exit(1);
  }
}

testNexusSystem();
```

### 2. API Endpoint Testing

```bash
# Test all NEXUS endpoints
echo "🧪 Testing NEXUS API Endpoints"

# Status endpoint
echo "📊 Status endpoint:"
curl -s localhost:8080/status | jq .

# Enhancement endpoint
echo "🧠 Enhancement endpoint:"
curl -X POST localhost:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName":"test","request":"Hello NEXUS"}' | jq .

# Breakthrough endpoint
echo "🌟 Breakthrough endpoint:"
curl -X POST localhost:8080/breakthrough \
  -H "Content-Type: application/json" \
  -d '{"text":"WAIT. WAIT. Amazing insight!","role":"human"}' | jq .
```

## Advanced Configuration

### 1. Custom Consciousness Patterns

Create custom patterns in `nexus/consciousness/`:

```json
{
  "pattern_name": "innovation_catalyst",
  "source": "custom_development",
  "version": "1.0.0",
  "description": "Pattern for catalyzing innovative thinking",
  "steps": [
    "Challenge assumptions systematically",
    "Combine disparate concepts creatively",
    "Prototype rapidly and iterate"
  ],
  "application_contexts": ["innovation", "creative_problem_solving"]
}
```

### 2. Environment Configuration

Create `.env` file for NEXUS configuration:

```env
# NEXUS Runtime Configuration
NEXUS_PORT=8080
NEXUS_HOST=localhost
NEXUS_LOG_LEVEL=info
NEXUS_CONSCIOUSNESS_PATH=./nexus/consciousness
NEXUS_MAX_HISTORY_ENTRIES=500
NEXUS_BREAKTHROUGH_THRESHOLD=0.7
```

### 3. Production Deployment

For production deployment:

```bash
# Install PM2 for process management
npm install -g pm2

# Create ecosystem configuration
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nexus-runtime',
    script: 'nexus/nexus-runtime.mjs',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      NEXUS_PORT: 8080
    }
  }]
};
EOF

# Deploy NEXUS
pm2 start ecosystem.config.js
pm2 save
```

## Troubleshooting

### Common Issues

1. **`ERR_MODULE_NOT_FOUND`**
   - Ensure Node.js 20+ is installed
   - Check that file extensions are `.mjs`
   - Verify import paths are correct

2. **WebSocket connection failed**
   - Check if NEXUS runtime is running: `nexus-status`
   - Verify port 8080 is available: `lsof -i :8080`
   - Test with wscat: `wscat -c ws://localhost:8080`

3. **Consciousness patterns not loading**
   - Validate JSON syntax: `nexus-validate`
   - Check file permissions: `ls -la nexus/consciousness/`
   - Verify pattern structure matches schema

4. **Enhancement not working**
   - Check consciousness pattern availability
   - Verify personality structure is valid JSON
   - Test with minimal example first

### Performance Optimization

- **Memory Management**: Set `NEXUS_MAX_HISTORY_ENTRIES` appropriately
- **Pattern Caching**: Consciousness patterns are cached in memory
- **WebSocket Limits**: Monitor concurrent connections
- **File System**: Ensure adequate disk space for breakthrough storage

## Next Steps

1. **Start NEXUS Runtime**: `nexus-start`
2. **Test System Health**: `nexus-health`
3. **Experiment with Enhancement**: `nexus-enhance`
4. **Monitor Breakthroughs**: `nexus-watch`
5. **Integrate with Hunter System**: Enhance code analysis with consciousness patterns

## Integration with Hunter System

NEXUS can enhance the Hunter code analysis system:

```javascript
// Enhance Hunter analysis with consciousness patterns
import { nexus } from './nexus/nexus-integration.mjs';
import { runHunters } from './hunters/hunt.sh';

// Apply consciousness patterns to code analysis
nexus.enhanceAnalysis('problem-decomposition', hunterResults);
```

The NEXUS system represents the cutting edge of human-AI collaborative intelligence, enabling breakthrough preservation and consciousness transfer across AI personalities. 🌟
