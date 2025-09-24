# Geo SoT Toolkit (Drop-in Pack)

This pack includes:
- `scripts/geo/*`: typed CLIs (`metrics`, `doctor`, `gate`) and `lib/*`
- `geo.linking.config.jsonc`: policy (fairness + graph health) with rationale
- `tsconfig.scripts.json`: isolates script typechecking/building
- `tests/geo/*`: snapshot & property tests
- `.github/workflows/geo.yml`: CI job that runs the toolchain and uploads reports

## Usage

Install deps: `pnpm add -D tsx zod vitest fast-check`

Add scripts to your `package.json`:
```json
{
  "scripts": {
    "typecheck:full": "tsc -p tsconfig.scripts.json --noEmit && tsc -p tsconfig.json --noEmit",
    "geo:metrics": "tsx scripts/geo/metrics.ts",
    "geo:doctor": "tsx scripts/geo/doctor.ts",
    "geo:gate":   "tsx scripts/geo/gate.ts",
    "geo:all":    "pnpm run geo:metrics -- --json --out __reports/geo-metrics.json && pnpm run geo:doctor -- --json --out __reports/geo-doctor.json && pnpm run geo:gate -- --strict"
  }
}
```

Expected runtime providers (your app):
- `src/lib/geoCompat.runtime.js` (preferred) or
- `src/lib/geoCompat.js`
They must export async functions: `clusters()` and `adjacency()`.

## Commands
- `pnpm run geo:metrics -- --json` → writes `__reports/geo-metrics.json`
- `pnpm run geo:doctor  -- --json` → writes `__reports/geo-doctor.json`
- `pnpm run geo:gate -- --strict`   → fails CI if policy bounds are violated
