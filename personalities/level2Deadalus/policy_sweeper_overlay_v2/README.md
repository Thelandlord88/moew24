# Policy Sweeper + CLI SoftwareApplication Overlay

This overlay adds:
1) A **tiny policy-sweeper** that tries ± deltas on your link weights, ranks results by fairness/locality/cluster-purity, and writes a report.
2) A **SoftwareApplication** JSON-LD entry for the **CLI** on `/systems`, using fields from `daedalus.config.json` (`cli.name`, `cli.version`, `cli.downloadUrl`).

## Install
```bash
unzip policy_sweeper_overlay.zip -d .
```

## Use the sweeper
```bash
node scripts/daedalus/tools/policy-sweeper.mjs                 # default (small variants)
node scripts/daedalus/tools/policy-sweeper.mjs --variants=medium
node scripts/daedalus/tools/policy-sweeper.mjs --json          # print JSON to stdout
```

Outputs:
- `__reports/daedalus/policy.sweep.json` — full ranking and metrics
- `__reports/daedalus/policy.sweep.md` — top picks (table)

### Metrics
- **Gini (↓)** — inbound link distribution inequality; lower = fairer.
- **Avg km (↓)** — average suburb-neighbor distance for selected links (when coordinates exist).
- **Purity (↑)** — share of links within the same cluster.

## Configure the CLI metadata
Add to `daedalus.config.json` (optional but recommended):
```json
{
  "cli": {
    "name": "Daedalus CLI",
    "version": "1.2.3",
    "downloadUrl": "https://example.com/downloads/daedalus-cli-1.2.3.tgz",
    "softwareRequirements": "Node.js 18+"
  },
  "releaseNotes": "Optional: short human notes for the SoftwareApplication block"
}
```

## Suggestions
See `SUGGESTIONS.md` for Daedalus-style ideas and rationale.


## Hook into your CLI
Add these to your `package.json`:
```json
{
  "scripts": {
    "daedalus:sweep": "node scripts/daedalus/tools/policy-sweeper.mjs --variants=small",
    "daedalus:sweep:medium": "node scripts/daedalus/tools/policy-sweeper.mjs --variants=medium",
    "daedalus:sweep:svc": "node scripts/daedalus/tools/policy-sweeper.mjs --variants=small --service=bond-cleaning"
  }
}
```

### HTML report
The sweeper now also writes `__reports/daedalus/policy.sweep.html` — a compact, shareable table of the top variants.
