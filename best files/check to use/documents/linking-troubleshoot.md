# Linking Troubleshoot & Hardening Guide

Comprehensive reference for maintaining deterministic, buildable, and parity‑safe internal links across services, suburbs, and clusters.

---
## 🌐 Core Facade
All link logic routes through `~/lib/links`.

Export highlights:
- `getCrossServiceItemsForSuburb(suburb, { currentService? })` → Cross‑service promo items (here/nearby).
- `getLocalGuidesLink(suburb)` / `getLocalGuidesLinks(suburb)` → Optional blog/local guide URL(s).
- `toServiceHref(service, suburb)` → Canonical service URL (`/services/{service}/{suburb}/`).
- `isServiceCovered(service, suburb)` → Direct coverage check.
- `pickNearbyCoveredInSameClusterSync(service, suburb, coverageJson)` → BFS same‑cluster fallback.
- `getRelatedServiceLinks(opts)` → Legacy related area links (until migrated fully).

Guideline: *Never* construct links with string concatenation outside this façade; use helpers for determinism & future proofing.

---
## 🔐 Invariants
| ID | Invariant | Rationale | Enforced By |
|----|-----------|-----------|-------------|
| L1 | Canonical service URL format `/services/{service}/{suburb}/` | SEO + predictable redirects | `toServiceHref` + unit tests |
| L2 | Nearby fallback stays inside same cluster | Geographical relevance & accuracy | BFS implementation + `lint:graph` |
| L3 | Precompute map == runtime generation | Determinism & drift prevention | `lint:cross` (sample/full) |
| L4 | All emitted links buildable | Zero 404 surface | `lint:buildable` |
| L5 | Adjacency symmetric & intra‑cluster | Stable undirected graph | `fix:adjacency`, `lint:graph` |
| L6 | Coverage tokens valid (suburb or cluster slug) | Prevent ghost pages | `lint:schemas` / future zod validator |
| L7 | No duplicate suburbs across clusters | Data integrity | `lint:schemas` / graph sanity |
| L8 | CSS baseline changes intentional | Noise‑free PRs | `css:baseline:check` |

---
## 🧪 Validation / Tool Matrix
| Purpose | Command | Notes |
|---------|---------|-------|
| Schema + coverage validity | `npm run lint:schemas` | Fails fast on missing/invalid data shapes |
| Graph integrity (existence + cross edges) | `npm run lint:graph` | Non‑fatal cross edges currently logged; symmetry handled by fixer |
| Buildable links (service/suburb) | `npm run lint:buildable` | Validates crossServiceMap & component hardcoded links |
| Parity (precompute vs runtime) | `npm run lint:cross` | Locally samples; CI does full with `FULL_PARITY=1` |
| Adjacency auto‑clean (dry) | `npm run fix:adjacency` | Reports aliasing, drops, mirroring stats |
| Adjacency write | `npm run fix:adjacency:write` | Persists cleaned adjacency.json |
| CSS baseline regression | `npm run css:baseline:check` | Pattern & delta based (hash‑agnostic) |
| Coverage stats overview | (planned) `npm run stats:coverage` | Service → suburb counts |

---
## 🛠️ Auto‑Fix Workflow (Adjacency)
1. Run `npm run fix:adjacency` – review summary.
2. If acceptable, `npm run fix:adjacency:write`.
3. Re‑run: `npm run lint:schemas && npm run lint:graph && npm run lint:buildable && npm run lint:cross`.
4. Commit.

Sample summary fields:
```
{
  nodes_input: 121,
  nodes_kept: 121,
  unknown_nodes: 0,
  unknown_neighbors: 0,
  alias_fixes: 0,
  drops_total: 0,
  cross_edges_dropped: 0,
  mirrored_edges_added: 53
}
```

---
## 🧭 Parity Failures
Output lines:
- `[preonly] suburb -> service/suburb` : Precompute produced a link runtime skipped.
- `[adapteronly] suburb -> service/suburb` : Runtime produced a link missing in precompute.

Steps:
1. `grep` suburb in `src/data/crossServiceMap.json`.
2. Inspect coverage for that service in `serviceCoverage.json` & adjacency BFS path.
3. Rebuild the map: `node scripts/build-cross-service-map.mjs`.
4. Re‑run parity.

Common root causes:
- Adjacency edit altered nearest covered suburb ranking.
- New coverage token added but not normalized.
- Precompute script not re‑run after data change (stale artifact).

---
## 🕸️ Graph / BFS Issues
Symptoms:
- Nearby service always picks same suburb, ignoring closer nodes.
- Parity mismatch after adding adjacency edge.

Checklist:
1. Run `npm run fix:adjacency` – ensure no hidden asymmetry.
2. Confirm both nodes share the same cluster in `areas.clusters.json`.
3. Ensure node degree > 0 (not isolated). If isolated, BFS cannot expand.
4. If multiple equidistant candidates, deterministic order relies on sorted suburb slugs—verify sorting.

---
## 📄 Coverage Token Problems
Error: `Unknown coverage tokens` (future strict validator) or link not appearing.

Actions:
- Verify token is either a suburb slug or a cluster slug.
- If you used a cluster slug intentionally, ensure cluster exists and expands to target suburbs.
- Run `npm run lint:schemas` then rebuild map.

---
## 🧹 Legacy Helper Migration
Deprecated or to remove after full test backfill:
- `src/lib/crossService.ts`
- `src/lib/serviceNav.adapter*.ts`
- `src/utils/internalLinks*.ts` (port logic into facade incrementally)

Shim approach: Replace contents with re‑exports pointing at `~/lib/links` until all imports updated; ensures build‑time visibility if stragglers remain.

---
## 🧾 Commit & CI Flow (Recommended)
```bash
npm run fix:adjacency                # dry-run sanity
npm run prebuild                     # schemas + graph + buildable + map
npm run lint:cross                   # parity (sample)
FULL_PARITY=1 npm run lint:cross     # (optional) full parity locally
npm run build                        # full guardrail build
npm run css:baseline:check           # confirm no CSS regressions
```
If all green, commit & push.

---
## 🩺 Quick Diagnosis Table
| Symptom | Command to Run | Likely Cause | Fix |
|---------|----------------|-------------|-----|
| 404 on a service link | `npm run lint:buildable` | coverage/suburb mismatch | Add coverage or remove link source |
| Parity mismatch | `npm run lint:cross` | stale map or adjacency tweak | Rebuild map / fix BFS input |
| Cross-cluster edge warning | `npm run lint:graph` | adjacency spans clusters | Remove edge or reassign suburb |
| Missing local guide link | Check `getLocalGuidesLink` return | No blog post for suburb | Publish guide or hide CTA |
| CSS baseline fail | `npm run css:baseline:check` | legitimate size growth or hash rename | Optimize OR update baseline |
| Nearby never appears | Inspect coverage & adjacency | service not covered cluster-wide | Add coverage or adjust UX copy |

---
## 🧪 Future Enhancements
- Strong (`zod`) data validator with STRICT_MODE slug enforcement.
- Coverage stats + diff tool (`stats:coverage`).
- Incremental parity test (only changed suburbs).
- Visual diff dashboard for link maps.

---
*Last updated: 2025-09-01*
