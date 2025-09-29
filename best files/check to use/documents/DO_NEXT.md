# Hunter Thinker — Do‑Next Agenda

## 1. data_contracts  —  CRITICAL  (score 18.19)

**Evidence**
```json
{
  "issues": 75,
  "counts": {
    "schemasFailed": 75
  },
  "eta": 20,
  "unlocks": [
    "runtime_ssr",
    "build_dependencies"
  ]
}
```
**Actions**
- Add key 'serviceId' to src/data/suburbs.aliases.json
- Add key 'slug' to src/data/suburbs.aliases.json
- Add key 'serviceId' to src/data/suburbs.coords.json
- Add key 'slug' to src/data/suburbs.coords.json
- Add key 'serviceId' to src/data/services.json
- Add key 'serviceId' to src/data/geo.neighbors.brisbane-west.json
**Proof invariants**
- `counts.schemasFailed==0`

## 2. content_integrity  —  WARN  (score 11.85)

**Evidence**
```json
{
  "issues": 17,
  "counts": {
    "brokenAnchors": 17
  },
  "eta": 15,
  "unlocks": [
    "a11y",
    "seo"
  ]
}
```
**Actions**
- Fix or add missing anchors for referenced anchor links.
**Proof invariants**
- `counts.brokenAnchors==0`
