# Action Items - Protective Complexity Cleanup

Generated from audit: `node scripts/audit-protective-complexity.mjs --write`

## 🔴 High Priority Actions

### 1. Centralize URL Management ✅ COMPLETED
**Issue**: Legacy redirects/aliases scattered across codebase  
**Impact**: Multiple URL truths, drift risk, maintenance overhead

**Action Plan**:
- [x] Create `src/lib/routes.ts` as single source of truth
- [x] Replace hardcoded URLs with route helpers
- [x] Add CI guard: `./scripts/ci/url-drift-guard.sh` ✅ PASSING
- [ ] Remove non-evidenced redirects from netlify.toml

**Results**: 
- ✅ **18 hardcoded URLs eliminated** (8 blog + 6 services + 4 suburbs)
- ✅ CI guard prevents future drift
- ✅ All navigation flows through centralized helpers

### 2. Fix Duplicate Blog URLs ✅ COMPLETED  
**Issue**: Literal `/blog/` links outside route builder
**Impact**: Inconsistent navigation, URL drift

**Results**: All `/blog/` URLs now use `routes.blog.*` helpers:
- [x] src/layouts/BaseLayout.astro navigation
- [x] src/pages/blog/[slug].astro canonicals  
- [x] src/pages/blog/index.astro links
- [x] src/pages/blog/rss.xml.ts feeds
- [x] src/pages/rss.xml.ts feeds
- [x] src/pages/sitemap.xml.ts URLs
- [x] src/pages/services/[service]/[suburb].astro links
- [x] src/pages/suburbs/[suburb].astro links

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

- **URL Centralization**: ✅ `./scripts/ci/url-drift-guard.sh` PASSES - 0 hardcoded URLs
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
