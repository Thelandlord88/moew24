# 🛡️ Adaptive Guardrails System

A comprehensive CSS architecture protection and monitoring system that adapts to development context and provides progressive enforcement across dev/CI/production environments.

## 🎯 Quick Start

```bash
# Daily development workflow
npm run summary              # View comprehensive dashboard
npm run guard:dev           # Run development checks
npm run build               # Full build with CI enforcement

# Technical debt management  
npm run debt:summary        # Check accumulated issues
npm run debt:clean          # Clean up debt log

# Emergency exceptions
npm run guard:allow -- --rule=cssBaseline --file="pattern" --until=2025-12-31 --reason="Feature work"
```

## 📊 System Overview

### **Progressive Enforcement Modes**

| Mode | CSS Budget | Per-File | Grace | Enforcement | Use Case |
|------|------------|----------|-------|-------------|----------|
| **Dev** | 180KB | 120KB | 20KB | Warnings only | Daily development |
| **CI** | 150KB | 100KB | 5KB | Error on critical | Pull requests |
| **Prod** | 140KB | 95KB | 0KB | Strict enforcement | Deployments |

### **Context-Aware Budgets**

The system automatically relaxes budgets when working on specific areas:

- **Homepage work**: +20KB CSS budget (detects `src/pages/index.astro` changes)
- **Component work**: +10KB CSS budget (detects `src/components/` changes)
- **Git-aware**: Uses staged/working tree changes for context detection

## 🚀 Core Commands

### **Daily Development**

```bash
# View comprehensive dashboard
npm run summary
# Output: Progress bars, file breakdown, drift analysis, allowlist status

# Run development checks (gentle warnings)
npm run guard:dev
# Output: [cssBaseline] Total CSS: 105.3KB/180KB ████████████░░░░░░░░ 59%

# Full build with CI enforcement
npm run build
# Includes all quality checks + adaptive guardrails
```

### **Different Enforcement Modes**

```bash
# Development mode (current default)
npm run summary
GUARD_MODE=dev npm run summary

# CI mode (stricter, used in build pipeline)
GUARD_MODE=ci npm run summary

# Production mode (strictest)
GUARD_MODE=prod npm run summary
```

### **Technical Debt Management**

```bash
# View accumulated technical debt
npm run debt:summary
# Shows: rule violations, hot files, recent issues

# Clean up duplicate entries in debt log
npm run debt:clean

# View detailed debt in JSON format
cat __reports/tech-debt.ndjson | jq '.'
```

### **Allowlist Management**

```bash
# Add temporary exception for CSS budget
npm run guard:allow -- \
  --rule=cssBaseline \
  --file="_suburb_.*\.css" \
  --until=2025-10-15 \
  --reason="Quote form enhancement"

# View active allowlist entries
npm run summary | grep -A 10 "Allowlist"
```

### **Repository Organization**

```bash
# Find duplicate files (numbered copies like file(1).js)
npm run reorg:audit-dupes

# View repository structure
find scripts/ -name "*.mjs" | head -20
```

## 📋 Report Files

### **Generated Reports**

| File | Purpose | Tracked in Git |
|------|---------|----------------|
| `__reports/css-baseline.json` | Performance baseline for drift detection | ✅ Yes |
| `__reports/css-current.json` | Current CSS snapshot | ❌ No (ephemeral) |
| `__reports/summary.json` | Machine-readable dashboard data | ❌ No (ephemeral) |
| `__reports/summary.md` | Human-readable summary | ❌ No (ephemeral) |
| `__reports/tech-debt.ndjson` | Technical debt log | ❌ No (ephemeral) |
| `scripts/guard/allowlist.json` | Active exceptions | ❌ No (ephemeral) |

# View CSS health summary
cat __reports/summary.md

# Extract key metrics from JSON
  allowlist: (.allowlist | length),
  debt: .debt.count
}'
```

## 🔧 Advanced Usage

### **Custom Summary Options**

```bash
# Limit file display
npm run summary -- --maxFiles=5

# Skip markdown generation (JSON only)
npm run summary -- --no-md

# Skip JSON generation (console only)
npm run summary -- --no-json

# Combined options
npm run summary -- --maxFiles=10 --no-md
```

### **Manual Guard Execution**

```bash
# Run individual guard components
node scripts/guard/run-css-one-global.mjs
node scripts/guard/run-css-baseline.mjs

# With specific modes
GUARD_MODE=ci node scripts/guard/run-css-baseline.mjs
```

### **Baseline Management**

```bash
# Create new baseline from current state
npm run guard:dev  # Generate current snapshot
cp __reports/css-current.json __reports/css-baseline.json
git add __reports/css-baseline.json
git commit -m "chore: Update CSS baseline after intentional changes"

# Reset baseline after major refactoring
npm run build
npm run guard:ci
cp __reports/css-current.json __reports/css-baseline.json
```

## 🧠 How It Works

### **CSS Architecture Protection**

1. **One Global Bundle Enforcement**: Ensures exactly one CSS file contains global styles
2. **Budget Monitoring**: Tracks total CSS size and per-file limits
3. **Drift Detection**: Compares current state vs established baseline
4. **Page Usage Tracking**: Monitors how many pages use each CSS file
```css
.btn, .card, .input
.shadow-card
view-transition-name:
::view-transition-(old|new)
--color-brand-accent
--radius-card
--shadow-card-hover
```

### **Technical Debt Tracking**

- **Non-blocking**: Issues are logged but don't stop development
- **Categorized**: Grouped by rule type (cssBaseline, cssOneGlobal, etc.)
- **Hot Files**: Identifies files causing the most issues
- **Temporal**: Shows recent trends and patterns

### **Allowlist System**

- **Time-limited**: All exceptions have expiry dates
- **Auditable**: Each exception includes a reason
- **Flexible**: Supports regex patterns for file matching
- **Progressive**: Can escalate enforcement over time

## 🚨 Troubleshooting

### **Common Issues**

**CSS budget exceeded in dev mode:**
```bash
# Check current usage
npm run summary

# Add temporary exception if needed
npm run guard:allow -- --rule=cssBaseline --file=".*" --until=2025-12-31 --reason="Feature development"

```bash
# View which files are considered global
npm run summary | grep -A 10 "Top CSS files"

# Check specific file content
grep -E "(\.btn|\.card|\.input)" dist/_astro/*.css
```

**Build fails with guard violations:**
```bash
# Run in CI mode to see what would fail
GUARD_MODE=ci npm run guard:ci

# Check specific violations
npm run debt:summary

# Add allowlist entry for urgent fixes
npm run guard:allow -- --rule=cssBaseline --file="problem-file\.css" --until=2025-09-15 --reason="Hotfix deployment"
```


# Check guard configuration
node -e "import('./scripts/guard/config.mjs').then(c => console.log(JSON.stringify(c.PROFILES, null, 2)))"

# View git context detection
git diff --name-only --cached || git diff --name-only HEAD
```

## 🎯 Current System Status

**CSS Health**: Excellent
- **105.3KB total CSS** (59% of dev budget)
- **2 CSS bundles**: 1 global (85.1KB), 1 route-specific (20.2KB)
- **376 pages served** by global bundle
- **Zero drift** vs baseline

**Quality Gates**: All Passing
- ✅ One global bundle architecture maintained
- ✅ CSS budgets within all enforcement levels
- ✅ Zero technical debt accumulated
- ✅ Repository organization clean

## 📚 Integration

### **CI/CD Pipeline**

The system is integrated into the build process:

```json
{
  "scripts": {
    "build": "... && GUARD_MODE=ci npm run guard:ci && ...",
    "postbuild": "... guardrails verification ..."
  }
}
```

### **Git Hooks**

Pre-push hooks run development checks:
```bash
# In .husky/pre-push
npm run guard:dev
```

### **Development Workflow**

1. **Daily**: `npm run summary` - Check CSS health
2. **Before PR**: `npm run guard:ci` - Verify CI compliance  
3. **After changes**: Compare with baseline, update if intentional
4. **Emergency**: Use allowlist for temporary exceptions

## 🔮 Future Enhancements

- **Escalation schedules**: Rules automatically tighten over time
- **Team-specific budgets**: Different limits per team/feature
- **Performance correlation**: Link CSS size to Core Web Vitals
- **Visual regression**: Screenshot-based CSS change detection

---

**Questions?** Check the generated reports in `__reports/` or run `npm run summary` for current status.

**Need help?** The system is designed to be non-intrusive - when in doubt, use allowlist entries with short expiry dates.
