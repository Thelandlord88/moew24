# Action Items - Protective Complexity Cleanup

Generated from audit: `node scripts/audit-protective-complexity.mjs --write`

## 🔴 High Priority Actions

### 1. Centralize URL Management (42 hits)
**Issue**: Legacy redirects/aliases scattered across codebase  
**Impact**: Multiple URL truths, drift risk, maintenance overhead

**Action Plan**:
- [ ] Create `src/lib/routes/blog.ts` as single source of truth
- [ ] Replace hardcoded URLs with route helpers
- [ ] Remove non-evidenced redirects from netlify.toml
- [ ] Add CI guard: `rg '/blog/' src --type astro --type ts | grep -v 'lib/routes' && exit 1`

**Files to clean up**:
- astro-adapter-fix.sh (3 hits)
- src/pages/*/[slug].astro (redirect calls)
- netlify.toml (redirect rules)

### 2. Fix Duplicate Blog URLs (9 hits)  
**Issue**: Literal `/blog/` links outside route builder
**Impact**: Inconsistent navigation, URL drift

**Action Plan**:
- [ ] Create route helper functions in `src/lib/routes/blog.ts`:
  ```ts
  export const blogRoutes = {
    index: () => '/blog/',
    post: (slug: string) => `/blog/${slug}/`,
    rss: () => '/blog/rss.xml'
  };
  ```
- [ ] Replace literals in:
  - src/layouts/BaseLayout.astro:31
  - src/pages/blog/[slug].astro:17
  - src/pages/blog/index.astro (2 hits)
  - src/pages/services/[service]/[suburb].astro:67

### 3. Clean Config Sprawl (30 hits)
**Issue**: Multiple ESLint/Prettier configs detected  
**Impact**: Inconsistent tooling, maintenance burden

**Action Plan**:
- [ ] Audit package-lock.json for redundant linting deps
- [ ] Choose single ESLint config approach  
- [ ] Remove conflicting/unused linter configs
- [ ] Document chosen tooling in README.md

## 🟡 Medium Priority

### 4. Address Technical Debt (5 hits)
- [ ] Review TODO markers in bootstrap.sh:960
- [ ] Clean audit script references to itself
- [ ] Document debt items that stay vs removal plan

### 5. SEO Infrastructure Health Check
**Good news**: 17 sitemap/RSS mentions + 15 JSON-LD schema hits show healthy SEO setup
- [ ] Validate sitemap generation works end-to-end
- [ ] Test RSS feed output format
- [ ] Verify JSON-LD structure with Google testing tool

## Implementation Priority

1. **Week 1**: URL centralization (route helpers)
2. **Week 2**: Config sprawl cleanup  
3. **Week 3**: Technical debt review
4. **Week 4**: SEO validation suite

## Success Metrics

- **URL Centralization**: `rg '/blog/' src` returns 0 hits outside routes module
- **Config Cleanup**: Single linting config per concern
- **Build Health**: All guards pass, faster dependency resolution
- **SEO Stability**: Sitemap + JSON-LD pass validation

## Rollback Plan

Each change should be atomic PRs with:
- Clear before/after comparison
- Test evidence (build passes, links work)
- Archived removed code under `docs/ops/removed-YYYY-MM-DD/`

---
*Generated: 2025-09-11 via protective complexity audit*
