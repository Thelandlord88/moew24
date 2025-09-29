# Geo Readiness Report (staged)

GeneratedAt: 2025-09-22T01:04:29.623Z

## Summary (Top by readiness)

```
slug           state   score  class    words  neighbors  images  coords?  titleOK  metaOK
----           -----   -----  -----    -----  ---------  ------  -------  -------  ------
ripley         staged  35.0   Blocked  16     3          0       true     false    false 
flinders-view  staged  35.0   Blocked  18     5          0       true     false    false 
```

## Findings & Questions

### ripley — Blocked (35.0)
- words: 16 | neighbors: 3 | images: 0 | coords: -27.671591,152.784112
- SEO: titleOK=false metaOK=false
- since (days): 4

- **contentWords**: ⚠️
  - ❌ **Critical** [CONTENT_TOO_SHORT] — Why is content only 16 words (< 600) for ripley?
    - suggestion: Add local intro, FAQs, checklist, trust block; reach min.
    - owner: content
    - artifact: src/content/suburbs/ripley.json
    - label: geo-copy
    - confidence: 0.9
- **coords**: OK
- **neighbors**: OK
  - ℹ️ **Info** [NEIGHBORS_MIN_EDGE] — Exactly minimum neighbors (3) for ripley. Improve relevance?
    - owner: data
    - artifact: src/data/adjacency.json
    - label: geo-data
    - confidence: 0.4
- **images**: ⚠️
  - ⚠️ **Warn** [IMAGES_MISSING] — No images for ripley.
    - suggestion: Add at least one unique hero or gallery image.
    - owner: media
    - artifact: src/content/suburbs/ripley.json
    - label: geo-media
    - confidence: 0.7
- **seo**: ⚠️
  - ⚠️ **Warn** [SEO_TITLE_LEN] — Title length outside 35–65 for ripley.
    - suggestion: Refine to service + suburb, people-first.
    - owner: seo
    - artifact: src/content/suburbs/ripley.json
    - label: geo-seo
    - confidence: 0.6
  - ⚠️ **Warn** [SEO_META_LEN] — Meta description outside 120–170 for ripley.
    - suggestion: Add compelling, helpful summary.
    - owner: seo
    - artifact: src/content/suburbs/ripley.json
    - label: geo-seo
    - confidence: 0.6
- **uniqueness**: OK
  - ℹ️ **Info** [UNIQUENESS_OK] — Uniqueness acceptable (TTR=0.875). Add landmark references?
    - owner: content
    - artifact: src/content/suburbs/ripley.json
    - label: geo-copy
    - confidence: 0.3

### flinders-view — Blocked (35.0)
- words: 18 | neighbors: 5 | images: 0 | coords: -27.651326,152.775374
- SEO: titleOK=false metaOK=false
- since (days): 4

- **contentWords**: ⚠️
  - ❌ **Critical** [CONTENT_TOO_SHORT] — Why is content only 18 words (< 600) for flinders-view?
    - suggestion: Add local intro, FAQs, checklist, trust block; reach min.
    - owner: content
    - artifact: src/content/suburbs/flinders-view.json
    - label: geo-copy
    - confidence: 0.9
- **coords**: OK
- **neighbors**: OK
- **images**: ⚠️
  - ⚠️ **Warn** [IMAGES_MISSING] — No images for flinders-view.
    - suggestion: Add at least one unique hero or gallery image.
    - owner: media
    - artifact: src/content/suburbs/flinders-view.json
    - label: geo-media
    - confidence: 0.7
- **seo**: ⚠️
  - ⚠️ **Warn** [SEO_TITLE_LEN] — Title length outside 35–65 for flinders-view.
    - suggestion: Refine to service + suburb, people-first.
    - owner: seo
    - artifact: src/content/suburbs/flinders-view.json
    - label: geo-seo
    - confidence: 0.6
  - ⚠️ **Warn** [SEO_META_LEN] — Meta description outside 120–170 for flinders-view.
    - suggestion: Add compelling, helpful summary.
    - owner: seo
    - artifact: src/content/suburbs/flinders-view.json
    - label: geo-seo
    - confidence: 0.6
- **uniqueness**: OK
  - ℹ️ **Info** [UNIQUENESS_OK] — Uniqueness acceptable (TTR=0.889). Add landmark references?
    - owner: content
    - artifact: src/content/suburbs/flinders-view.json
    - label: geo-copy
    - confidence: 0.3
