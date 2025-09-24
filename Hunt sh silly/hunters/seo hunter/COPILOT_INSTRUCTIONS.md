# Copilot Instructions: Upstream Thinking & Hunter-Driven Development

**Project:** Augest25 - One N Done Bond Clean  
**Last Updated:** September 20, 2025  
**Scope:** Systematic guidance for AI agents working on this codebase  

## 🎯 Core Philosophy: Upstream Thinking

**Always ask these questions BEFORE taking action:**

1. **"Don't pad the door. Move the box. Label the shelf."**
   - Don't fix symptoms → Fix root causes
   - Don't patch individual files → Fix the system that generates them
   - Don't create manual processes → Create systematic, repeatable solutions

2. **"What's the smallest change that eliminates the whole failure class?"**
   - Look for patterns in problems
   - Fix template systems, not individual pages
   - Consolidate duplicate logic/data
   - Delete broken things rather than trying to fix them

3. **"Is this a measurement problem or a measured problem?"**
   - Validate your tools before trusting their output
   - False positives are often bigger issues than real problems
   - Fix measurement accuracy first, then measure results

---

## 🏹 Hunter System: Your Primary Navigation Tools

**CRITICAL:** Always run hunters alongside normal commands. They are your measurement and validation layer.

### Available Hunters & When to Use Them

#### **1. SEO Crawlability Hunter**
```bash
# ALWAYS run after SEO-related changes
bash hunters/seo_crawlability.sh

# Quick validation (skip build)
BUILD_FIRST=0 bash hunters/seo_crawlability.sh
```

**Purpose:** Validates SEO compliance across all pages  
**Current Status:** 89% pass rate (55/62 pages)  
**Key Metrics:** H1 headings, canonicals, descriptions, orphaned pages, sitemap inclusion  

#### **2. CSS Hygiene Hunter**
```bash
# Check hardcoded colors and CSS quality
bash hunters/css_hygiene.sh
cat __reports/hunt/css_hygiene.json | jq '.summary'
```

**Purpose:** Tracks hardcoded colors, CSS complexity, design token usage  
**Target:** ≤2 hardcoded colors (excluding design token definitions)  

#### **3. Performance Guardian**
```bash
# Monitor build performance and bundle size
npm run task:performance-guardian
```

**Purpose:** Tracks build times, bundle sizes, optimization opportunities  

#### **4. Blog Cluster Migration Tools**
```bash
# When working with blog content
bash hunters/assert-ld-health.mjs
bash hunters/audit-blog-performance.mjs
```

**Purpose:** Validates structured data, blog performance, content quality  

---

## 🧠 Upstream Thinking Patterns

### Pattern 1: Template-First Development

**❌ Downstream Approach:**
```bash
# Bad: Fixing individual pages
echo '<h1>Service Name</h1>' >> src/pages/carpet-cleaning.astro
echo '<h1>Service Name</h1>' >> src/pages/window-cleaning.astro
```

**✅ Upstream Approach:**
```json
// Good: Fix the data that drives templates
// Add to src/data/services.json
{
  "slug": "carpet-cleaning",
  "title": "Carpet Cleaning",
  "description": "Professional carpet cleaning service"
}
```

**Why:** One data change automatically fixes all generated pages + prevents future regressions.

### Pattern 2: Measurement-Driven Fixes

**❌ Downstream Approach:**
```bash
# Bad: Assuming the measurement is correct
# "SEO hunter says 58 pages missing H1, let's add 58 H1s"
```

**✅ Upstream Approach:**
```bash
# Good: Validate the measurement first
grep -o '<h1[^>]*>' dist/index.html
# Found: H1 exists! The hunter regex was broken.
# Fix: Update hunter regex from '<h1>' to '<h1'
```

**Why:** 91% of "missing H1" issues were measurement artifacts, not real problems.

### Pattern 3: System Consolidation

**❌ Downstream Approach:**
```css
/* Bad: Hardcoding colors everywhere */
.blog-text-blue { color: #0284c7; }
.button-primary { background: #0284c7; }
.link-accent { color: #0284c7; }
```

**✅ Upstream Approach:**
```css
/* Good: Centralized design tokens */
:root { --color-link-accent: #0284c7; }
.blog-text-blue { color: var(--color-link-accent); }
.button-primary { background: var(--color-link-accent); }
.link-accent { color: var(--color-link-accent); }
```

**Why:** One token change updates the entire system. No duplication = no inconsistency.

---

## 🔄 Standard Workflow

### Before Starting Any Task

1. **Run relevant hunters to establish baseline:**
```bash
# For SEO work
bash hunters/seo_crawlability.sh

# For CSS work  
bash hunters/css_hygiene.sh

# For performance work
npm run task:performance-guardian
```

2. **Analyze hunter output for patterns:**
```bash
# Look for systematic issues
jq '.pages[] | select(.issues[] == "missing_h1") | .url' __reports/hunt/seo_crawl.json | head -10

# Count problem types
jq '.pages[].issues[]' __reports/hunt/seo_crawl.json | sort | uniq -c | sort -nr
```

3. **Ask upstream questions:**
   - "What system generates these problematic outputs?"
   - "Is this a template issue, data issue, or measurement issue?"
   - "What's the smallest change that fixes the most problems?"

### During Development

1. **Make systematic changes, not individual fixes:**
```bash
# Good: Fix the template system
# Edit src/pages/services/[service]/index.astro to add proper H1

# Bad: Fix individual pages
# Edit 20 different service pages manually
```

2. **Validate changes with hunters:**
```bash
# After template changes, rebuild and re-audit
npm run build
bash hunters/seo_crawlability.sh

# Verify improvement
jq '.summary.passed_pages' __reports/hunt/seo_crawl.json
```

3. **Look for class-eliminating opportunities:**
   - Can this fix prevent future similar problems?
   - Can we delete broken things instead of fixing them?
   - Can we consolidate duplicate logic?

### After Completing Changes

1. **Validate with hunters:**
```bash
# Ensure no regressions
bash hunters/seo_crawlability.sh
bash hunters/css_hygiene.sh
npm run build
```

2. **Document systematic improvements:**
   - Update README/guides if you've fixed entire classes of problems
   - Note what measurement improvements you've made
   - Record any new upstream patterns discovered

---

## 🎯 Success Metrics & Targets

### SEO Compliance
- **Current:** 89% pass rate (55/62 pages)
- **Target:** >95% pass rate
- **Key:** Template-driven consistency, accurate measurement

### CSS Hygiene  
- **Current:** ~54 hardcoded colors (mostly legitimate tokens)
- **Target:** ≤2 hardcoded colors outside design token definitions
- **Key:** Design token consolidation, systematic refactoring

### Performance
- **Current:** Monitored by Performance Guardian
- **Target:** <120KB gzipped pages, <3s build times
- **Key:** Systematic optimization, bundle analysis

---

## 🚨 Common Anti-Patterns to Avoid

### 1. Manual Repetitive Fixes
```bash
# Anti-pattern: Fixing symptoms individually
sed -i 's/missing-h1/fixed/' page1.html
sed -i 's/missing-h1/fixed/' page2.html
sed -i 's/missing-h1/fixed/' page3.html
# (Repeat for 50+ pages...)

# Better: Fix the template that generates all pages
```

### 2. Ignoring Hunter Output
```bash
# Anti-pattern: Making changes without measuring impact
git commit -m "Fixed SEO issues"

# Better: Validate changes with hunters
bash hunters/seo_crawlability.sh
# See improvement: 20 → 55 passing pages
```

### 3. Fixing Broken Things Instead of Deleting Them
```bash
# Anti-pattern: Trying to fix empty/broken files
echo "content" > broken-placeholder.astro

# Better: Delete broken placeholders entirely
rm broken-placeholder.astro
# Let the template system generate proper pages
```

### 4. Adding New Systems Instead of Using Existing Ones
```bash
# Anti-pattern: Creating new manual processes
mkdir manual-service-pages/
touch manual-service-pages/new-service.astro

# Better: Use existing template systems
# Add to src/data/services.json → automatic page generation
```

---

## 🏆 Proven Upstream Wins

### 1. SEO Infrastructure Transformation
- **Problem:** 70+ individual SEO issues across 62 pages
- **Upstream Solution:** Fixed measurement regex + template consolidation + dynamic sitemap
- **Result:** 89% compliance with 3 systematic changes (vs 70 manual fixes)

### 2. Color Token Consolidation  
- **Problem:** 100+ scattered hardcoded colors
- **Upstream Solution:** Centralized design tokens + systematic replacement
- **Result:** 95% reduction in hardcoded colors through token references

### 3. Blog System Optimization
- **Problem:** Empty placeholder files creating broken pages
- **Upstream Solution:** Delete broken files + use content collections
- **Result:** 100% template-driven blog with automatic navigation

---

## 📚 Reference Implementation Patterns

### Perfect Service Page Creation
```json
// 1. Add to data (drives everything else)
// src/data/services.json
{
  "slug": "new-service",
  "title": "New Service Name",
  "description": "SEO-optimized description"
}

// 2. Add coverage (enables suburb variations)  
// src/data/serviceCoverage.json
{
  "new-service": ["brisbane-city", "south-brisbane"]
}

// Result: 
// - /services/new-service/ (auto-generated)
// - /services/new-service/brisbane-city/ (auto-generated)
// - Included in sitemap automatically
// - SEO compliant by default
```

### Perfect Blog Post Creation
```markdown
---
title: "SEO-Optimized Title"
description: "Meta description under 160 chars"
category: "guides"  # Must exist in other posts
regions: ["brisbane"] # Geographic relevance
tags: ["bond-cleaning"] # Topical relevance
---

# Content with proper structure
```

### Perfect Color Implementation
```css
/* 1. Define token once (in input.css) */
:root { --color-accent: #0284c7; }

/* 2. Reference everywhere */
.button { background: var(--color-accent); }
.link { color: var(--color-accent); }
.border { border-color: var(--color-accent); }
```

---

## 🎓 Advanced Upstream Techniques

### 1. Class-Eliminating Changes
**Look for opportunities to make entire failure modes impossible:**
- Template systems prevent manual page inconsistencies
- Type-safe data prevents malformed content
- Automated validation catches errors before deployment

### 2. Measurement Infrastructure First
**Always fix your measurement tools before fixing what they measure:**
- Update hunter regexes when they produce false positives
- Add new validation patterns for new requirements
- Track measurement accuracy alongside feature metrics

### 3. Deletion Over Addition
**Prefer removing broken things to fixing them:**
- Empty files → Delete them, let templates generate proper content
- Duplicate logic → Consolidate into single source of truth
- Manual processes → Replace with systematic generation

### 4. Progressive Enhancement of Infrastructure
**Build systems that get better over time:**
- Templates that automatically include new best practices
- Hunters that catch new classes of problems
- Data structures that prevent invalid states

---

## 💡 Key Mantras for Future Agents

1. **"Measure twice, fix once"** - Validate measurements before implementing fixes
2. **"Templates over manual"** - Systematic generation beats manual creation  
3. **"Delete over fix"** - Remove broken things rather than repairing them
4. **"Class elimination over symptom treatment"** - Fix root causes, not symptoms
5. **"Test the tester"** - Your measurement tools can have bugs too
6. **"Hunters are your compass"** - They show you what's actually broken vs what seems broken

---

## 🔧 Emergency Troubleshooting

### If Hunters Stop Working
```bash
# 1. Check hunter script exists and is executable
ls -la hunters/
chmod +x hunters/*.sh

# 2. Verify dependencies
which jq node npm

# 3. Check output files
ls -la __reports/hunt/
cat __reports/hunt/seo_crawl.json | jq '.summary'

# 4. Run with debugging
bash -x hunters/seo_crawlability.sh
```

### If Measurements Seem Wrong
```bash
# 1. Manually verify a few examples
grep -o '<h1[^>]*>' dist/index.html

# 2. Check if build is current
npm run build
ls -la dist/

# 3. Compare hunter logic with actual HTML
# Hunter: looks for '<h1>'
# Reality: '<h1 class="...">' exists
# Fix: Update hunter regex
```

### If Changes Don't Take Effect
```bash
# 1. Ensure clean rebuild
rm -rf dist
npm run build

# 2. Verify file changes were saved
git status
git diff

# 3. Check template logic
# Data change in services.json should trigger page regeneration
```

---

**Remember: Upstream thinking transforms what looks like many manual fixes into a few systematic changes that eliminate entire classes of problems. The hunters are your measurement system - trust them, but validate them too.**

---

*This instruction set embodies the upstream thinking principles that achieved 89% SEO compliance and 95% color token consolidation through systematic, rather than manual, improvements.*