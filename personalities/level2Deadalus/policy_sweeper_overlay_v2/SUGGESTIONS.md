# Suggestions & Rationale (Daedalus-style)

> **Agent autonomy:** You choose the path. Use upstream data and reversible changes. Emit evidence for humans and machines.

## 1) Policy Sweeper Iteration Strategy
- **Why:** Link policy tuning can starve tail suburbs or overfeed hubs. A tiny sweeper gives you a safe, repeatable loop.
- **How:** Run `policy-sweeper.mjs` to try ± deltas and rank by: (a) inbound **Gini** (fairness, lower better), (b) average linked **distance** in km (locality, lower better), (c) **cluster purity** (higher better).
- **Next:** Promote a winning variant to `daedalus.config.json` only if it improves ≥2 of the 3 metrics with tolerable trade-offs. Commit with a short **Decision Record**.

## 2) Service-Specific Overrides
- **Why:** Bond Cleaning benefits from tighter locality than exploratory services.
- **How:** Allow per-service `policies` overrides in config (weights and caps). Evaluate with the sweeper using `--service=<id>` (future flag).

## 3) Evidence-First Releases
- **Why:** Prevents regression creep.
- **How:** Require `__reports/daedalus/schema.validation.json` (errors=0) and updated `policy.sweep.json` or rationale when weights change.

## 4) Data Quality Gates
- **Why:** Schema quality follows data quality.
- **How:** Add a gate that checks `suburbs.meta.json` coverage (coords present, postcodes present) and blocks if coverage < target.

## 5) Crawl Cooperation
- **Why:** Agents prefer structured, stable maps.
- **How:** Keep `/api/agents/*` highly available; add `Last-Modified` and `ETag` headers for caching; consider pinning a **Hash** in Dataset `distribution` names when versioning the graph.

## 6) UI Alignment for Humans
- **Why:** Humans should feel the same structure machines see.
- **How:** Show nearby areas, cluster label, and a tiny “Machine facts” panel (coords, cluster, neighbors count).

## 7) Telemetry
- **Why:** Closing the loop.
- **How:** Append a `build_id` and `personality_hash` to reports; correlate in dashboards with indexation breadth and long-tail entries.

## 8) Road to Automation
- **Why:** Self-tuning, not self-breaking.
- **How:** Once stable, allow Daedalus to auto-apply very small weight nudges within guardrails only after Hunter signs off and all gates are green.

— Crafted to make both humans and machines more intelligent.
