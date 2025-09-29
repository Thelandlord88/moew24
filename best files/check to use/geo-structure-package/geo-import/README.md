# Reformatted Geo Data (runtime-ready)

This folder contains split, deterministic artefacts produced from `geo_derived.bundle.json`
for use with the geo runtime utilities (e.g. `geoCompat.runtime`).

## File Layout

```
reformatted_geo/
├── content/
│   └── areas.clusters.json          # clusters -> suburb slugs (derived from LGA groups)
└── data/
    ├── suburbs.coords.json          # slug -> {lat, lng}
    ├── suburbs.index.json           # slug -> {name, lga?, postcode_list?, abs_codes?, distance_to_bne_cbd_km?}
    ├── aliases.json                 # alias -> slug
    └── groups/
        └── lga.groups.json          # LGA name -> [slug]
```

## Schemas

### `content/areas.clusters.json`
```jsonc
{
  "version": 1,
  "clusters": [
    {
      "slug": "brisbane",
      "name": "Brisbane",
      "weight": 195,
      "suburbs": ["acacia-ridge", "albion", "..."]
    }
  ],
  "meta": {
    "generated_from": "geo_derived.bundle.json",
    "generated_at": "2025-09-14T06:29:23Z",
    "hash": "16d07578e3d3cb8b2d2fa64b9271e8a61cf820bceaa99b922c5852e5db343684"
  }
}
```

### `data/suburbs.coords.json`
- Keyed by **slug**.
- Values: `{ "lat": number, "lng": number }`.

### `data/suburbs.index.json`
- Keyed by **slug**.
- Values include: `name`, optional `lga`, optional `abs_codes`, optional `distance_to_bne_cbd_km`, etc.

### `data/aliases.json`
- Keyed by **lowercased alias** (e.g. variant spellings).
- Value is the canonical **slug**.

### `data/groups/lga.groups.json`
- Keyed by **LGA name**.
- Values are **sorted arrays** of slugs for determinism.

## Integration Notes

- The runtime wrapper expects:
  - `content/areas.clusters.json`
  - `data/suburbs.coords.json`
- Adjacency is **not** included in this bundle and should be provided separately as `data/adjacency.json` (slug -> [slug]).
  - If you need a temporary adjacency, you can generate one from `suburbs.coords.json` using a distance threshold; however, true boundary adjacency is preferred for production.

## Provenance

- Source bundle: `/mnt/data/geo_derived.bundle.json`
- Suburbs: 345  | Coords: 345
- LGAs: 3
