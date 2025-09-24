# Root-Cause Engineering Journal

**Purpose:** Track class-eliminating changes and upstream thinking applications  
**Format:** Symptom → Upstream cause → Class-eliminating change → Invariant added → Siblings handled  

---

## 2025-09-19: CSS Hygiene → Systemic Architecture Engineering

**Symptom:** 288 CSS hygiene violations and recurring build failures from file corruption

**Upstream Cause:** No architectural constraints on file operations and design system compliance - 33 build scripts using dangerous patterns without governance

**Class-Eliminating Change:** 
- Eliminated inline style attribute class entirely (3 instances → 0)
- Consolidated all file operations through single safe utility (33 dangerous patterns → 1 governed utility)
- Established CI policy enforcement preventing regression (manual review → automatic failure)

**Invariant Added:** 
- `scripts/build-safety-check.mjs` - CI fails on dangerous file operation patterns
- `scripts/css-hygiene-check.mjs` - CI fails on inline styles and hardcoded colors
- `scripts/utils/safe-file-ops.mjs` - Audit trail logging with .astro structure validation

**Siblings Handled:**
- All hardcoded colors centralized to `src/styles/input.css` design tokens
- Build-aware monitoring implemented with `rg-hunt-build-aware.sh`
- File corruption prevention through AST-aware transformations
- TODO debt threshold management with CI enforcement

**Complexity Delta:** 
- Paths removed: 33 (dangerous file operation patterns)
- Configs removed: 17+ (unused CSS classes, scattered color definitions)
- Single sources of truth: 3 established (file ops, CSS tokens, build safety)

**Evidence Window:** Last 30 days - recurring Polaroid.astro corruption proved systemic build interference

**Rollback Plan:** Remove safe utility, restore individual script patterns, disable CI enforcement

---