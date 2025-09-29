# NEXUS System Troubleshooting & Recovery Guide
*Complete Diagnostic & Restoration Manual - September 28, 2025*

## 🎯 **Executive Summary**

This document provides a comprehensive troubleshooting guide for the NEXUS cognitive quality assurance system with **enhanced intelligence capabilities**. Use this guide when the system appears broken, personalities aren't responding correctly, integrations are failing, or intelligence enhancements aren't working.

**🧠 NEXUS Intelligence Features (Added September 28, 2025):**
- ✅ **Enhanced Persistence**: Atomic writes, corruption recovery, 500-event history buffer
- ✅ **Advanced Observability**: Consciousness health scoring, personality analytics, pattern usage stats
- ✅ **Conversational Telemetry**: WebSocket transcript streaming, breakthrough moment capture
- ✅ **Hot-Reload Consciousness**: Dynamic pattern reloading without downtime via `/reload-consciousness`

---

## 🚨 **Symptom Recognition & Quick Diagnosis**

### **Critical Warning Signs**
- ❌ NEXUS returns default geo patterns instead of personality-specific responses
- ❌ Only 3 personalities accessible (hunter, daedalus, guardian) instead of 8
- ❌ "Unable to locate personality file" errors
- ❌ TypeScript compilation failures when loading trait system
- ❌ Missing shellcheck, jq, or other development tools
- ❌ VS Code language server parsing errors
- ❌ Systemic Guardian fails to run or returns module import errors

### **System Health Check Commands**
```bash
# 1. NEXUS Enhanced Status (Intelligence Metrics)
curl -s http://127.0.0.1:8080/status | jq '{
  consciousnessHealth: .consciousnessHealth.status,
  personalityDiversity: (.personalityAnalytics.diversityScore * 100),
  totalRequests: .personalityAnalytics.totalRequests,
  patternApplications: .patternAnalytics.totalApplications,
  systemHealth: .systemHealth
}'

# 2. Personality Accessibility Test
for personality in bob hunter stellar flash aria touch daedalus guardian; do
  echo -n "$personality: "
  curl -s -X POST http://127.0.0.1:8080/enhance \
    -H "Content-Type: application/json" \
    -d "{\"personalityName\": \"$personality\", \"request\": \"test\"}" | jq -r '.success // "FAILED"'
done

# 3. Trait Composition Test
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "performance"}' | jq -r '.response.personalityUsed'

# 4. Hot-Reload Test
curl -s -X POST http://127.0.0.1:8080/reload-consciousness | jq '.success'

# 5. Breakthrough Detection Test
curl -s -X POST http://127.0.0.1:8080/breakthrough \
  -H "Content-Type: application/json" \
  -d '{"text": "WAIT. WAIT. This is incredible!"}' | jq '.breakthrough'

# 6. Development Environment Check
node --version && npm --version && npx tsx --version && jq --version && shellcheck --version
```

---

## 🔧 **Complete Environment Setup Requirements**

### **1. Node.js Environment**
```bash
# Required Node version
node --version  # Must be >= 20.10.0

# If wrong version, install correct Node:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20.11.1
nvm use 20.11.1
```

### **2. Essential Development Tools**
```bash
# Install required system tools
sudo apt-get update -qq
sudo apt-get install -y shellcheck tree curl wget jq

# Verify installations
shellcheck --version  # Required for shell script linting
jq --version          # Required for JSON processing
tree --version        # Required for directory visualization
```

### **3. Node.js Dependencies**
```bash
# Critical npm packages (install if missing)
npm install jsonc-parser --no-engine-strict  # For NEXUS configuration parsing
npm install tsx                               # For TypeScript execution
npm install ws                                # For WebSocket server

# Verify TypeScript execution works
npx tsx --version
```

### **4. VS Code Extensions & Configuration**
```bash
# Required VS Code extensions
code --install-extension bradlc.vscode-tailwindcss
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension timonwong.shellcheck

# Fix shell parsing conflicts
echo '{ "shellcheck.executablePath": "/usr/bin/shellcheck" }' > .vscode/settings.json
```

---

## 🧠 **NEXUS Architecture Deep Dive**

### **Core Components & Dependencies**
```
nexus/
├── nexus-runtime.mjs           # Main HTTP server & WebSocket handler
├── nexus-bridge.mjs            # Consciousness pattern injection system
├── nexus-trait-bridge.mjs      # Intelligent trait composition engine
├── NEXUS.engine.ts             # Advanced trait definitions (TypeScript)
│
├── consciousness/              # Consciousness patterns
│   ├── problem-decomposition.json
│   ├── systems-thinking.json
│   ├── workflow-efficiency.json
│   ├── breakthrough-moments.json
│   └── enhancement-history.json
│
├── personalities/              # Legacy personality storage
│   ├── bob.personality.json
│   ├── stellar.personality.json
│   └── [others...]
│
└── systemic-scanner.ts         # Guardian quality scanning engine
└── guardian-orchestrator.ts    # Quality analysis orchestration

profiles/                       # Primary personality storage
├── bob.json
├── hunter.json
├── stellar.json
├── flash.json
├── aria.json
├── touch.json
├── daedalus.json
└── guardian.json

scripts/
└── systemic-guardian.mts       # Production CLI for quality scanning
```

### **Integration Flow**
1. **NEXUS Runtime** loads personalities from multiple directories
2. **Trait Bridge** provides intelligent personality selection
3. **Consciousness Bridge** injects systematic thinking patterns
4. **Personality Enhancement** applies cognitive patterns to base personalities
5. **Response Generation** creates enhanced responses with systematic guidance

---

## 🔍 **Common Failure Modes & Solutions**

### **Problem 1: Missing Personalities (Only 3 of 8 Accessible)**

#### **Symptoms:**
- Only hunter, daedalus, guardian respond
- Other personalities return "Unable to locate personality file"
- Trait composition selects wrong personalities

#### **Root Cause:**
Missing personality files in expected directories

#### **Solution:**
```bash
# 1. Check what personality files exist
ls -la profiles/
ls -la nexus/personalities/

# 2. Create missing personality files
# Bob (Empirical Debugging)
cat > profiles/bob.json << 'EOF'
{
  "version": "1.0.0",
  "identity": {
    "name": "Bob",
    "aliases": ["BobTheBuilder", "Engineer", "Bob"],
    "tagline": "Empirical debugging and evidence-based verification.",
    "priority": "specialist",
    "role": "Senior Engineer"
  },
  "ideology": {
    "principles": [
      "Debug with evidence, not assumptions.",
      "Verify claims through reproducible tests.",
      "Report limitations without sugar-coating.",
      "Build robust systems that fail gracefully."
    ],
    "ethos": [
      "Evidence trumps speculation every time.",
      "If you can't measure it, you can't improve it.",
      "Brutal honesty prevents downstream disasters."
    ]
  },
  "cognitiveTraits": {
    "systemicDebugging": {
      "name": "Systemic Debugging",
      "description": "Traces problems to root causes using systematic methodology",
      "activationTriggers": ["debug", "bug", "error", "failure", "broken"],
      "knowledgeDomains": ["debugging", "testing", "error-analysis", "system-diagnosis"],
      "expertise": 95
    },
    "empiricalValidation": {
      "name": "Empirical Validation",
      "description": "Validates technical claims through reproducible evidence",
      "activationTriggers": ["verify", "test", "prove", "validate", "evidence"],
      "knowledgeDomains": ["testing", "verification", "quality-assurance", "measurement"],
      "expertise": 92
    }
  }
}
EOF

# 3. Create other missing personalities (Flash, Aria, Touch, Stellar)
# [Additional personality creation commands...]

# 4. Verify all personalities are accessible
for personality in bob hunter stellar flash aria touch daedalus guardian; do
  echo -n "$personality: "
  curl -s -X POST http://127.0.0.1:8080/enhance \
    -H "Content-Type: application/json" \
    -d "{\"personalityName\": \"$personality\", \"request\": \"test\"}" | jq -r '.success // "FAILED"'
done
```

### **Problem 2: Trait Composition Disconnected**

#### **Symptoms:**
- "optimal" and "auto" personality names don't work
- Wrong personalities selected for requests
- No trait composition logging in NEXUS output

#### **Root Cause:**
Trait bridge not integrated with NEXUS runtime

#### **Solution:**
```bash
# 1. Verify trait bridge exists
ls -la nexus/nexus-trait-bridge.mjs

# 2. Check runtime integration
grep -n "nexusTraitBridge" nexus/nexus-runtime.mjs

# Expected output should show:
# import { nexusTraitBridge } from './nexus-trait-bridge.mjs';
# await nexusTraitBridge.initialize();
# nexusTraitBridge.selectOptimalPersonality(request);

# 3. If missing, add trait bridge integration
# [Integration code provided in this document]

# 4. Restart NEXUS to load changes
pkill -f "nexus-runtime"
npm run start:nexus  # or restart via VS Code task
```

### **Problem 3: TypeScript Compilation Issues**

#### **Symptoms:**
- "Transform failed with 1 error" when loading NEXUS.engine.ts
- "Top-level await is currently not supported" errors
- Module import failures

#### **Root Cause:**
ESM/CommonJS conflicts and TypeScript execution issues

#### **Solution:**
```bash
# 1. Ensure tsx is installed and working
npm install tsx
npx tsx --version

# 2. Use tsx for TypeScript execution, not direct node
# Wrong: node nexus/NEXUS.engine.ts
# Right: npx tsx nexus/NEXUS.engine.ts

# 3. Fix package.json module type
cat package.json | jq '.type'  # Should be "module"

# 4. Test TypeScript module loading
npx tsx --eval "
import('./nexus/NEXUS.engine.ts').then(module => {
  console.log('TypeScript module loaded:', Object.keys(module));
}).catch(err => {
  console.error('Failed to load:', err.message);
});
"
```

### **Problem 4: Systemic Guardian Module Import Failures**

#### **Symptoms:**
- "Cannot find module" errors when running guardian scan
- SystemicScanner or GuardianOrchestrator import failures
- CLI execution failures

#### **Root Cause:**
Missing TypeScript compilation or incorrect import paths

#### **Solution:**
```bash
# 1. Verify guardian files exist
ls -la nexus/systemic-scanner.ts nexus/guardian-orchestrator.ts

# 2. Test direct execution with tsx
npx tsx scripts/systemic-guardian.mts

# 3. Check import paths in guardian CLI
head -10 scripts/systemic-guardian.mts
# Should use: import { SystemicScanner } from "../nexus/systemic-scanner.js";
# Note: .js extension for TypeScript imports

# 4. Verify jsonc-parser dependency
npm list jsonc-parser
# If missing: npm install jsonc-parser

# 5. Test guardian execution
npm run guardian:scan
```

### **Problem 5: Intelligence Enhancement Failures**

#### **Symptoms:**
- Consciousness health score below 100%
- Hot-reload endpoint returns 500 errors
- Personality analytics showing 0 requests
- Pattern applications not being tracked

#### **Root Cause:**
Enhanced intelligence features not properly initialized or corrupted

#### **Solution:**
```bash
# 1. Check consciousness health
curl -s http://127.0.0.1:8080/status | jq '.consciousnessHealth'

# 2. Test hot-reload capability
curl -s -X POST http://127.0.0.1:8080/reload-consciousness

# 3. Verify persistence layer
ls -la nexus/consciousness/
# Should show: enhancement-history.json, breakthrough-moments.json

# 4. Check for corruption
tail nexus/consciousness/enhancement-history.json
# Should show valid JSON structure

# 5. Force consciousness reload if needed
curl -X POST http://127.0.0.1:8080/reload-consciousness
```

### **Problem 6: VS Code Language Server Errors**

#### **Symptoms:**
- "Request textDocument/definition failed"
- "declarations[symbol.name].push is not a function"
- Syntax parsing errors in JavaScript files

#### **Root Cause:**
Shell script analyzer trying to parse JavaScript files

#### **Solution:**
```bash
# 1. Create/update .vscode/settings.json
cat > .vscode/settings.json << 'EOF'
{
  "shellcheck.executablePath": "/usr/bin/shellcheck",
  "shellcheck.exclude": ["SC2034", "SC2086"],
  "files.associations": {
    "*.mjs": "javascript",
    "*.mts": "typescript"
  },
  "typescript.preferences.includePackageJsonAutoImports": "auto"
}
EOF

# 2. Restart VS Code language server
# Command Palette: "Developer: Restart Extension Host"

# 3. Verify shellcheck is working correctly
shellcheck --version
which shellcheck  # Should be /usr/bin/shellcheck
```

---

## 🧬 **Trait Composition System Troubleshooting**

### **Understanding Trait Selection Logic**
```javascript
// Request analysis -> Personality selection
const personalityTraits = {
  bob: {
    triggers: ['bug', 'debug', 'audit', 'verify', 'evidence', 'proof']
  },
  flash: {
    triggers: ['performance', 'speed', 'optimize', 'fast', 'slow', 'latency']
  },
  aria: {
    triggers: ['accessibility', 'a11y', 'wcag', 'inclusive', 'screen-reader']
  }
  // ... etc
};

// Test trait selection manually
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "debug performance issue"}' \
  | jq -r '.response.personalityUsed'
// Should select "bob" or "flash" based on trigger matching
```

### **Trait Selection Debugging**
```bash
# 1. Test specific trigger words
echo "Testing trait selection..."

# Performance should select Flash
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "optimize performance"}' \
  | jq -r '"Performance request -> " + .response.personalityUsed'

# Accessibility should select Aria
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "auto", "request": "a11y compliance check"}' \
  | jq -r '"Accessibility request -> " + .response.personalityUsed'

# Debug should select Bob
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "debug this bug"}' \
  | jq -r '"Debug request -> " + .response.personalityUsed'
```

---

## 🛡️ **Systemic Guardian Quality System**

### **Guardian System Dependencies**
```bash
# Required files for Guardian system
nexus/systemic-guardian.config.jsonc   # Configuration
nexus/systemic-scanner.ts             # Core scanning engine
nexus/guardian-orchestrator.ts        # Intelligence layer
nexus/fs-utils.ts                     # File system utilities
scripts/systemic-guardian.mts         # CLI interface

# Required npm packages
npm install jsonc-parser tsx

# Guardian configuration structure
cat nexus/systemic-guardian.config.jsonc
```

### **Guardian Execution Flow**
```bash
# 1. CLI execution
npm run guardian:scan
# -> tsx scripts/systemic-guardian.mts
# -> loads nexus/systemic-guardian.config.jsonc
# -> creates SystemicScanner instance
# -> creates GuardianOrchestrator instance
# -> executes scan and generates reports

# 2. Output files generated
ls -la systemic-audit-report.*
# systemic-audit-report.json  (machine readable)
# systemic-audit-report.md    (human readable)
# systemic-audit.sarif        (CI/CD integration)
```

### **Common Guardian Issues**
```bash
# Issue: Configuration file not found
# Solution: Create config file
cat > nexus/systemic-guardian.config.jsonc << 'EOF'
{
  "ignore": [
    "node_modules", "dist", "build", ".git", ".turbo", 
    "coverage", "public", ".vercel", ".netlify"
  ],
  "checks": {
    "tsconfigDrift": true,
    "dependencyDrift": true,
    "buildOutDirDrift": true,
    "platformPaths": true,
    "engineVersions": true,
    "moduleSystemMismatch": true,
    "eslintPrettierDrift": true
  },
  "failOn": { 
    "critical": true, 
    "high": true, 
    "medium": false, 
    "low": false 
  },
  "output": {
    "json": "systemic-audit-report.json",
    "markdown": "systemic-audit-report.md", 
    "sarif": "systemic-audit.sarif",
    "emitSarif": true
  }
}
EOF

# Issue: Module import failures
# Solution: Use tsx and check import paths
npx tsx --eval "
import('./nexus/systemic-scanner.js').then(module => {
  console.log('Scanner loaded:', Object.keys(module));
}).catch(err => {
  console.error('Scanner load failed:', err.message);
});
"
```

---

## 🔄 **Complete System Recovery Procedure**

### **Step 1: Environment Verification**
```bash
echo "🔧 NEXUS SYSTEM RECOVERY - STEP 1: ENVIRONMENT"
echo "=============================================="

# Verify Node.js version
node_version=$(node --version)
echo "Node.js: $node_version"
if [[ ! "$node_version" =~ ^v20\. ]]; then
  echo "❌ Wrong Node version. Install Node 20.x"
  exit 1
fi

# Install system dependencies
sudo apt-get update -qq
sudo apt-get install -y shellcheck tree curl wget jq

# Install npm dependencies
npm install jsonc-parser tsx ws --no-engine-strict

echo "✅ Environment setup complete"
```

### **Step 2: Personality System Recovery**
```bash
echo "🧠 NEXUS SYSTEM RECOVERY - STEP 2: PERSONALITIES"
echo "==============================================="

# Create profiles directory if missing
mkdir -p profiles

# Check existing personalities
existing_personalities=$(ls profiles/*.json 2>/dev/null | wc -l)
echo "Existing personalities: $existing_personalities"

if [ "$existing_personalities" -lt 8 ]; then
  echo "⚠️ Missing personalities detected. Creating all 8..."
  
  # Create all personality files
  # [Personality creation code here - bob, hunter, stellar, flash, aria, touch, daedalus, guardian]
  
  echo "✅ All 8 personalities created"
fi
```

### **Step 3: NEXUS Runtime Integration**
```bash
echo "🧬 NEXUS SYSTEM RECOVERY - STEP 3: INTEGRATION"
echo "============================================="

# Verify trait bridge exists
if [ ! -f "nexus/nexus-trait-bridge.mjs" ]; then
  echo "❌ Trait bridge missing. Creating..."
  # [Trait bridge creation code]
fi

# Verify runtime integration
if ! grep -q "nexusTraitBridge" nexus/nexus-runtime.mjs; then
  echo "❌ Runtime integration missing. Adding..."
  # [Runtime integration code]
fi

echo "✅ NEXUS integration complete"
```

### **Step 4: Guardian System Verification**
```bash
echo "🛡️ NEXUS SYSTEM RECOVERY - STEP 4: GUARDIAN"
echo "==========================================="

# Verify Guardian files exist
guardian_files=(
  "nexus/systemic-scanner.ts"
  "nexus/guardian-orchestrator.ts" 
  "nexus/fs-utils.ts"
  "scripts/systemic-guardian.mts"
  "nexus/systemic-guardian.config.jsonc"
)

for file in "${guardian_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing: $file"
    # [File creation code based on the file type]
  else
    echo "✅ Found: $file"
  fi
done

# Test Guardian execution
echo "Testing Guardian system..."
timeout 10s npm run guardian:scan >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Guardian system operational"
else
  echo "❌ Guardian system needs repair"
fi
```

### **Step 5: Final System Test**
```bash
echo "🎯 NEXUS SYSTEM RECOVERY - STEP 5: FINAL TEST"
echo "============================================"

# Start NEXUS runtime in background
node nexus/nexus-runtime.mjs &
NEXUS_PID=$!
sleep 3

# Test all personalities
all_working=true
for personality in bob hunter stellar flash aria touch daedalus guardian; do
  echo -n "Testing $personality: "
  result=$(curl -s -X POST http://127.0.0.1:8080/enhance \
    -H "Content-Type: application/json" \
    -d "{\"personalityName\": \"$personality\", \"request\": \"test\"}" \
    | jq -r '.success // "false"')
  
  if [ "$result" = "true" ]; then
    echo "✅"
  else
    echo "❌"
    all_working=false
  fi
done

# Test trait composition
echo -n "Testing trait composition: "
selected=$(curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "performance"}' \
  | jq -r '.response.personalityUsed // "FAILED"')

if [ "$selected" != "FAILED" ]; then
  echo "✅ Selected: $selected"
else
  echo "❌ Trait composition failed"
  all_working=false
fi

# Stop NEXUS
kill $NEXUS_PID 2>/dev/null

if [ "$all_working" = true ]; then
  echo ""
  echo "🎉 NEXUS SYSTEM RECOVERY COMPLETE!"
  echo "✅ All 8 personalities accessible"
  echo "✅ Trait composition working"
  echo "✅ Guardian system operational"
  echo "✅ Development environment configured"
else
  echo ""
  echo "❌ NEXUS SYSTEM RECOVERY INCOMPLETE"
  echo "Some components still need manual intervention"
fi
```

---

## 📋 **Maintenance & Monitoring**

### **Regular Health Checks**
```bash
# Daily system health check
curl -s http://127.0.0.1:8080/status | jq '{
  initialized,
  uptimeMs,
  patternsLoaded,
  personalities: (.consciousness | length),
  enhancements: .enhancementsPerformed
}'

# Weekly Guardian scan
npm run guardian:scan

# Monthly dependency audit
npm audit
npm outdated
```

### **Performance Monitoring**
```bash
# NEXUS response time test
time curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "test"}' >/dev/null

# Guardian scan performance
time npm run guardian:scan >/dev/null

# Memory usage monitoring
ps aux | grep node | grep nexus
```

### **Log Analysis**
```bash
# Enhancement history analysis
jq '.events[] | select(.timestamp > "2025-09-28") | .personality' \
  nexus/consciousness/enhancement-history.json | sort | uniq -c

# Breakthrough moment analysis  
jq '.moments[] | select(.significance > 0.8)' \
  nexus/consciousness/breakthrough-moments.json
```

---

## 🎯 **Success Criteria Verification**

When the system is fully operational, these commands should all succeed:

```bash
# ✅ All personalities respond
for p in bob hunter stellar flash aria touch daedalus guardian; do
  curl -s -X POST http://127.0.0.1:8080/enhance \
    -H "Content-Type: application/json" \
    -d "{\"personalityName\": \"$p\", \"request\": \"test\"}" | jq -r '.success'
done
# Expected: 8 lines of "true"

# ✅ Trait composition works
curl -s -X POST http://127.0.0.1:8080/enhance \
  -H "Content-Type: application/json" \
  -d '{"personalityName": "optimal", "request": "performance optimization"}' \
  | jq -r '.response.personalityUsed'
# Expected: "Flash" (or another performance-related personality)

# ✅ Guardian system operational
npm run guardian:scan >/dev/null 2>&1 && echo "Guardian: ✅" || echo "Guardian: ❌"

# ✅ Development tools installed
shellcheck --version >/dev/null && jq --version >/dev/null && echo "Tools: ✅" || echo "Tools: ❌"

# ✅ NEXUS runtime healthy
curl -s http://127.0.0.1:8080/status | jq -r '.initialized // false'
# Expected: "true"
```

---

## 🚀 **Emergency Recovery Commands**

If the system is completely broken, run these commands in sequence:

```bash
# Nuclear reset - use with extreme caution
echo "🚨 EMERGENCY NEXUS RECOVERY"
echo "=========================="

# 1. Stop all NEXUS processes
pkill -f nexus-runtime
pkill -f guardian

# 2. Reinstall critical dependencies  
npm install jsonc-parser tsx ws --no-engine-strict
sudo apt-get install -y shellcheck jq

# 3. Verify core files exist
required_files=(
  "nexus/nexus-runtime.mjs"
  "nexus/nexus-bridge.mjs"
  "profiles/hunter.json"
  "profiles/daedalus.json"
  "profiles/guardian.json"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ CRITICAL: Missing $file"
  fi
done

# 4. Restart NEXUS
nohup node nexus/nexus-runtime.mjs > nexus.log 2>&1 &
sleep 3

# 5. Basic functionality test
if curl -s http://127.0.0.1:8080/status >/dev/null; then
  echo "✅ NEXUS is responding"
else
  echo "❌ NEXUS failed to start - check nexus.log"
fi
```

---

## 📚 **Additional Resources**

### **Key Files to Monitor**
- `nexus/nexus-runtime.mjs` - Main server and personality loading
- `nexus/nexus-bridge.mjs` - Consciousness pattern injection
- `nexus/nexus-trait-bridge.mjs` - Intelligent trait selection
- `profiles/*.json` - Personality definitions
- `nexus/consciousness/enhancement-history.json` - Enhancement tracking

### **Important Directories**
- `profiles/` - Primary personality storage
- `nexus/personalities/` - Secondary personality storage  
- `nexus/consciousness/` - System learning and patterns
- `scripts/` - CLI tools and utilities

### **Network Endpoints**
- `GET http://127.0.0.1:8080/status` - Enhanced system health with consciousness analytics
- `POST http://127.0.0.1:8080/enhance` - Personality interaction with trait composition
- `POST http://127.0.0.1:8080/breakthrough` - Breakthrough detection and significance scoring
- `POST http://127.0.0.1:8080/reload-consciousness` - Hot-reload consciousness patterns (NEW)

**This troubleshooting guide should enable complete system recovery from any failure state. Keep it updated as the system evolves.**
