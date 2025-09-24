# Hunter Pack: Learning + Thinking Orchestrator

A modular, dependency-light system that:
- runs specialized **hunters** (SSR/SSG, build deps, security, a11y, perf, code quality),
- emits strict **JSON** reports and human logs,
- merges a **master** report with pass/fail policy,
- runs a **Hunter Thinker** that reads everything and writes a single, ranked **Do-Next** agenda (Fix → Proof → Sibling Sweep) with “hot files”,
- keeps all **strict gates** in the hunters (secrets, SSR failures, etc.), so the Thinker is advisory, not escapist.

## Quickstart

```bash
# run the full hunt in strict mode (fails CI on criticals)
npm run hunt:strict

# dev-time, warn-only
npm run hunt:warn

# run Thinker manually (advisory agenda)
npm run thinker
```

Artifacts:
- Machine: `__reports/hunt/*.json` (per-module), `__reports/hunt/master.json`
- Human: `__reports/hunt/logs/*.log`
- Advisory: `__ai/thinker/master-insights.json`
- Telemetry: `var/hunt-events.ndjson`

## Modules

- `runtime_ssr` — SSR/SSG drift (import assertions, dynamic JSON imports, adapter/config mismatch).
- `build_dependencies` — generator→output registry, generated-in-src, DO-NOT-EDIT violations & conflict risk.
- `security` — secrets, dangerous dynamic code, XSS sinks, mixed content, .env exposure.
- `accessibility` — alt/labels/landmarks/headings/clickable-div heuristics.
- `performance` — large images/modules, barrel exports, CSS sprawl.
- `code_quality` — TODO/FIXME, long lines, magic numbers, duplication hints.

All modules output the same JSON shape (status/issues/affected_files/counts/actions/policy_invariants/eta_minutes/unlocks) so the Thinker can score fairly.

## Policy & Strict Mode

- The orchestrator **fails** in `STRICT=1` when **any module** reports `status: "critical"`.
- Each module defines **policy_invariants** that should be true after a fix (e.g., `counts.dynamicJsonImports == 0`). These are advisory in the JSON and **enforced** by the module itself when possible.
- The **Thinker** never changes exit codes. It reads JSON, ranks actions by: **severity + recurrence + blast radius − time-to-fix + unlocks**, and emits a single agenda with “why now”.

Tune the Thinker via `__ai/thinker/thinker-policy.json`.

## CI Example (GitHub Actions)

```yaml
- name: Hunter (strict)
  run: npm run hunt:strict

- name: Upload hunter artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: hunter-artifacts
    path: |
      __reports/hunt/**
      __ai/thinker/master-insights.json
```

## Determinism

- Set `FAKE_NOW=…` to pin timestamps for reproducible builds.
- The hunters avoid wall-clock and network IO. The Thinker uses only local files.

## Extending with New Hunters

1. Create `hunters/<name>.sh`, write to `__reports/hunt/<name>.json` using the standard contract.
2. Add `<name>` to `MODULES` env or pass `MODULES` when running.
3. Optional: source `hunters/trace.sh` and emit `trace_issue`/`trace_open_file` for richer “hot files”.

## Example Agenda (from Thinker)

```json
{
  "agenda": [
    {
      "module": "build_dependencies",
      "status": "critical",
      "score": 7.1,
      "actions": [
        "Move writers to scripts/ and output to __generated/",
        "Stop editing compiled outputs; edit .source.* or generator input"
      ],
      "proof": ["counts.potential_conflicts == 0"],
      "why": "severity:2 recurrence:3 blast:5 unlocks:2"
    },
    {
      "module": "runtime_ssr",
      "status": "critical",
      "score": 6.5,
      "actions": [
        "Remove JSON import assertions and dynamic JSON import() in src/**",
        "Adopt adapter + output:'server' if SSR intentional"
      ],
      "proof": ["counts.dynamicJsonImports == 0","truthPin == 'ok'"],
      "why": "severity:2 recurrence:2 blast:7 unlocks:2"
    }
  ]
}
```

## Safety & Governance

- Hard reds (secrets, env files in repo, SSR misconfig) **fail** strict hunts.
- The Thinker is transparent: all inputs (module JSON) + outputs (agenda) are versioned alongside the code.
- No network calls. No private exfiltration. Everything stays local.

## Troubleshooting

- **JSON parsing error**: check `__reports/hunt/logs/<module>.log` for stack traces; the orchestrator writes a stub JSON if a module crashes so the run can continue.
- **Missing Node**: the Thinker step is skipped; core hunts still run.
- **Performance**: on large repos, consider a `.huntrc` ignore file (use `rg --ignore-file`) or set `MODULES` to a subset for pre-commit.
