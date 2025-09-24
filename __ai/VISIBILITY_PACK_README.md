# Transparent Visibility Pack — Operator Guide

## Commands
- `npm run geo:doctor`     → Validates geo data & writes service×suburb smoke paths
- `npm run vis:prebuild`   → Prebuild gates (reserved)
- `npm run build`          → Astro build
- `npm run vis:postbuild`  → DOM gates (happy-dom)
- `npm run seo:snapshot`   → Writes __ai/seo-snapshot.json
- `npm run vis:ci`         → doctor → strict prebuild → build → strict postbuild → snapshot
- `npm run test:ux` / `npm run test:seo` → Playwright smokes
- `npm run ethics:syndication` → Generate transparent syndication briefs (no auto-posting)
- `npm run ethics:404-reclaim` → Internal 404 report for cleanup/outreach
- `npm run panic` → Disable optional add-ons, harden gates; commit & redeploy

## Tune (single dial) — __ai/visibility-flags.json
- `site` — production canonical base
- `anchors.*` — commercial phrases & per-page repetition cap
- `nearby.*` — UI↔JSON-LD lockstep + max nearby items (data-invariant="nearby")
- `schema.*` — AggregateRating source, Offer currency, FAQ/Breadcrumb honesty
- `ethics.*` — ban UA-conditional DOM & hidden stuffing (SR-only allowed)
- `localContent.*` — min words & local hint count on service×suburb pages
- `similarity.*` — duplicate guard on service×suburb pages
- `sitemap.*` — dist presence, canonical self, internal linking
- `geo.*` — required files & smoke density
- `syndication.*` — briefs output & disclosure text
