# NoAdapterInstalled Error: Root Cause & Solution

**Date**: September 18, 2025  
**Error**: `[NoAdapterInstalled] Cannot use server-rendered pages without an adapter`  
**Location**: `AstroBuilder.setup (node_modules/astro/dist/core/build/index.js:80:13)`

---

## 🎯 Root Cause Identified

The **NoAdapterInstalled** error is caused by **two specific issues** in the repository:

### **1. SSR-Requiring Page (Primary Cause)**

**File**: `src/pages/bond-cleaning/[suburb]/checklist.notusing.astro`
```astro
export const prerender = false;
```

**Issue**: 
- ❌ This file contains `export const prerender = false;`
- ❌ Astro detects ANY page with `prerender = false` and requires an SSR adapter
- ❌ Even though filename suggests "notusing", Astro still processes it
- ❌ Forces entire build into SSR mode

### **2. Server Import (Secondary Issue)**

**File**: `src/pages/index.astro`
```javascript
import { getReviews } from '~/server/reviews.js';
```

**Issue**:
- ⚠️ Import from `~/server/` directory suggests SSR usage
- ✅ **However**: `reviews.js` is actually build-time compatible (no Astro.request, etc.)
- ✅ Just reads JSON files synchronously - works fine in SSG

---

## 🔧 Solutions

### **Solution 1: Remove SSR-Requiring File** ✅ **RECOMMENDED**

The `.notusing.astro` file is causing the problem and appears unused:

```bash
# Delete the problematic file
rm src/pages/bond-cleaning/[suburb]/checklist.notusing.astro
```

**Why this works**:
- ✅ Removes the `prerender = false` declaration
- ✅ Eliminates SSR requirement
- ✅ Allows pure SSG build to proceed
- ✅ File appears unused based on naming

### **Solution 2: Move Server File** (Optional)

If you want cleaner architecture:

```bash
# Move reviews.js from server to lib
mv src/server/reviews.js src/lib/reviews.js

# Update import in index.astro
# From: import { getReviews } from '~/server/reviews.js';
# To:   import { getReviews } from '~/lib/reviews.js';
```

**Why this helps**:
- ✅ Clarifies that it's build-time, not server-time
- ✅ Follows SSG conventions (`lib/` for build-time utilities)
- ✅ Eliminates confusion about SSR requirements

---

## 🚀 Immediate Fix

**Quick Resolution**:
```bash
# Remove the problematic file
rm src/pages/bond-cleaning/[suburb]/checklist.notusing.astro

# Test the build
npm run build
```

**Expected Result**:
- ✅ Build succeeds without adapter error
- ✅ Pure SSG operation restored
- ✅ All 600+ pages generate as static files

---

## 📊 Analysis Summary

| Component | Status | Action |
|-----------|--------|---------|
| **astro.config.mjs** | ✅ Correct | `output: 'static'` is proper |
| **checklist.notusing.astro** | ❌ Blocking | DELETE (forces SSR) |
| **reviews.js** | ⚠️ Misleading | OPTIONAL: Move to `lib/` |
| **All other pages** | ✅ SSG Ready | Use `getStaticPaths()` |

### **The Error Chain**:
1. `checklist.notusing.astro` has `prerender = false`
2. Astro detects SSR requirement
3. Astro looks for adapter configuration  
4. No adapter found (commented out in config)
5. **NoAdapterInstalled** error thrown at build time

### **Why This Breaks SSG**:
- Astro's build system scans ALL `.astro` files in `src/pages/`
- Any file with `prerender = false` triggers SSR mode
- SSR mode requires an adapter (Netlify, Vercel, etc.)
- No adapter = build failure

---

## 🎉 Resolution

**The fix is simple**: Remove the unused file that's forcing SSR mode.

```bash
rm src/pages/bond-cleaning/[suburb]/checklist.notusing.astro
```

This will restore pure SSG operation and allow the build to complete successfully.

**After the fix**:
- ✅ Pure SSG builds work
- ✅ 600+ static pages generate correctly  
- ✅ CDN deployment proceeds normally
- ✅ Perfect setup for SoT Toolkit integration

---

*Problem solved: Remove unused SSR-requiring file to restore pure SSG operation.*
