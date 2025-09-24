# Daedalus — Level 2 (Design‑System Wiring)

This is an **overlay pack** that upgrades Level 1 to **Level 2**:
- Adds a minimal **design system** (ThemeProvider, PageLayout, Banner, Card, Accordion, Badge, NearbyGrid).
- Introduces **theme tokens** and a merge function that combines **service** + **suburb** themes.
- Rewrites the writer plugin to compose real components instead of raw HTML.
- Keeps JSON‑LD, internal link planning, and reports unchanged.

## How to apply

1) Unzip Level 2 into your repo root **after** Level 1:
```bash
unzip daedalus_level2.zip -d .
```

2) Ensure your project uses ESM (`"type": "module"`) and Tailwind is enabled.

3) Build pages again:
```bash
node scripts/daedalus/cli.mjs build
```

> If you have your own components already, swap these in-place—the writer emits standard Astro imports.

---
