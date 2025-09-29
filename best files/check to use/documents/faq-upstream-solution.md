# 🎯 FAQ SYSTEM UPSTREAM-CURIOUS TRANSFORMATION
**Implementation of class-eliminating solution based on hunter findings**

## 📊 **HUNTER DISCOVERY: MASSIVE FAQ CHAOS**

**Current State (Critical):**
- **39 FAQ-related files** across the codebase
- **4 schema variations** causing build conflicts
- **4 redundant components** doing similar jobs
- **7 build scripts** with overlapping functionality  
- **High maintenance complexity** with no single source of truth

## 🎯 **UPSTREAM-CURIOUS SOLUTION: UNIFIED FAQ ARCHITECTURE**

Following the **Box → Closet → Policy** framework:

### **The Plan:**
1. **Single source of truth:** `src/content/faqs.ts` (typed content collection)
2. **Smart component:** `src/components/ContextualFAQ.astro` (auto-detects page context)
3. **Page-context routing:** Automatic FAQ selection based on route/page type
4. **Complexity elimination:** Remove 15+ redundant files

---

## 🔧 **IMPLEMENTATION: PHASE 1 - UNIFIED CONTENT COLLECTION**
