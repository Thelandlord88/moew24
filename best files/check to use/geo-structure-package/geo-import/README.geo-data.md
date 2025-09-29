# Geo Data (normalized)

This directory contains normalized geo datasets generated from `geo_derived.bundle.json`.

## Files

- **suburbs.coords.json** — `slug -> { lat, lng }` (WGS84).  
- **suburbs.index.json** — `slug -> { name, lga?, postcode_list?, abs_codes?, distance_to_bne_cbd_km? }`.  
- **suburbs.aliases.json** — `alias (lowercased/slugified) -> canonical slug`.  
- **lgas.groups.json** — `LGA -> [ slug ]` (sorted, unique).  
- **adjacency.json** — `slug -> [ neighboring slug ]`, sorted, self-loops removed.  
- **areas.clusters.json** — `{ clusters: [ { slug, name, suburbs:[slug] } ] }`; sourced from bundle clusters when present; otherwise derived from LGA groups.

## Normalization rules

- Slugs are diacritic-folded, lowercased, non-alnum collapsed to `-`, trimmed.  
- All lists are sorted and de-duplicated.  
- Missing or invalid coordinates are dropped from `suburbs.coords.json`.  
- `adjacency.json` accepts either array form or `{ adjacent_suburbs:[...] }` and removes self-loops.

## Provenance

- Source bundle: `geo_derived.bundle.json`
- Generated on: (runtime)
