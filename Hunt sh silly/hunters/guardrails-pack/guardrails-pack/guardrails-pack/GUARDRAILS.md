# Guardrails for Generated Artifacts

This pack prevents accidental edits to generated JSON and keeps them fresh.

## Files
- `scripts/generated.map.json` — declarative rules: outputs → inputs → command
- `scripts/run-generators.mjs` — runs all unique generators from the map
- `scripts/check-generated.mjs` — pre-commit/CI guard that reads the map
- `.github/workflows/generated-guard.yml` — PR gate to ensure outputs are up to date
- `CODEOWNERS` — optional protection for generated outputs

## Install (copy & wire)
1. Copy `scripts/` into your repo and commit.
2. Add to `package.json`:
   ```json
   {
     "scripts": {
       "gen:all": "node scripts/run-generators.mjs",
       "precommit:generated": "node scripts/check-generated.mjs"
     }
   }
   ```
3. Hook Husky pre-commit:
   ```bash
   # .husky/pre-commit
   node scripts/check-generated.mjs || exit 1
   ```
4. (Optional) Add `CODEOWNERS` and enable "Require review from Code Owners".
5. Push `.github/workflows/generated-guard.yml` to enforce in PRs.

## Customize
- Edit `scripts/generated.map.json` to add/remove rules. Each rule:
  ```json
  {
    "output": "path/to/generated.json",
    "inputs": ["path/to/source-or-dir", "scripts/your-gen.mjs"],
    "gen": "node scripts/your-gen.mjs --write"
  }
  ```
- Use a different map file via: `--map=path` on both scripts.

## Notes
- The guard blocks commits if an output is staged without its sources.
- It re-runs generators and fails if diffs appear (ensuring freshness).
- Use `--skip-gen` when you only want to enforce the staging rule.
