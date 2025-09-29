# CSS Guardrails — Triage Guide

## Overview

Our CSS architecture is protected by a comprehensive guardrail system that prevents performance regressions and maintains code quality. This guide helps you quickly diagnose and fix issues when they occur.

## 🛡️ Guardrail Types

### 1. CSS Duplication Detector
**Purpose**: Prevents multiple large CSS bundles containing the same global styles  
**Command**: `npm run css:audit-duplicates`

### 2. CSS Source Map Tracer  
**Purpose**: Maps CSS bundles back to source modules for debugging  
**Command**: `npm run css:map-sources`

### 3. Global Import Detector
**Purpose**: Ensures main.css is imported only in approved layout files  
**Command**: `npm run detect:global-css`

### 4. CSS Budget Auditor
**Purpose**: Enforces size limits to prevent CSS bloat  
**Command**: `npm run css:audit-budgets`

### 5. CSS Investigator 🔍
**Purpose**: Comprehensive CSS analysis - which pages use which bundles, JS-to-CSS mapping, selector overlap analysis  
**Command**: `npm run css:investigate`

## 🚨 When Guardrails Fail

### If "CSS Duplicates" Fails

```bash
# 1. Check current duplication status
npm run css:audit-duplicates

# 2. Enable source maps and trace the issue
CSS_MAP_ENABLE=1 npm run build
npm run css:map-sources

# 3. Examine the debug report
cat __reports/map-css-sources.json
```

**Common Causes**:
- Component importing `main.css` directly
- Multiple layouts importing global CSS
- Component with `@import "tailwindcss"` in `<style>` block

**Fix**: Remove extra `main.css` imports outside of approved layouts

### If "Global Import" Fails

**Error**: `main.css imported outside the root layout`

**Allowed Locations**:
- `src/layouts/MainLayout.astro` ✅
- `src/layouts/BaseLayout.astro` ✅  
- `src/layouts/Layout.astro` ✅

**Fix**: 
1. Move `import '~/styles/main.css'` to an approved layout
2. Remove any `@import "tailwindcss"` from components
3. Move component styles to `src/styles/main.css` under `@layer components`

**Custom Layouts**: Set environment variable:
```bash
GLOBAL_IMPORT_ALLOWLIST="src/layouts/CustomLayout.astro" npm run detect:global-css
```

### If "CSS Budgets" Fail

**Current Budgets**:
- Max single file: 120KB (configurable via `BUDGET_CSS_FILE`)
- Total CSS: 180KB (configurable via `BUDGET_CSS_TOTAL`)

**Analysis**:
```bash
npm run css:audit-budgets
# Check the "largest" array in output for biggest files
```

**Fixes**:
- Review largest CSS files for bloat
- Deduplicate shared component styles  
- Move large component CSS to separate chunks
- As last resort: Raise budgets with justification

### Deep CSS Investigation

**Quick Commands**:
```bash
# Size overview (largest first)
npm run css:list

# Find pages using specific CSS file
CSS="_suburb_.uBeUre1a.css" npm run css:find

# See usage clustered by route/section
CSS="_suburb_.uBeUre1a.css" npm run css:usage

# Full analysis with global signatures
npm run css:investigate
```

**What each shows**:

1. **css:list** - File sizes overview, total CSS weight
2. **css:find** - Exact pages that reference a CSS file (HTML scan)
3. **css:usage** - Route clustering (services/bond-cleaning: 119, areas/brisbane: 49, etc.)
4. **css:investigate** - Global vs route signatures, comprehensive analysis

**Real Example Output**:
```
[css:usage] _suburb_.uBeUre1a.css used by 188 page(s). Grouped by route:
  - services/bond-cleaning: 119
  - services/spring-cleaning: 58
  - services/bathroom-deep-clean: 10
  - root: 1
```

**Output**: Console summary + JSON reports in `__reports/`

## 🔧 Environment Configuration

### CSS Duplication
```bash
CSS_DUP_SOFT_FAIL=1           # Warning mode (emergency override)
CSS_DUP_THRESHOLD_KB=8        # Size threshold for analysis
CSS_DUP_ALLOWLIST="vendor.css" # Skip specific files
```

### CSS Budgets
```bash
BUDGET_CSS_TOTAL=140000       # 140KB total CSS budget
BUDGET_CSS_FILE=110000        # 110KB max single file
```

### Global Imports
```bash
GLOBAL_IMPORT_ALLOWLIST="src/layouts/Shell.astro"  # Additional allowed layouts
FAIL_TAILWIND_IN_COMPONENTS=0 # Disable component Tailwind check
```

### Source Maps & Manifest
```bash
CSS_MAP_ENABLE=1              # Enable CSS source maps for debugging
VITE_MANIFEST=1               # Enable Vite manifest for JS-to-CSS mapping
```

### CSS Investigation
```bash
CSS_PATTERN="_suburb_.*\\.css"  # Regex pattern for CSS files to analyze
CSS_TOP_PAGES=50              # Max pages to show per CSS file
CSS_TOP_OVERLAPS=60           # Max overlapping selectors to show
```

## 📊 Reports & Artifacts

All guardrails generate JSON reports in `__reports/`:

- `audit-css-duplicates.json` - Duplication analysis
- `map-css-sources.json` - Source mapping data

These are automatically uploaded as CI artifacts for debugging.

## ⚡ Emergency Overrides

**Soft Fail Mode** (allows deployment with warnings):
```bash
CSS_DUP_SOFT_FAIL=1 npm run build
```

**Temporarily Raise Budgets**:
```bash
BUDGET_CSS_TOTAL=200000 BUDGET_CSS_FILE=150000 npm run build
```

## 📈 Current Status (Healthy Baseline)

```json
{
  "totalCSS": "105.6KB",
  "largestFile": "84.9KB", 
  "duplication": "none",
  "globalImports": "compliant"
}
```

## 🔍 Investigation Workflow

```bash
# 1. Get overview
npm run css:list

# 2. Investigate specific files  
CSS="filename.css" npm run css:find
CSS="filename.css" npm run css:usage

# 3. Full analysis when needed
npm run css:investigate

# 4. Debug with source maps (if needed)
CSS_MAP_ENABLE=1 npm run build
npm run css:map-sources

# 5. Check for regressions
npm run css:baseline:check
npm run css:assert:one-global
```

## 🏆 Production Integration

**Build Pipeline**: Automated checks run in every build
**CI/CD**: Violations fail the deployment  
**Monitoring**: JSON reports for artifact storage
**Alerts**: Precise violation messages with deltas

## � Automated Regression Detection

### Never-Regress System
The system now automatically prevents CSS architecture violations:

```bash
# Capture current state as baseline (run once when healthy)
npm run css:baseline:update

# Check for regressions (runs in build pipeline automatically)
npm run css:baseline:check

# Assert exactly one global bundle (fails if architecture breaks)
npm run css:assert:one-global
```

### What Gets Detected Automatically

**Size Regressions**:
- Individual CSS file grows >10KB from baseline
- Total CSS weight grows >25KB from baseline  
- New CSS files appear unexpectedly

**Usage Regressions**:
- CSS file reaches >50 more pages than baseline
- Global signatures appear in route-specific CSS
- Global signatures disappear from global CSS

**Architecture Violations**:
- Multiple CSS files contain global signatures (duplication)
- No CSS files contain global signatures (missing global styles)

### Emergency Overrides

If urgent deployment needed despite violations:
```bash
# Skip baseline check temporarily
CSS_BASELINE_MODE=skip npm run build

# Relax tolerances temporarily  
CSS_BASELINE_MAX_FILE_KB_DELTA=20 npm run build

# Update baseline to current state
npm run css:baseline:update && npm run build
```

## 🚀 Getting Help

- Review this guide first
- Check `__reports/*.json` for detailed analysis  
- Use `CSS_MAP_ENABLE=1` to debug source modules
- Consider soft-fail mode for emergency deployments
- Update budgets with justification when legitimate growth occurs
