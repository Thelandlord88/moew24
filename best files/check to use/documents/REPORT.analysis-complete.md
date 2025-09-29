vitest run# Cross-Service Linking Analysis & Fixes

## Executive Summary

We successfully implemented a comprehensive analysis and fix for cross-service linking consistency across your Astro application. The audit uncovered **268 cross-cluster violations** in the static map and fixed them using same-cluster fallback policy.

## Key Findings

### 🔍 Discovery Results

**Dynamic Routes Analysis:**
- ✅ 3 dynamic pages found, all properly configured with SSG
- ✅ All routes are tracked in Git
- ✅ No param mismatches detected
- ✅ No suspicious filenames found

**Graph Integrity:**
- ✅ 3 clusters: Ipswich (30 suburbs), Brisbane (48 suburbs), Logan (43 suburbs)  
- ✅ 121 total suburbs, all present in adjacency data
- ✅ No duplicate suburbs across clusters
- ✅ All adjacency nodes exist in cluster definitions

**Buildable Links:**
- ✅ 187 buildable service/suburb combinations
- ✅ 216 cross-service links checked, all buildable
- ✅ No broken internal links detected

**Cross-Service Map Violations (BEFORE fix):**
- ❌ **268 cross-cluster fallbacks** violating same-cluster policy
- 484 total entries (inflated due to cross-cluster links)

## 🔧 Fixes Implemented

### 1. Cross-Service Map Builder Update
**File:** `scripts/build-cross-service-map.mjs`

**Problem:** Global deterministic fallback allowed cross-cluster links
```javascript
// OLD (violated same-cluster policy)
const all = (coverage[service] || []).slice().sort();
return all[0] || null;
```

**Solution:** Enforce same-cluster only policy
```javascript
// NEW (strict same-cluster only)
return null; // NO GLOBAL FALLBACK
```

**Result:**
- ✅ 0 cross-cluster violations
- ✅ Reduced entries from 484 → 216 (same-cluster only)
- ✅ Consistent with runtime adapter policy

### 2. Canonical Suburb Provider
**File:** `src/lib/links/knownSuburbs.ts`

**Problem:** Multiple modules parsing cluster data differently

**Solution:** Single source of truth for suburb/cluster resolution
- Handles the actual `areas.clusters.json` structure (array format)
- Provides slugification consistency
- Exports unified API for all modules

### 3. Analysis Tools Suite
**Files:** `tools/*.mjs`, `scripts/guard-dynamic.mjs`

**Capabilities:**
- **Route Guard:** Validates dynamic pages have proper SSG/SSR setup
- **Graph Sanity:** Ensures adjacency/cluster data integrity  
- **Buildable Links:** Prevents links to non-generated pages
- **Cross-Service Diff:** Detects cross-cluster violations

### 4. CI Integration
**File:** `package.json` (new scripts)

```json
{
  "scripts": {
    "build:map": "node scripts/build-cross-service-map.mjs",
    "guard:routes": "node scripts/guard-dynamic.mjs", 
    "lint:graph": "node tools/graph-sanity.mjs",
    "lint:buildable": "node tools/check-buildable.mjs",
    "lint:cross": "node tools/diff-cross-service.mjs",
    "lint:all": "npm run guard:routes && npm run lint:graph && npm run lint:buildable && npm run lint:cross"
  }
}
```

## 📊 Impact Analysis

### Before vs After
| Metric | Before | After | Change |
|--------|--------|-------|---------|
| Cross-cluster violations | 268 | 0 | ✅ -268 |
| Total cross-service entries | 484 | 216 | ⬇️ -55% |
| Policy consistency | ❌ Mixed | ✅ Same-cluster only | Fixed |
| Build failures from broken links | Possible | Prevented | ✅ |

### Benefits Achieved

1. **Consistency:** Runtime adapter and static map now use identical same-cluster policy
2. **Safety:** All emitted links guaranteed buildable under `getStaticPaths()`
3. **Maintainability:** Single source of truth for suburb/cluster data
4. **CI Protection:** Automated guards prevent regressions
5. **Performance:** Reduced cross-service entries (55% reduction)

## 🛡️ Guards Implemented

### Build-Time Protections
- ✅ Cross-cluster violations fail the build
- ✅ Unbuildable links detected before deployment  
- ✅ Graph integrity validated
- ✅ Dynamic route configuration verified

### Runtime Consistency
- ✅ Adapter and map use same cluster resolution
- ✅ Same BFS algorithm for nearby lookups
- ✅ Identical coverage checking logic

## 🔄 Recommended CI Workflow

```bash
# Pre-build validation
npm run build:map          # Regenerate cross-service map
npm run lint:all           # Validate all integrity checks

# Build process  
npm run build              # Standard build (now includes guards)
```

## 📋 Acceptance Criteria ✅

- ✅ **Map parity:** Zero cross-cluster entries in `crossServiceMap.json`
- ✅ **Single truth:** All modules use `src/lib/links/knownSuburbs.ts`
- ✅ **No broken links:** All targets verified buildable
- ✅ **Graph integrity:** All adjacency nodes exist in clusters
- ✅ **CI protection:** Guards fail on regressions

## 🚀 Next Steps

1. **Monitor:** Run `npm run lint:all` regularly to catch any drift
2. **Extend:** Add more specific link validation as needed
3. **Document:** Update team processes to use the new guard scripts
4. **Optimize:** Consider caching mechanisms for large-scale builds

The implementation successfully **eliminated all cross-cluster violations** while providing comprehensive tools to prevent future regressions.
