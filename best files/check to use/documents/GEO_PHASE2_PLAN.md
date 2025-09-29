# Geo Analytics – Phase 2 Plan (Seed)

Status: Phase 1 hardening merged (pending PR). Phase 2 will focus on visibility & governance.

## Objectives

1. Reviewer visibility: markdown reporter (`report-md.mjs`).
2. Connectivity decision support: optional bridge candidate generator (`bridge.mjs`).
3. Governance flexibility: introduce policy overrides file (`geo.policy.json`).
4. Observability: add timings (`meta.timings`) to metrics & doctor.
5. UI enablement: prepare Astro component scaffold reading artifacts.

## Deliverables

| Item | Description | Artifact |
|------|-------------|----------|
| Markdown PR Report | Badges + tables + top diff rows + rep churn | `__ai/geo-report.md` |
| Bridge Tool | Haversine-based candidate edges for smallest component | `__ai/geo-bridge-candidates.json` + overlay |
| Policy Overrides | Severity & per-cluster gates externalization | `geo.policy.json` |
| Timings | Runtime phase durations | `meta.timings` in metrics & doctor |
| Astro Scaffold | `/geo/*` pages (dashboard, diff, components, reps) | `src/pages/geo/` |

## Order of Implementation

1. Timings instrumentation (low risk, informs perf).
2. Markdown reporter (unblocks reviewer clarity).
3. Bridge tool (optional depending on component policy decision).
4. Policy override loader + integration into diff & doctor.
5. Astro page scaffolding + initial static SSR pages.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Reporter drift vs schema | Read through index object (defensive defaults). |
| Bridge tool misuse (artificial edges) | Only emit proposals; never auto-apply. |
| Policy override confusion with existing `geo.config.json` | Use distinct filename: `geo.policy.json`; doc the difference. |
| Timing noise on CI | Average over multiple runs (future) or display raw. |

## Definition of Done

* Reporter integrated, uploaded in CI.
* Optional bridge tool script documented & producing deterministic output.
* Policy overrides file recognized (severity changed in output when applied).
* Timings present in both metrics & doctor meta.
* Astro pages compile and render basic data (dashboard + diff + reps + components).

---
Prepared as a seed file to anchor the Phase 2 PR.
