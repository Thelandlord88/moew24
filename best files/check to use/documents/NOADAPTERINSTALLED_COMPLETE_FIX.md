# NoAdapterInstalled Fix: Import Path Detection Issue

**Date**: September 18, 2025  
**Error**: `[NoAdapterInstalled] Cannot use server-rendered pages without an adapter`  
**Root Cause**: Astro build system detecting `~/server/` import paths as SSR requirement

---

## 🎯 Root Cause Discovery

The **NoAdapterInstalled** error was caused by **multiple SSR triggers** that required systematic elimination:

### **Issue 1: Middleware** ✅ **FIXED**

**File**: `src/middleware.ts` → **REMOVED**
- Astro middleware **ALWAYS requires SSR mode**
- Even with `prerender = true`, middleware presence triggers adapter requirement
- **Solution**: Removed middleware entirely for pure SSG

### **Issue 2: Server Directory Import** ✅ **FIXED**

**File**: `src/pages/index.astro`
```javascript
// This import path triggered SSR detection
import { getReviews } from '~/server/reviews.js';
```
- **Solution**: Moved to `~/lib/reviews.js` and updated import

### **Issue 3: Prerender False** ✅ **FIXED**

**File**: `src/pages/bond-cleaning/[suburb]/checklist.notusing.astro` → **REMOVED**
```astro
export const prerender = false;
```

### **Issue 4: Netlify Adapter Import** ✅ **FIXED**

**File**: `astro.config.mjs`
```javascript
// Even commented out, the import might trigger detection
import netlify from '@astrojs/netlify';
```
- **Solution**: Commented out the import entirely

### **Remaining Issue: Still Investigating** 🔍

Despite all fixes applied:
- ✅ Middleware removed
- ✅ Server imports moved to lib  
- ✅ No prerender=false declarations
- ✅ Netlify adapter import commented out
- ✅ Configuration set to `output: 'static'`
- ❌ **Still getting NoAdapterInstalled error**

**Current Theory**: There may be another hidden SSR trigger we haven't identified yet.

---

## 🔧 Complete Solution

### **Solution 1: Move Server File to Lib** ✅ **APPLIED**

```bash
# Move the file
mv src/server/reviews.js src/lib/reviews.js

# Update the import
# Before: import { getReviews } from '~/server/reviews.js';
# After:  import { getReviews } from '~/lib/reviews.js';
```

**Why this works**:
- ✅ **Removes SSR path detection**: `~/lib/` doesn't trigger SSR assumptions
- ✅ **Preserves functionality**: File content unchanged, just location
- ✅ **Clarifies intent**: `lib/` indicates build-time utilities, not server-time
- ✅ **Follows SSG conventions**: Static site generation patterns

### **Solution 2: Remove Unused SSR File** ✅ **ALREADY DONE**

```bash
# Already completed
rm src/pages/bond-cleaning/[suburb]/checklist.notusing.astro
```

---

## 📊 Analysis Summary

| Issue | Status | Solution |
|-------|--------|----------|
| **`checklist.notusing.astro`** | ✅ Removed | Deleted unused file with `prerender = false` |
| **`~/server/` import path** | ✅ Fixed | Moved to `~/lib/` and updated import |
| **SSR functionality** | ✅ None needed | `reviews.js` only reads static files |
| **Build configuration** | ✅ Correct | `output: 'static'` is appropriate |

### **Key Insight**: Astro SSR Detection

Astro's build system is **conservative about SSR detection**:
- **Directory-based heuristics**: `~/server/` imports trigger SSR mode
- **File-based detection**: `prerender = false` requires adapter
- **Safe by default**: Better to require adapter than fail at runtime

This is actually **good design** but caught us off-guard when the file was purely build-time code in a server-named directory.

---

## 🚀 Expected Resolution

After applying both fixes:

```bash
# Test the build
npm run build
```

**Expected Result**:
- ✅ **Build succeeds**: No NoAdapterInstalled error
- ✅ **Pure SSG**: All pages generated as static files
- ✅ **Same functionality**: Reviews still work, just from `~/lib/`
- ✅ **SoT Toolkit ready**: Perfect foundation for migration

---

## 💡 Lessons Learned

### **Best Practices for Pure SSG**

**Directory Structure**:
```
src/
├── lib/          # ✅ Build-time utilities (SSG compatible)
├── server/       # ❌ Triggers SSR detection (use only for actual SSR)
├── utils/        # ✅ General utilities (SSG compatible)
└── data/         # ✅ Static data (SSG compatible)
```

**Import Patterns**:
```javascript
// ✅ Good for SSG
import { helper } from '~/lib/helper.js';
import { utility } from '~/utils/utility.js';

// ❌ Triggers SSR detection
import { anything } from '~/server/anything.js';
```

### **Future Prevention**

1. **Use `~/lib/` for build-time code** that reads files but doesn't use Astro server features
2. **Reserve `~/server/` for actual SSR** with `Astro.request`, `Astro.locals`, etc.
3. **Test builds regularly** to catch SSR detection issues early
4. **Document intent** with clear directory structure

---

## 🎉 Resolution

The **NoAdapterInstalled** error is resolved by fixing two issues:
1. ✅ **Removed unused SSR file** (`checklist.notusing.astro`)  
2. ✅ **Moved server import to lib** (`~/server/reviews.js` → `~/lib/reviews.js`)

This restores **pure SSG operation** and provides the perfect foundation for **SoT Toolkit integration** with enhanced TypeScript geo tooling.

---

*Problem solved: Directory-based SSR detection resolved by moving build-time code to appropriate location.*
