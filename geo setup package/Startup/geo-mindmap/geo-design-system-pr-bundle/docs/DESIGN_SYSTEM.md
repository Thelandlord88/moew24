# Design System — Geo‑Dominance UI Engine

This is a **drop‑in component library** wired to your geo data (suburbs/services). It works with your SSG build and `areas.clusters.json`/`areas.adj.json` flow.

## Files
- `src/lib/designTokens.js` — color/typography/spacing tokens
- `src/lib/suburbThemes.js` — per‑suburb theme (hex + gradient classes)
- `src/lib/serviceThemes.js` — per‑service theme
- `src/lib/themeProvider.js` — runtime combiner + helpers
- `src/components/ui/Button.astro` — themable button (CSS variables + Tailwind)
- `src/components/ui/Card.astro` — service/suburb cards
- `src/components/ui/Banner.astro` — hero banner
- `src/components/layout/PageLayout.astro` — ready‑to‑use page shell
- `src/pages/services/[service]/[suburb]/index.astro` — example page using the layout

## How it styles without React
- Components are **Astro** files using Tailwind v4 classes.
- We set **CSS variables** (e.g. `--btn-bg`) inline, and use Tailwind **arbitrary values**: `bg-[var(--btn-bg)]`, `border-[var(--btn-border)]`.
- Gradients use standard Tailwind classes (e.g. `from-red-500`).

## Data assumptions
- `suburb.slug` and `suburb.name` exist (from your generators).
- `service` is a slug like `bond-cleaning`.
- `availableServices` is an array of service slugs.
- `adjacentSuburbs` is an array of `{ slug, name }` (you can map from `areas.adj.json`).

## Wire‑up
- Import the layout in your route and pass in the geo props you already generate.
- Add or change suburb/service themes by editing `suburbThemes.js` / `serviceThemes.js`.

## Extending
- Add more UI (Tabs, Badges, Accordions) in `src/components/ui/` and use `createTheme(suburb.slug, service)` to stay consistent.
