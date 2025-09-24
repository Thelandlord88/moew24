# Hunter & Daedalus — Quickstart and Working Guide

Audience: Developers and agents collaborating with the Hunter (quality gates) and Daedalus (geo architect) systems.

## What they are

- Daedalus (lead): Architecture that tells the story of its own intelligence; builds geo systems, pages, data pipelines, and APIs deterministically.
- Hunter (follow-up): Failure-class elimination and evidence discipline; converts incidents into named gates and blocks regressions.

## Where their brains live (source of truth)

- Personalities (authoring):
  - `daedalus.personality.json`
  - `hunter.personality.json`
- Public profiles (served by API/UI):
  - `profiles/daedalus.json`
  - `profiles/hunter.json`
- Key briefs/docs:
  - `HUNTER_DAEDALUS_DIRECT_COMMUNICATION.md`
  - `HUNTER_ANALYSIS_FOR_DAEDALUS.md`
  - `personalities/level2Deadalus/DAEDALUS_HUNTER_FULL_BRIEFING.md`

## How to talk to them (CLI)

- Validate personalities: `npm run personalities:validate`
- Ask Daedalus for guidance: `npm run system:daedalus`
- Ask Hunter for guidance: `npm run system:hunter`

These commands read the authoring JSON personalities (not the public profiles) and print core principles, default actions, and constraints.

## How to talk to them (HTTP, when running the dev server)

- Human-readable system page: `/systems/` (renders both profiles)
- Machine endpoints:
  - `/api/systems/daedalus.json` → `profiles/daedalus.json`
  - `/api/systems/hunter.json` → `profiles/hunter.json`
  - `/api/systems/manifest.json` → `profiles/manifest.json`

Use these endpoints for automation, dashboards, and external tools.

## Division of responsibilities (at a glance)

- Daedalus
  - Deterministic generation (pages, JSON-LD, sitemaps)
  - Policies: internal links, SEO schema, robots, budgets
  - Reports: `__reports/daedalus/*`
- Hunter
  - Gates (build, perf, SEO, a11y, security)
  - Evidence-first: block when reports are missing or regressions occur
  - Converts issues → failure-classes → guards

## Communication protocol (keep it consistent)

- Assumptions → Evidence → Decision → Actions → Risks → Next checks
- Never hand-edit generated artifacts; change data, policies, or generators.
- If a failure appears once, name the class and add a gate.

## Immediate, practical workflows

- Page/geo work (Daedalus mindset)
  1) Update upstream data in `src/data/*` and policies in `daedalus.config.json`.
  2) Build with `npm run build` or dedicated geo scripts (see package.json).
  3) Verify `/systems/` and `/api/systems/*.json` reflect the intent.
  4) Review `__reports/daedalus/*` if present (metrics, issues, schema).

- Quality gates (Hunter mindset)
  1) Run checks and gather evidence (see “guard” and “inv:*” scripts in package.json).
  2) If a new failure emerges, document it as a failure-class and add a guard.
  3) Keep gates measurable and reversible; store outputs under `__reports/*`.

## Contracts (inputs/outputs)

- Inputs
  - Data: `src/data/areas.clusters.json`, adjacency, meta
  - Policies: `daedalus.config.json`, personality JSON
- Outputs
  - Pages: `/services/{service}/{suburb}/`
  - APIs: `/api/systems/*`, `/api/agents/*` (when implemented)
  - Reports: `__reports/daedalus/*`, `__reports/hunt/*`
- Error modes
  - Gate failures (block): schema invalid, page counts mismatch, budgets exceeded
  - Warnings (proceed): near-threshold metrics; follow up with evidence

## Useful scripts (from package.json)

- Development/build
  - `npm run dev` / `npm run build` / `npm run preview`
- Visibility and invariants
  - `npm run geo:doctor`, `npm run geo:guard`, `npm run geo:smoke`, `npm run inv:*`
- Personalities (intelligence tooling)
  - `npm run personalities:validate` (structure check)
  - `npm run system:daedalus` / `npm run system:hunter` (guidance)
  - `npm run personalities:v3` (evolution engine v3 — deeper analysis)

## Next recommended steps (fast wins)

- Add/confirm gates Hunter requested in the debrief:
  - Suburb/service coverage validation (page count parity with data)
  - Size budgets for HTML/CSS/JS with reports under `__reports/daedalus/`
  - Conversion elements presence checks (CTAs, trust UI) via invariant scripts
- Expose/verify machine endpoints during dev:
  - Visit `/systems/` and the `/api/systems/*.json` endpoints
- Keep Decision Records for any policy change (see the Full Briefing templates)

## Where to extend next

- Implement `/api/agents/*` (index, graph, clusters) from the Level 4 schema notes.
- Wire canary builds and size-budgets plugins per the Full Briefing.
- Build a static dashboard under `__reports/ui/` using the reports JSON.
