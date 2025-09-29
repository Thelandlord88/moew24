# Hunter Thinker 2.0 — Learning + Policy for Modular Hunters

A thin “brain” that reads *all* hunter reports and trace events, learns what repeatedly flips **critical → pass**, and outputs a ranked **Do‑Next** plan with proof‑invariants. Ships with new detectors for **Geo Fitness**, **Data Contracts**, **Content Integrity**, **Perf Budgets**, and a **Determinism** harness. Integrates with your existing hunters (runtime_ssr, build_dependencies, performance, accessibility, security, code_quality).

---

## Goals

- **Breadth with one verdict** — More domains guarded (geo/data/links/perf/a11y/security/determinism), but still a single CI pass/fail via `policy.mjs`.
- **Evidence, not vibes** — Every agenda item includes actions+proof invariants and points to the exact counts.
- **Light learning** — Tiny memory biases toward plays that have historically fixed real failures.

---

## Install (one‑shot)

```bash
bash install-hunter-thinker-2.0.sh --force --site=https://your-domain.com
# Optional if you already use Playwright
npx playwright install

# Full run
npm run hunt:ci
# Or: run existing hunt, then:
npm run hunt:thinker && npm run hunt:policy:strict
```

Artifacts:
- `__ai/thinker/master-insights.json` — structured agenda + hot files
- `__ai/thinker/DO_NEXT.md` — human‑friendly next actions
- `__ai/thinker/verdict.json` — strict/warn invariant evaluation
- `__ai/thinker/memory.json` — tiny memory of successful plays
- `var/hunt-events.ndjson` — trace events (opt‑in from hunters)

---

## New detectors (beyond SSR)

### 1) Geo Fitness (`hunters/geo_fitness.sh`)
- **Blocks:** dynamic JSON imports, `assert {type:'json'}` — enforces the static import + alias pattern.
- **Why:** runtime patterns cascade into SSR failures and perf hits.
- **Invariant:** `counts.importAssertions==0 && counts.dynamicJsonImports==0`.

### 2) Data Contracts (`hunters/data_contracts.sh`)
- **Checks:** required keys in `src/data/**/*.json` and `src/content/**/*.json` (fast regex).
- **Why:** upstream safety; UI and generators can assume shape.
- **Invariant:** `counts.schemasFailed==0`.

### 3) Content Integrity (`hunters/content_integrity.sh`)
- **Checks:** broken `(#anchor)` links without matching `{#anchor}` headings.
- **Why:** crawlability + UX; cheap wins across MD/MDX/Astro.
- **Invariant:** `counts.brokenAnchors==0` (warn by default).

### 4) Perf Budgets (`hunters/perf_budget.sh`)
- **Checks:** total JS KB in `dist/assets`, number of images > budget KB.
- **Why:** keeps bundle honest pre‑Lighthouse.
- **Policy:** warn; add caps to `policy.json` if you want strict.

### 5) Determinism (`hunters/determinism.sh`)
- **What:** run hunters twice with `FAKE_NOW`, diff report JSON.
- **Why:** stable evidence → reproducible builds.
- **Invariant:** `determinism.diff == ""` (strict).

> Your existing hunters continue to run unchanged. These sit next to them and write `__reports/hunt/*.json` too.

---

## Thinker (how scoring works)

Scoring per module =  
`3.0*severity + 1.6*log(1+issues) + 1.4*log(1+affected_files) - 0.8*log(1+eta_minutes) + 1.2*unlocks`

- **severity:** critical=2, warn=1, pass=0  
- **recurrence:** more issues → higher priority  
- **blast:** more files touched → higher priority  
- **timeToFix:** shorter → higher priority  
- **unlocks:** fixes that clear other modules get a boost  

Threshold to recommend: `CFG.thresholds.recommend` (default 2.0). Max items: `CFG.thresholds.maxAgenda` (default 12).

**Learning:** When a module that was “critical” in the previous run is no longer critical and the surrounding commit touched its files, the Thinker increments `success_count` for that module in `memory.json`. Future agendas can multiply score by a tiny `(1 + success_count*ε)` if you want stronger learning (left as a policy choice).

---

## Policy (single verdict for CI)

`__ai/thinker/policy.json` defines strict and warn invariants across modules. Example strict failures:

- `runtime_ssr.truthPin != "violated"`
- `build_dependencies.counts.potential_conflicts == 0`
- `geo_fitness.counts.importAssertions == 0`

Run:

```bash
npm run hunt:policy:strict  # exit 1 on strict fail
```

Outputs: `__ai/thinker/verdict.json`

---

## Trace events (optional)

Include in hunters:

```bash
HUNTER_MODULE="runtime_ssr"
source hunters/trace.sh || true
trace_open_file "src/pages/index.astro"
trace_issue "no_adapter" "astro.config.mjs" "critical"
trace_invariant "SSR-adapter-required" "fail"
```

These power **Hot files** in the agenda, focusing reviews.

---

## Typical run in CI

```yaml
- name: Hunters (modular)
  run: npm run hunt:all

- name: Thinker
  run: npm run hunt:thinker

- name: Policy (strict)
  run: npm run hunt:policy:strict

- name: Upload evidence
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: hunter-bundle
    path: |
      __reports/hunt/**
      __ai/thinker/**
      var/hunt-events.ndjson
```

---

## Acceptance tests (what to try)

1) **Geo flip:** add `import x from './foo.json' assert { type:'json' }` in `src/utils` → `geo_fitness` goes **critical**, policy fails.  
2) **Contract miss:** remove `serviceId` in a `src/data/*.json` → `data_contracts.schemasFailed>0` (strict fail).  
3) **Determinism break:** add `Date.now()` to a hunter → `determinism.diff` non‑empty (strict fail).  
4) **Perf bust:** add a 1.2MB PNG to `dist/` → perf warn with largeImages count.  
5) **Anchors:** reference a `(#missing)` with no `{#missing}` heading → content_integrity warn with sample lines.

---

## Tuning

- `__ai/thinker/config.json` — scoring weights, thresholds, memory file, hotFilesTopN.
- `__ai/thinker/policy.json` — strict & warn invariants to enforce in CI.
- `hunters/perf_budget.sh` — `BUDGET_JS_KB`, `BUDGET_IMG_KB` env caps.
- Determinism — set `FAKE_NOW` env to your canonical build time for consistency.

---

## Notes

- Everything is plain Bash + Node (ESM). No extra npm deps are required beyond `jq` and `ripgrep` (`rg`) which your hunters already use.
- The Thinker never mutates repo files. It only reads reports and emits guidance + a single verdict.
