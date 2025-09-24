# Linking + Page Context Merge Helper

This helper merges:
- `astro_props_linking_pack.zip` (linking components & page-context script)
- `geo_page_ctx_bundle.zip` (deterministic page context + reports + bridges)

## Usage
Copy both zips into your repo root (same level as `package.json`) and run:
```bash
bash merge_linking_ctx.sh ./astro_props_linking_pack.zip ./geo_page_ctx_bundle.zip
```

Then run:
```bash
npm run geo:adj
npm run geo:pagectx   # or: npm run geo:ctx
```

Outputs to check:
- `src/gen/geoPageContext.ts`
- `__reports/geo-linking.summary.json`
- `__reports/geo-link-fairness.json`
- `__reports/geo-anchor-templates.json`

