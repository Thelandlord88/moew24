# Repository Tree (Proposed)

_Heuristic re-organization by file name/type. Convention-leaning (Astro/Tailwind):_
- Code lives in `src/` (components/pages/layouts/utils/lib/gen/hooks/routes).
- Scripts live in `scripts/` with topical subfolders (e.g., `scripts/geo/`).
- Data lives in `data/` with topical subfolders; geospatial in `data/geo/`, graphs in `data/geo/graph/`.
- Schemas in `schemas/`, docs in `docs/`, reports in `reports/`, tests in `tests/`.
- Public assets in `public/images/`.
- Root configs remain at the project root.

### Legend (category → count)
- **tests**: 569
- **scripts**: 183
- **src**: 134
- **docs**: 94
- **report**: 60
- **assets**: 51
- **data-general**: 48
- **misc**: 44
- **data-geo**: 36
- **root-config**: 15
- **keep**: 12
- **schema**: 9
- **data-geo-graph**: 8
- **data-seo**: 4

> Note: vendor/cache directories (e.g., `node_modules/`, `dist/`, `.astro/`) are omitted from the proposed layout.

```
├── .github/
│   ├── workflows/
│   │   ├── _lhci.yml
│   │   ├── ai-review.yml
│   │   ├── blog-base-guards.yml
│   │   ├── ci.yml
│   │   ├── codeql.yml
│   │   ├── geo-gate.yml
│   │   ├── lhci.yml
│   │   ├── qa.yml
│   │   └── verify-graph.yml
│   ├── PR_BODY.md
│   ├── dependabot.yml
│   └── pr-12-body.md
├── data/
│   ├── general/
│   │   ├── .lighthouserc.json
│   │   ├── acceptance.bond-clean.json
│   │   ├── ai-rules.json
│   │   ├── ai-rules.json
│   │   ├── aliases.json
│   │   ├── all-pages.json
│   │   ├── anchor-locations.csv
│   │   ├── anchor-locations.json
│   │   ├── anchor.templates.json
│   │   ├── blog-reviews.json
│   │   ├── cards.areas.json
│   │   ├── cards.home.json
│   │   ├── content-audit-strict.json
│   │   ├── content-audit.json
│   │   ├── content-policy-strict.json
│   │   ├── content-policy-strict.json
│   │   ├── content-policy.json
│   │   ├── content-policy.json
│   │   ├── css.json
│   │   ├── faq-issues-suggestions.json
│   │   ├── faq.generic.json
│   │   ├── faq.service-bathroom.json
│   │   ├── faq.service-bond.json
│   │   ├── faq.service-spring.json
│   │   ├── faqs.compiled.json
│   │   ├── faqs.compiled.json
│   │   ├── gallery.json
│   │   ├── ld-multiples.json
│   │   ├── ld-pages.json
│   │   ├── ld-required-types.json
│   │   ├── ld-sources.json
│   │   ├── meta-manifest.json
│   │   ├── meta-manifest.json
│   │   ├── review-receipts.json
│   │   ├── reviews.json
│   │   ├── seed-reviews.json
│   │   ├── serviceCoverage.full.json
│   │   ├── serviceCoverage.initial10.json
│   │   ├── serviceCoverage.json
│   │   ├── serviceCoverage.json
│   │   ├── serviceCoverage.source.json
│   │   ├── serviceCoverage.source.json
│   │   ├── services.json
│   │   ├── topics.json
│   │   ├── tsconfig.json
│   │   ├── tsconfig.json
│   │   ├── tsconfig.playwright.json
│   │   └── upstream-issues.json
│   ├── geo/
│   │   ├── graph/
│   │   │   ├── adj.bridges.json
│   │   │   ├── adj.config.json
│   │   │   ├── adjacency-history.json
│   │   │   ├── adjacency.json
│   │   │   ├── adjacency.json
│   │   │   ├── adjacency.json
│   │   │   ├── adjacency.json
│   │   │   └── geo-bridge-candidates.json
│   │   ├── areas.clusters.json
│   │   ├── areas.clusters.json
│   │   ├── areas.clusters.json
│   │   ├── areas.extended.clusters.json
│   │   ├── areas.extended.clusters.json
│   │   ├── areas.hierarchical.clusters.json
│   │   ├── crossServiceMap.json
│   │   ├── faq.suburb.springfield-lakes.json
│   │   ├── geo-metrics.baseline.json
│   │   ├── geo-proximity-diff.json
│   │   ├── geo.hashes.json
│   │   ├── geo.integrity.json
│   │   ├── geo.integrity.json
│   │   ├── geo.integrity.local.json
│   │   ├── geo.linking.config.json
│   │   ├── geo.neighbors.brisbane-west.json
│   │   ├── geo.neighbors.brisbane-west.json
│   │   ├── geo.neighbors.ipswich.json
│   │   ├── geo.neighbors.ipswich.json
│   │   ├── geo.neighbors.logan.json
│   │   ├── geo.neighbors.logan.json
│   │   ├── geo.policy.json
│   │   ├── lga.groups.json
│   │   ├── lgas.groups.json
│   │   ├── lgas.groups.json
│   │   ├── refactor-map.json
│   │   ├── suburbs.aliases.json
│   │   ├── suburbs.aliases.json
│   │   ├── suburbs.coords.json
│   │   ├── suburbs.coords.json
│   │   ├── suburbs.coords.json
│   │   ├── suburbs.index.json
│   │   ├── suburbs.index.json
│   │   ├── suburbs.json
│   │   ├── suburbs.meta.json
│   │   └── synonyms.map.json
│   └── seo/
│       ├── cross-links-failures.json
│       ├── inbound-links.blog.ipswich.json
│       ├── internal-links.json
│       └── outbound-links.blog.ipswich.json
├── docs/
│   ├── # Code Citations.md
│   ├── ASTRO-LATEST-IMPLEMENTATION.md
│   ├── BRIDGE_BUILDING_SUBURBS.md
│   ├── BRIDGE_MAKING.md
│   ├── CODE-CITATIONS.md
│   ├── CONTENT_AUDITOR.md
│   ├── CONTENT_AUDITOR.md
│   ├── CONTRIBUTING.md
│   ├── CSS-EXTENDED-CLEANUP-COMPLETE.md
│   ├── CSS-INVESTIGATION-DEBRIEF.md
│   ├── DEVELOPMENT_JOURNAL.md
│   ├── Details.txt
│   ├── GEOGRAPHIC_DATA_ARCHITECTURE_OVERHAUL_REPORT.md
│   ├── GEO_FULL_IMPLEMENTATION_OVERVIEW.md
│   ├── GEO_PHASE2_PLAN.md
│   ├── GEO_PHASE2_STATUS_AND_ROADMAP.md
│   ├── GEO_SEO_LINKING_STRATEGY.md
│   ├── GEO_STATUS_REPORT.md
│   ├── GEO_SUBCLUSTERS_PROPOSAL.md
│   ├── HARDENING_SESSION_LOG.md
│   ├── MID_WORK_IMPLEMENTATION_DEBRIEF.md
│   ├── MORE_ABOUT_API_FAQ.md
│   ├── NETLIFY_SETUP_COMPLETE.md
│   ├── OWNER_TODO.md
│   ├── PERFORMANCE-DEBRIEF.md
│   ├── PROVENANCE.md
│   ├── README-GUARD.md
│   ├── README-Geo-Linking.md
│   ├── README.geo-data.md
│   ├── README.geo-data.md
│   ├── README.md
│   ├── README.md
│   ├── README.md
│   ├── REPORT.analysis-complete.md
│   ├── REPORT.technical-expanded.md
│   ├── REPO_FILES.md
│   ├── REPO_GUIDE.md
│   ├── SESSION_COMPLETION_SUMMARY.md
│   ├── Service-troubleshooting.md
│   ├── UPGRADE-COMPLETE-SUMMARY.md
│   ├── VIEW-TRANSITIONS-FIXED.md
│   ├── VITEST_STABILIZATION_COMPLETE.md
│   ├── __all_files_tmp.txt
│   ├── adjacency.md
│   ├── ai-comment.md
│   ├── ai-comment.md
│   ├── all-pages.txt
│   ├── blog-base-violations.txt
│   ├── bond-cleaning.md
│   ├── bond-mistakes-to-avoid.md
│   ├── brisbane-west.md
│   ├── build-failures.md
│   ├── build-list.md
│   ├── canonical-components.md
│   ├── checklist.md
│   ├── codemod-blog-base.txt
│   ├── contributing-data.md
│   ├── css-guardrails.md
│   ├── david-kenmore.md
│   ├── faq-issues-suggestions.md
│   ├── file-list.md
│   ├── geo-adjacency-TODO.md
│   ├── geo-coverage-correlation.md
│   ├── geo-linking.health.md
│   ├── geo-linking.promotions.md
│   ├── geo-phase3-plan.md
│   ├── geo-report.md
│   ├── geo-report.md
│   ├── geo-report.txt
│   ├── geo-tests.summary.md
│   ├── intent-anchors-report.txt
│   ├── internal-links-missing.txt
│   ├── ipswich.md
│   ├── ld-pages.txt
│   ├── ld-sources.txt
│   ├── linking-troubleshoot.md
│   ├── new-build-log.md
│   ├── output-summary-code.md
│   ├── redirects-check.txt
│   ├── redirects-validate.txt
│   ├── redirects.txt
│   ├── refactor-fix-report.txt
│   ├── refactor-scan.txt
│   ├── rewrite-intent-anchors.txt
│   ├── robots.txt
│   ├── sarah-springfield-lakes.md
│   ├── site-audit.txt
│   ├── spring-cleaning.md
│   ├── suburbs-overview.md
│   ├── summary.md
│   ├── troubleshoot.md
│   ├── ui-grep.txt
│   ├── unused-js.md
│   └── user-debrief.md
├── misc/
│   ├── .gitkeep
│   ├── ServiceLayout.astro.backup
│   ├── _headers
│   ├── _redirects
│   ├── _safelist.partial.html
│   ├── ai-copy-lint.sarif
│   ├── ai-critique.sarif
│   ├── blog__brisbane__category__checklist.html
│   ├── blog__brisbane__category__local.html
│   ├── blog__brisbane__category__story.html
│   ├── blog__brisbane__category__suburb.html
│   ├── blog__brisbane__category__usp.html
│   ├── blog__ipswich__category__checklist.html
│   ├── blog__ipswich__category__local.html
│   ├── blog__ipswich__category__story.html
│   ├── blog__ipswich__category__suburb.html
│   ├── blog__ipswich__category__usp.html
│   ├── blog__logan__category__checklist.html
│   ├── blog__logan__category__local.html
│   ├── blog__logan__category__story.html
│   ├── blog__logan__category__suburb.html
│   ├── blog__logan__category__usp.html
│   ├── build-faqs.mjs.backup
│   ├── build.log
│   ├── build.log
│   ├── contact.html
│   ├── dev.out
│   ├── faq.css
│   ├── gallery.html
│   ├── geoClusters.json.unused
│   ├── guard-dynamic.sh
│   ├── health.sh
│   ├── main.css
│   ├── main.css.backup
│   ├── output.css
│   ├── pre-commit
│   ├── pre-push
│   ├── prevent-alias-files.sh
│   ├── preview.url
│   ├── push.log
│   ├── quote.html
│   ├── terms.html
│   ├── ui.html
│   └── upgrade-astro.sh
├── public/
│   └── images/
│       ├── bath.jpg
│       ├── bath.jpg
│       ├── before.png
│       ├── before.webp
│       ├── brookwater-hero.webp
│       ├── browns-plains-hero.webp
│       ├── checklist.webp
│       ├── checklist.webp
│       ├── contactcard.png
│       ├── door.jpg
│       ├── door.jpg
│       ├── favicon-16x16.png
│       ├── favicon-16x16.png
│       ├── favicon-180x180.png
│       ├── favicon-180x180.png
│       ├── favicon-32x32.png
│       ├── favicon-32x32.png
│       ├── favicon.svg
│       ├── fblogo.jpeg
│       ├── fblogo.jpeg
│       ├── fblogo.webp
│       ├── fblogo.webp
│       ├── foam.png
│       ├── forest-lake-hero.webp
│       ├── herobg.png
│       ├── images.webp
│       ├── indooroopilly-hero.webp
│       ├── kenmore-hero.webp
│       ├── logo.svg
│       ├── logo.svg
│       ├── logo.svg
│       ├── mopbucket.png
│       ├── nans.png
│       ├── og.jpg
│       ├── og.jpg
│       ├── oven.jpg
│       ├── oven.jpg
│       ├── pandora.png
│       ├── redbank-plains-hero.webp
│       ├── shapes.svg
│       ├── shapes.svg
│       ├── shapes.svg
│       ├── springfield-lakes-hero.webp
│       ├── springwood-hero.webp
│       ├── tap.jpg
│       ├── tap.jpg
│       ├── usdown.webp
│       ├── usdown.webp
│       ├── ustop.webp
│       ├── ustop.webp
│       └── window.png
├── reports/
│   ├── .gitkeep
│   ├── adjacency.build.json
│   ├── ai-report.mjs
│   ├── audit-css-duplicates.json
│   ├── build-report.mjs
│   ├── build-summary.json
│   ├── cluster_fixer.output.json
│   ├── cluster_fixes.proposed.json
│   ├── content-audit-strict.json
│   ├── content-audit-summary.json
│   ├── content-audit.json
│   ├── content-dupes.json
│   ├── css-baseline.json
│   ├── css-current.json
│   ├── css-find.json
│   ├── css-usage-by-route.json
│   ├── debt-summary.mjs
│   ├── faqs-build.json
│   ├── full-summary.mjs
│   ├── generate-audit-reports.mjs
│   ├── generate-focused-summary.mjs
│   ├── generate-output-summary.mjs
│   ├── geo-coverage-correlation.json
│   ├── geo-doctor.json
│   ├── geo-gate.json
│   ├── geo-link-anchors.json
│   ├── geo-linking.promotions.delta.json
│   ├── geo-linking.promotions.json
│   ├── geo-linking.summary.fixture.json
│   ├── geo-linking.summary.json
│   ├── geo-metrics.diff.json
│   ├── geo-metrics.json
│   ├── geo-page-coverage.report.json
│   ├── geo-report.index.json
│   ├── geo-report.json
│   ├── geo-report.mjs
│   ├── geo-strategy-coverage.json
│   ├── geo-tests.summary.json
│   ├── geoPageContext.json
│   ├── geoReportMd.spec.ts
│   ├── internal-links-report.json
│   ├── investigate-css.json
│   ├── local-build-run-after-install.log
│   ├── local-build-run.log
│   ├── map-css-sources.json
│   ├── numbered-dupes.json
│   ├── pages.json
│   ├── pr-summary.mjs
│   ├── report-css-chunks.mjs
│   ├── report-index.mjs
│   ├── report-ld-sources.mjs
│   ├── report-ld.mjs
│   ├── report-linking-health.mjs
│   ├── report-md.mjs
│   ├── scripts-report-pages.mjs
│   ├── services_bathroom-clean__enrichment.json
│   ├── services_spring-cleaning__enrichment.json
│   ├── summary.json
│   ├── unused-js.json
│   └── upstream-issues-summary.json
├── schemas/
│   ├── adj.config.schema.json
│   ├── adjacency.build.schema.json
│   ├── areas.extended.clusters.schema.json
│   ├── baseline.json
│   ├── faq.compiled.schema.json
│   ├── geo.cluster.doctor.report.schema.json
│   ├── geo.linking.config.schema.json
│   ├── suburbs.meta.schema.json
│   └── suburbs.meta.schema.json
├── scripts/
│   ├── build/
│   │   ├── assert-no-alias-build.mjs
│   │   ├── build-faqs-new.mjs
│   │   ├── build-faqs.mjs
│   │   ├── build-unused-allowlist.mjs
│   │   ├── check-buildable.mjs
│   │   └── run-build-and-log.mjs
│   ├── geo/
│   │   ├── adjacency-symmetry.mjs
│   │   ├── assert-sitemap-blog-canonicals.mjs
│   │   ├── audit-geo-data.mjs
│   │   ├── build-adjacency.mjs
│   │   ├── build-cross-service-map.mjs
│   │   ├── cluster-alias-migrate.mjs
│   │   ├── cluster_doctor.mjs
│   │   ├── cluster_fixer.mjs
│   │   ├── faqmap.js
│   │   ├── find-geo-usages.mjs
│   │   ├── fix-adjacency.mjs
│   │   ├── generate_cluster_doctor.mjs
│   │   ├── geoCompat.runtime.js
│   │   ├── geoHandler-clean.js
│   │   ├── geoHandler.js
│   │   ├── getSuburbFaq.js
│   │   ├── lint-geo-neighbors.mjs
│   │   ├── map-css-sources.mjs
│   │   ├── reconcile-clusters.mjs
│   │   ├── relatedSuburbs.js
│   │   ├── suburbFacts.js
│   │   ├── validate-adjacency.mjs
│   │   ├── validate-cluster-membership.mjs
│   │   └── validate-suburb-pages.js
│   ├── seo/
│   │   ├── audit-cross-links.mjs
│   │   ├── audit-internal-links.mjs
│   │   ├── audit-related-links.mjs
│   │   ├── audit-related-links.mjs
│   │   ├── check-internal-links.mjs
│   │   ├── check-internal-links.mjs
│   │   ├── extract-internal-links.mjs
│   │   ├── internalLinks.js
│   │   ├── internalLinks.js
│   │   ├── linking_gate.mjs
│   │   ├── seoSchema.js
│   │   └── validate-footer-links.js
│   ├── .stylelintrc.cjs
│   ├── add-allowlist.mjs
│   ├── add_package_scripts.mjs
│   ├── ai-copy-lint.mjs
│   ├── ai-critique.mjs
│   ├── ai-enrichment-critic.js
│   ├── ai-intent-lint.js
│   ├── analyze-performance (2).mjs
│   ├── assert-ld-health.mjs
│   ├── assert-no-legacy-folders.mjs
│   ├── assert-no-ssr-synonym-pages.mjs
│   ├── assert-site-config.mjs
│   ├── audit-content.mjs
│   ├── audit-css-budgets.mjs
│   ├── audit-css-duplicates.mjs
│   ├── audit-graph.mjs
│   ├── audit-numbered-dupes.mjs
│   ├── audit-output-css.mjs
│   ├── audit-routes.mjs
│   ├── baseline-css.mjs
│   ├── bootstrap_page_context.mjs
│   ├── bridge.mjs
│   ├── check-compiled-faqs.mjs
│   ├── check-css-baseline-hash-tolerant.mjs
│   ├── check-css-baseline-original.mjs
│   ├── check-css-baseline.mjs
│   ├── check-env.js
│   ├── check-live.mjs
│   ├── churn.mjs
│   ├── clean-legacy-css.js
│   ├── cleanup-numbered-dupes.mjs
│   ├── cleanup-strays.mjs
│   ├── codemod-blog-base.mjs
│   ├── codemod-blog-base.spec.mjs
│   ├── config.mjs
│   ├── consolidate-ld.mjs
│   ├── crawl-audit.mjs
│   ├── css-assert-one-global.mjs
│   ├── css-baseline-enhanced.mjs
│   ├── css-baseline.mjs
│   ├── css-cleanup.mjs
│   ├── css-find.mjs
│   ├── css-guardrails.mjs
│   ├── css-list.mjs
│   ├── css-usage-by-route.mjs
│   ├── cypress.config.js
│   ├── debt-clean.mjs
│   ├── derive-meta-tiers.mjs
│   ├── derive-meta-tiers.mjs
│   ├── detect-global-imports.mjs
│   ├── dev-port.mjs
│   ├── diff-coverage-whitelist.mjs
│   ├── diff-cross-service.mjs
│   ├── diff.mjs
│   ├── discover-pages.mjs
│   ├── doctor.mjs
│   ├── expand-coverage.mjs
│   ├── expand-coverage.mjs
│   ├── extract-essential-css.mjs
│   ├── extract-ld-hashes.mjs
│   ├── faq-schema.mjs
│   ├── faq-section.cypress.js
│   ├── faqOverrides.js
│   ├── faqTemplates.js
│   ├── faqToJsonLd.js
│   ├── find-anchors.mjs
│   ├── find-legacy.mjs
│   ├── find-orphaned-css.mjs
│   ├── fix-legacy-service-shape.mjs
│   ├── gate.mjs
│   ├── gen-toc.mjs
│   ├── generate-knowledge-base.mjs
│   ├── generate-promotions.mjs
│   ├── generate-synonym-redirects.mjs
│   ├── graph-sanity.mjs
│   ├── guard-canonical-components.mjs
│   ├── guard-css.js
│   ├── guard-deno.js
│   ├── guard-dynamic.mjs
│   ├── guards.mjs
│   ├── hash-verify.mjs
│   ├── helpers.mjs
│   ├── history-archive.mjs
│   ├── ingest-import.mjs
│   ├── inspect.mjs
│   ├── intent-anchors-verify.mjs
│   ├── investigate-css.mjs
│   ├── lighthouserc.js
│   ├── math.js
│   ├── metrics.mjs
│   ├── overlay-merge.mjs
│   ├── page-context.mjs
│   ├── performance-guardian.mjs
│   ├── predev.mjs
│   ├── preview.mjs
│   ├── prioritiseByGrid.js
│   ├── prioritiseByGrid.js
│   ├── quarantine-files.mjs
│   ├── quote-form.cypress.js
│   ├── quote-form.cypress.js
│   ├── redirect-canary.mjs
│   ├── redirects-sample.mjs
│   ├── refactor-fix.mjs
│   ├── refactor-scan.mjs
│   ├── refactor-whatif.mjs
│   ├── rename-rehearse.mjs
│   ├── reviews.js
│   ├── rewrite-intent-anchors.mjs
│   ├── routes-util.mjs
│   ├── run-css-baseline.mjs
│   ├── run-css-one-global.mjs
│   ├── sarif.js
│   ├── scan-unused-js.mjs
│   ├── schema-baseline.mjs
│   ├── schema-diff.mjs
│   ├── schema.js
│   ├── schemaGraph.js
│   ├── schemamanager.js
│   ├── script.js
│   ├── serve-with-redirects.mjs
│   ├── setup-team-awareness.mjs
│   ├── slugify.js
│   ├── slugify.js
│   ├── spacing.mjs
│   ├── strategy-coverage.mjs
│   ├── ui-grep.mjs
│   ├── validate-data.js
│   ├── validate-faqs.js
│   ├── validate-footer.js
│   ├── validate-redirects.mjs
│   ├── validate-schema.js
│   ├── validate-schemas.mjs
│   ├── validate-slugs.mjs
│   ├── verify-blog-base-extended.mjs
│   ├── verify-blog-base.mjs
│   ├── verify-faqs.mjs
│   ├── verify-jsonld-new.mjs
│   ├── verify-jsonld.mjs
│   ├── verify-no-tabs.mjs
│   ├── verify-redirects-block.mjs
│   └── where.mjs
├── src/
│   ├── components/
│   │   ├── AboutSection.astro
│   │   ├── AcceptanceSlice.astro
│   │   ├── AvailabilityWidget.astro
│   │   ├── Badge.astro
│   │   ├── Button.astro
│   │   ├── Card.astro
│   │   ├── ContactCardWide.astro
│   │   ├── ContactSection.astro
│   │   ├── CrossServiceLinks.astro
│   │   ├── DifferenceSection.astro
│   │   ├── EnhancedQuoteForm.astro
│   │   ├── FAQ.astro
│   │   ├── FaqBlock.astro
│   │   ├── FaqSection.astro
│   │   ├── FeatureCardGrid.astro
│   │   ├── FloatingButton.astro
│   │   ├── Footer.astro
│   │   ├── GallerySection.astro
│   │   ├── Header.astro
│   │   ├── HeroSection.astro
│   │   ├── Lightbox.astro
│   │   ├── MidStrokeDivider.astro
│   │   ├── Polaroid.astro
│   │   ├── Polaroid.astro
│   │   ├── QuoteCTA.astro
│   │   ├── QuoteForm.astro
│   │   ├── RelatedGrid.astro
│   │   ├── RelatedLinks.astro
│   │   ├── ReviewSection.astro
│   │   ├── Schema.astro
│   │   ├── SchemaGraph.astro
│   │   ├── Section.astro
│   │   ├── ServiceNav.astro
│   │   ├── SparkleWipeDivider.astro
│   │   ├── SuburbFaq.astro
│   │   ├── WaveBackground.astro
│   │   ├── WaveDivider.astro
│   │   └── index.ts
│   ├── gen/
│   │   └── geoPageContext.ts
│   ├── layouts/
│   │   ├── MainLayout.astro
│   │   └── ServiceLayout.astro
│   ├── lib/
│   │   ├── buildable.ts
│   │   ├── clusters.ts
│   │   ├── coverage.ts
│   │   ├── crossService.ts
│   │   ├── data.ts
│   │   ├── faq-adapters.ts
│   │   ├── faq-types.ts
│   │   ├── geoCompat.runtime.ts
│   │   ├── index.ts
│   │   ├── index.ts
│   │   ├── knownSuburbs.ts
│   │   ├── nearby.ts
│   │   ├── paths.ts
│   │   ├── resolveDisplay.ts
│   │   ├── sanitize.ts
│   │   ├── schemas.ts
│   │   ├── seoSchema.d.ts
│   │   ├── serviceMeta.ts
│   │   ├── serviceNav.adapter.sync.ts
│   │   ├── serviceNav.adapter.ts
│   │   ├── slug.ts
│   │   ├── str.ts
│   │   └── url.ts
│   ├── pages/
│   │   ├── [category].astro
│   │   ├── [slug].astro
│   │   ├── [suburb].astro
│   │   ├── checklist.astro
│   │   ├── checklist.notusing.astro
│   │   ├── contact.astro
│   │   ├── gallery.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── index.astro
│   │   ├── privacy.astro
│   │   ├── quote.astro
│   │   ├── sitemap.xml.ts
│   │   ├── terms.astro
│   │   └── ui.astro
│   ├── utils/
│   │   ├── areaIndex.ts
│   │   ├── chooseSuburbForPost.sync.ts
│   │   ├── chooseSuburbForPost.ts
│   │   ├── clusterMap.ts
│   │   ├── coverageToMap.ts
│   │   ├── emitAnalytics.ts
│   │   ├── faqToJsonLd.ts
│   │   ├── geoCompat.d.ts
│   │   ├── geoCompat.ts
│   │   ├── geoHandler.ts
│   │   ├── index.ts
│   │   ├── internalLinks.ts
│   │   ├── internalLinksAdapter.ts
│   │   ├── nearbyCovered.single.ts
│   │   ├── nearbyCovered.ts
│   │   ├── normalizeClusters.ts
│   │   ├── origin.ts
│   │   ├── repSuburb.sync.ts
│   │   ├── repSuburb.ts
│   │   ├── slug.ts
│   │   └── slugify.ts
│   ├── RelatedLinks.astro
│   ├── adjacency-quality.ts
│   ├── adjacency-symmetry.ts
│   ├── aliases.ts
│   ├── astro-components.d.ts
│   ├── check-buildable.ts
│   ├── config.ts
│   ├── coverage-stats.ts
│   ├── css-baseline-enhanced.ts
│   ├── css-diff.ts
│   ├── diff-cross-service.ts
│   ├── env.d.ts
│   ├── env.d.ts
│   ├── faq-api.ts
│   ├── faq-personalize.ts
│   ├── fix-adjacency.ts
│   ├── global.d.ts
│   ├── graph-sanity.ts
│   ├── guard-dynamic.ts
│   ├── hello.ts
│   ├── index.ts
│   ├── middleware.ts
│   ├── optional-json.d.ts
│   ├── playwright.config.ts
│   ├── quote-handler.ts
│   ├── siteConfig.ts
│   ├── smoke-crawl.ts
│   └── validate-data.zod.ts
├── tests/
│   ├── --chromium-linux.png
│   ├── -areas-brisbane--chromium-linux.png
│   ├── -areas-desktop-chromium-linux.png
│   ├── -areas-ipswich--chromium-linux.png
│   ├── -areas-mobile-chromium-linux.png
│   ├── -blog-desktop-chromium-linux.png
│   ├── -blog-ipswich-bond-cleaning-checklist--chromium-linux.png
│   ├── -blog-mobile-chromium-linux.png
│   ├── -desktop-chromium-linux.png
│   ├── -mobile-chromium-linux.png
│   ├── -services-bond-cleaning-desktop-chromium-linux.png
│   ├── -services-bond-cleaning-ipswich--chromium-linux.png
│   ├── -services-bond-cleaning-mobile-chromium-linux.png
│   ├── -services-spring-cleaning-indooroopilly--chromium-linux.png
│   ├── a11y.spec.ts
│   ├── a11y.spec.ts
│   ├── acceptance-slice.spec.ts
│   ├── adjacency.asym.fixture.json
│   ├── adjacency.fixture.json
│   ├── aliases.spec.ts
│   ├── areaIndex.spec.ts
│   ├── areas-brisbane-anstead-desktop-chromium-linux.png
│   ├── areas-brisbane-anstead-mobile-chromium-linux.png
│   ├── areas-brisbane-ashgrove-desktop-chromium-linux.png
│   ├── areas-brisbane-ashgrove-mobile-chromium-linux.png
│   ├── areas-brisbane-auchenflower-desktop-chromium-linux.png
│   ├── areas-brisbane-auchenflower-mobile-chromium-linux.png
│   ├── areas-brisbane-bardon-desktop-chromium-linux.png
│   ├── areas-brisbane-bardon-mobile-chromium-linux.png
│   ├── areas-brisbane-bellbowrie-desktop-chromium-linux.png
│   ├── areas-brisbane-bellbowrie-mobile-chromium-linux.png
│   ├── areas-brisbane-brookfield-desktop-chromium-linux.png
│   ├── areas-brisbane-brookfield-mobile-chromium-linux.png
│   ├── areas-brisbane-chapel-hill-desktop-chromium-linux.png
│   ├── areas-brisbane-chapel-hill-mobile-chromium-linux.png
│   ├── areas-brisbane-chelmer-desktop-chromium-linux.png
│   ├── areas-brisbane-chelmer-mobile-chromium-linux.png
│   ├── areas-brisbane-darra-desktop-chromium-linux.png
│   ├── areas-brisbane-darra-mobile-chromium-linux.png
│   ├── areas-brisbane-desktop-chromium-linux.png
│   ├── areas-brisbane-doolandella-desktop-chromium-linux.png
│   ├── areas-brisbane-doolandella-mobile-chromium-linux.png
│   ├── areas-brisbane-durack-desktop-chromium-linux.png
│   ├── areas-brisbane-durack-mobile-chromium-linux.png
│   ├── areas-brisbane-ellen-grove-desktop-chromium-linux.png
│   ├── areas-brisbane-ellen-grove-mobile-chromium-linux.png
│   ├── areas-brisbane-fig-tree-pocket-desktop-chromium-linux.png
│   ├── areas-brisbane-fig-tree-pocket-mobile-chromium-linux.png
│   ├── areas-brisbane-forest-lake-desktop-chromium-linux.png
│   ├── areas-brisbane-forest-lake-mobile-chromium-linux.png
│   ├── areas-brisbane-graceville-desktop-chromium-linux.png
│   ├── areas-brisbane-graceville-mobile-chromium-linux.png
│   ├── areas-brisbane-inala-desktop-chromium-linux.png
│   ├── areas-brisbane-inala-mobile-chromium-linux.png
│   ├── areas-brisbane-indooroopilly-desktop-chromium-linux.png
│   ├── areas-brisbane-indooroopilly-mobile-chromium-linux.png
│   ├── areas-brisbane-jamboree-heights-desktop-chromium-linux.png
│   ├── areas-brisbane-jamboree-heights-mobile-chromium-linux.png
│   ├── areas-brisbane-jindalee-desktop-chromium-linux.png
│   ├── areas-brisbane-jindalee-mobile-chromium-linux.png
│   ├── areas-brisbane-karana-downs-desktop-chromium-linux.png
│   ├── areas-brisbane-karana-downs-mobile-chromium-linux.png
│   ├── areas-brisbane-kenmore-desktop-chromium-linux.png
│   ├── areas-brisbane-kenmore-hills-desktop-chromium-linux.png
│   ├── areas-brisbane-kenmore-hills-mobile-chromium-linux.png
│   ├── areas-brisbane-kenmore-mobile-chromium-linux.png
│   ├── areas-brisbane-kholo-desktop-chromium-linux.png
│   ├── areas-brisbane-kholo-mobile-chromium-linux.png
│   ├── areas-brisbane-lake-manchester-desktop-chromium-linux.png
│   ├── areas-brisbane-lake-manchester-mobile-chromium-linux.png
│   ├── areas-brisbane-middle-park-desktop-chromium-linux.png
│   ├── areas-brisbane-middle-park-mobile-chromium-linux.png
│   ├── areas-brisbane-milton-desktop-chromium-linux.png
│   ├── areas-brisbane-milton-mobile-chromium-linux.png
│   ├── areas-brisbane-mobile-chromium-linux.png
│   ├── areas-brisbane-moggill-desktop-chromium-linux.png
│   ├── areas-brisbane-moggill-mobile-chromium-linux.png
│   ├── areas-brisbane-mount-crosby-desktop-chromium-linux.png
│   ├── areas-brisbane-mount-crosby-mobile-chromium-linux.png
│   ├── areas-brisbane-mount-ommaney-desktop-chromium-linux.png
│   ├── areas-brisbane-mount-ommaney-mobile-chromium-linux.png
│   ├── areas-brisbane-oxley-desktop-chromium-linux.png
│   ├── areas-brisbane-oxley-mobile-chromium-linux.png
│   ├── areas-brisbane-paddington-desktop-chromium-linux.png
│   ├── areas-brisbane-paddington-mobile-chromium-linux.png
│   ├── areas-brisbane-pinjarra-hills-desktop-chromium-linux.png
│   ├── areas-brisbane-pinjarra-hills-mobile-chromium-linux.png
│   ├── areas-brisbane-pullenvale-desktop-chromium-linux.png
│   ├── areas-brisbane-pullenvale-mobile-chromium-linux.png
│   ├── areas-brisbane-red-hill-desktop-chromium-linux.png
│   ├── areas-brisbane-red-hill-mobile-chromium-linux.png
│   ├── areas-brisbane-richlands-desktop-chromium-linux.png
│   ├── areas-brisbane-richlands-mobile-chromium-linux.png
│   ├── areas-brisbane-riverhills-desktop-chromium-linux.png
│   ├── areas-brisbane-riverhills-mobile-chromium-linux.png
│   ├── areas-brisbane-seventeen-mile-rocks-desktop-chromium-linux.png
│   ├── areas-brisbane-seventeen-mile-rocks-mobile-chromium-linux.png
│   ├── areas-brisbane-sherwood-desktop-chromium-linux.png
│   ├── areas-brisbane-sherwood-mobile-chromium-linux.png
│   ├── areas-brisbane-sinnamon-park-desktop-chromium-linux.png
│   ├── areas-brisbane-sinnamon-park-mobile-chromium-linux.png
│   ├── areas-brisbane-st-lucia-desktop-chromium-linux.png
│   ├── areas-brisbane-st-lucia-mobile-chromium-linux.png
│   ├── areas-brisbane-sumner-desktop-chromium-linux.png
│   ├── areas-brisbane-sumner-mobile-chromium-linux.png
│   ├── areas-brisbane-taringa-desktop-chromium-linux.png
│   ├── areas-brisbane-taringa-mobile-chromium-linux.png
│   ├── areas-brisbane-the-gap-desktop-chromium-linux.png
│   ├── areas-brisbane-the-gap-mobile-chromium-linux.png
│   ├── areas-brisbane-toowong-desktop-chromium-linux.png
│   ├── areas-brisbane-toowong-mobile-chromium-linux.png
│   ├── areas-brisbane-upper-brookfield-desktop-chromium-linux.png
│   ├── areas-brisbane-upper-brookfield-mobile-chromium-linux.png
│   ├── areas-brisbane-upper-kedron-desktop-chromium-linux.png
│   ├── areas-brisbane-upper-kedron-mobile-chromium-linux.png
│   ├── areas-brisbane-wacol-desktop-chromium-linux.png
│   ├── areas-brisbane-wacol-mobile-chromium-linux.png
│   ├── areas-brisbane-westlake-desktop-chromium-linux.png
│   ├── areas-brisbane-westlake-mobile-chromium-linux.png
│   ├── areas-catalog.spec.ts
│   └── … (+449 more)
├── .editorconfig
├── .env.example
├── .eslintrc.cjs
├── .gitattributes
├── .gitignore
├── .nvmrc
├── README.md
├── astro.config.mjs
├── eslint.config.js
├── netlify.toml
├── package-lock.json
├── package.json
├── postcss.config.cjs
├── tailwind.config.js
└── tsconfig.json
```

### Next steps (optional)
- I can generate a **move plan** (old → new) as a shell script or CSV if you want to actually reorganize the repo in one pass.