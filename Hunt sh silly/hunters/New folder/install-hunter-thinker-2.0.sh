#!/usr/bin/env bash
# install-hunter-thinker-2.0.sh — Well‑rounded Learning + Thinking Hunter (idempotent, CI‑friendly)
# Target stack: Astro repos with modular hunters (runtime_ssr.sh, performance.sh, accessibility.sh, security.sh, code_quality.sh, build_dependencies.sh, rg-hunt.sh, hunt.sh)
# What this does:
#   • Adds a lightweight Thinker that reads ALL hunter reports + trace events and writes a ranked Do‑Next agenda.
#   • Adds new detectors (geo_fitness, data_contracts, content_integrity, perf_budget, determinism harness) that complement SSR.
#   • Encodes strict invariants across modules (policy) and a single verdict for CI.
#   • Adds an append‑only ledger (var/hunt-events.ndjson) for “what files were opened / what invariants tripped”.
#   • Wires package.json scripts for local + CI use, without touching your existing hunters.
#
# Usage:
#   bash install-hunter-thinker-2.0.sh --force --site=https://your-domain.com
#   npx playwright install   # only if you already use Playwright; otherwise harmless to skip
#   npm run hunt:ci         # or run 'bash ./hunt.sh' then 'npm run hunt:thinker'
#
set -euo pipefail

FORCE=0
SITE="${SITE:-https://YOUR-PRODUCTION-DOMAIN.com}"
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --site=*) SITE="${a#*=}" ;;
  esac
done

require_files=( package.json )
for f in "${require_files[@]}"; do
  [[ -f "$f" ]] || { echo "❌ Missing $f — run from repo root."; exit 1; }
done

ROOT="$PWD"
AI="__ai/thinker"
RPTS="__reports/hunt"
HUNTERS="hunters"
SCR="scripts/thinker"
VAR="var"
mkdir -p "$AI" "$RPTS" "$HUNTERS" "$SCR" "$VAR" tmp

# Idempotency check
EXIST=()
for f in "$SCR/aggregate.mjs" "$SCR/policy.mjs" "$HUNTERS/trace.sh" "$HUNTERS/geo_fitness.sh" "$HUNTERS/data_contracts.sh" "$HUNTERS/content_integrity.sh" "$HUNTERS/perf_budget.sh" "$HUNTERS/determinism.sh" "$AI/policy.json" "$AI/config.json" "HUNTER_THINKER_README.md"; do
  [[ -f "$f" ]] && EXIST+=("$f")
done
if [[ ${#EXIST[@]} -gt 0 && $FORCE -ne 1 ]]; then
  echo "⚠️  Hunter Thinker files already present. Re‑run with --force to overwrite:"
  printf ' - %s\n' "${EXIST[@]}"
  exit 0
fi

# ----------------------------- config + policy -----------------------------
cat > "$AI/config.json" <<JSON
{
  "site": "${SITE}",
  "weights": { "severity": 3.0, "recurrence": 1.6, "blast": 1.4, "timeToFix": -0.8, "unlocks": 1.2 },
  "thresholds": { "recommend": 2.0, "maxAgenda": 12 },
  "memoryFile": "__ai/thinker/memory.json",
  "hotFilesTopN": 12,
  "determinism": { "enabled": true, "fakeNow": "2001-01-01T00:00:00.000Z" }
}
JSON

cat > "$AI/policy.json" <<'JSON'
{
  "strict_invariants": [
    "runtime_ssr.truthPin != \"violated\"",
    "runtime_ssr.counts.noAdapter == 0",
    "runtime_ssr.counts.dynamicJsonImports == 0",
    "build_dependencies.counts.potential_conflicts == 0",
    "build_dependencies.counts.illegal_targets == 0",
    "geo_fitness.counts.importAssertions == 0",
    "geo_fitness.counts.dynamicJsonImports == 0",
    "data_contracts.counts.schemasFailed == 0",
    "determinism.diff == \"\""
  ],
  "warn_invariants": [
    "content_integrity.counts.brokenAnchors == 0",
    "performance.counts.largeImages == 0",
    "accessibility.counts.criticalA11y == 0",
    "security.counts.secrets == 0",
    "code_quality.counts.esmCjsBoundary == 0"
  ]
}
JSON

# ----------------------------- trace shim -----------------------------
cat > "$HUNTERS/trace.sh" <<'BASH'
# hunters/trace.sh — tiny event logger for all hunters (optional, no‑fail)
TRACE_FILE="${TRACE_FILE:-var/hunt-events.ndjson}"
mkdir -p "$(dirname "$TRACE_FILE")"
_ts() { date -Iseconds; }
_trace() {
  local op="$1"; local payload="${2:-{}}"
  printf '{"t":"%s","module":"%s","op":"%s","data":%s}\n' "$(_ts)" "${HUNTER_MODULE:-unknown}" "$op" "$payload" >> "$TRACE_FILE" || true
}
trace_open_file() { local p="${1:-}"; _trace open_file "$(jq -n --arg path "$p" '{path:$path}')" ; }
trace_issue()     { local cls="${1:-}"; local p="${2:-}"; local sev="${3:-warn}"; _trace issue "$(jq -n --arg class "$cls" --arg path "$p" --arg severity "$sev" '{class:$class,path:$path,severity:$severity}')" ; }
trace_invariant() { local name="${1:-}"; local status="${2:-fail}"; _trace invariant "$(jq -n --arg name "$name" --arg status "$status" '{name:$name,status:$status}')" ; }
BASH
chmod +x "$HUNTERS/trace.sh"

# ----------------------------- detectors -----------------------------
cat > "$HUNTERS/geo_fitness.sh" <<'BASH'
#!/usr/bin/env bash
# hunters/geo_fitness.sh — Enforce static geo imports (Sept 17 pattern) and ban dynamic JSON imports / import assertions
set -euo pipefail
HUNTER_MODULE="geo_fitness"; source "hunters/trace.sh" || true
OUT="__reports/hunt/geo_fitness.json"; mkdir -p "$(dirname "$OUT")"

rg -n "import\\s+.+\\s+from\\s+['\"][^'\"]+\\.json['\"][^\\n]*assert\\s*\\{\\s*type\\s*:\\s*['\"]json['\"]\\s*\\}" src || true > .tmp.geo_asserts || true
rg -n "await\\s+import\\([^)]*\\.json[^)]*\\)" src || true > .tmp.geo_dynamic || true

BAD_ASSERTS=$(wc -l < .tmp.geo_asserts || echo 0)
BAD_DYNAMIC=$(wc -l < .tmp.geo_dynamic || echo 0)
STATUS="pass"; [[ $BAD_ASSERTS -gt 0 || $BAD_DYNAMIC -gt 0 ]] && STATUS="critical"

ACTIONS=()
[[ $BAD_ASSERTS -gt 0 ]] && ACTIONS+=("Replace JSON import assertions with static imports (gold pattern: src/utils/geoCompat.ts with ~/lib/* aliases).")
[[ $BAD_DYNAMIC -gt 0 ]] && ACTIONS+=("Remove dynamic JSON imports; move data shaping to build step and consume static outputs.")

jq -n \
  --arg status "$STATUS" \
  --argjson asserts ${BAD_ASSERTS:-0} \
  --argjson dynamic ${BAD_DYNAMIC:-0} \
  --argjson actions "$(printf '%s\n' "${ACTIONS[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" '
{
  module:"geo_fitness", status:$status,
  issues: ($asserts + $dynamic),
  counts: { importAssertions: $asserts, dynamicJsonImports: $dynamic },
  affected_files: ($asserts + $dynamic),
  actions: $actions,
  policy_invariants: ["counts.importAssertions==0","counts.dynamicJsonImports==0"],
  eta_minutes: 30,
  unlocks: ["runtime_ssr","performance"]
}' > "$OUT"
BASH
chmod +x "$HUNTERS/geo_fitness.sh"

cat > "$HUNTERS/data_contracts.sh" <<'BASH'
#!/usr/bin/env bash
# hunters/data_contracts.sh — Validate minimal schemas in src/data & src/content (keys only; fast, zero deps)
set -euo pipefail
HUNTER_MODULE="data_contracts"; source "hunters/trace.sh" || true
OUT="__reports/hunt/data_contracts.json"; mkdir -p "$(dirname "$OUT")"

miss=0; files=0; actions=()
check_req() { local file="$1"; shift; files=$((files+1))
  trace_open_file "$file" || true
  for key in "$@"; do
    if ! rg -q "\"$key\"\\s*:" "$file"; then
      miss=$((miss+1)); actions+=("Add key '$key' to $file"); trace_issue "missing_key:$key" "$file" "critical" || true
    fi
  done
}

while IFS= read -r f; do check_req "$f" "serviceId" "slug"; done < <(rg -l --glob "src/data/**/*.json" . || true)
while IFS= read -r f; do check_req "$f" "title" "updated"; done < <(rg -l --glob "src/content/**/*.json" . || true)

status=$([[ $miss -eq 0 ]] && echo pass || echo critical)
jq -n --arg status "$status" --argjson miss ${miss:-0} --argjson files ${files:-0} \
  --argjson actions "$(printf '%s\n' "${actions[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" '
{
  module:"data_contracts", status:$status, issues: $miss,
  counts: { schemasFailed: $miss }, affected_files: $files,
  actions: $actions, policy_invariants:["counts.schemasFailed==0"], eta_minutes: 20,
  unlocks:["runtime_ssr","build_dependencies"]
}' > "$OUT"
BASH
chmod +x "$HUNTERS/data_contracts.sh"

cat > "$HUNTERS/content_integrity.sh" <<'BASH'
#!/usr/bin/env bash
# hunters/content_integrity.sh — Broken (#anchor) links without corresponding {#anchor} headings
set -euo pipefail
HUNTER_MODULE="content_integrity"; source "hunters/trace.sh" || true
OUT="__reports/hunt/content_integrity.json"; mkdir -p "$(dirname "$OUT")"

BROKEN="$(rg -n "\\(#([^)]+)\\)" -g "src/**/*.mdx" -g "src/**/*.md" -g "src/**/*.astro" || true)"
COUNT=$(printf "%s" "$BROKEN" | grep -c . || true)
STATUS=$([[ ${COUNT:-0} -eq 0 ]] && echo pass || echo warn)
[[ ${COUNT:-0} -gt 0 ]] && trace_issue "broken_anchor" "$(echo "$BROKEN" | head -n1 | cut -d: -f1)" "warn" || true

jq -n --arg status "$STATUS" --argjson count ${COUNT:-0} --arg sample "$(printf "%s" "$BROKEN" | head -n 20)" '
{
  module:"content_integrity", status:$status, issues:$count,
  counts:{ brokenAnchors:$count }, affected_files:$count,
  actions: ($count>0 ? ["Fix or add missing anchors {#...} for referenced (#anchor) links."] : []),
  samples: ( $sample | split("\n") ),
  policy_invariants:["counts.brokenAnchors==0"], eta_minutes: 15, unlocks:["a11y","seo"]
}' > "$OUT"
BASH
chmod +x "$HUNTERS/content_integrity.sh"

cat > "$HUNTERS/perf_budget.sh" <<'BASH'
#!/usr/bin/env bash
# hunters/perf_budget.sh — Build-time budgets using dist/ assets (no Lighthouse)
set -euo pipefail
HUNTER_MODULE="perf_budget"; source "hunters/trace.sh" || true
OUT="__reports/hunt/perf_budget.json"; mkdir -p "$(dirname "$OUT")"

BUDGET_JS_KB=${BUDGET_JS_KB:-350}      # tune as needed
BUDGET_IMG_KB=${BUDGET_IMG_KB:-512}

total_js_kb=0
large_images=0
if [[ -d "dist/assets" ]]; then
  while IFS= read -r f; do
    kb=$(( ( $(stat -c%s "$f" 2>/dev/null || stat -f%z "$f") + 1023 ) / 1024 ))
    [[ "$f" == *.js ]] && total_js_kb=$((total_js_kb + kb))
  done < <(find dist/assets -type f -maxdepth 1 2>/dev/null)

  while IFS= read -r f; do
    kb=$(( ( $(stat -c%s "$f" 2>/dev/null || stat -f%z "$f") + 1023 ) / 1024 ))
    if [[ $kb -gt $BUDGET_IMG_KB ]]; then
      large_images=$((large_images+1))
      trace_issue "large_image" "$f" "warn" || true
    fi
  done < <(find dist -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) 2>/dev/null)
fi

status="pass"
[[ $total_js_kb -gt $BUDGET_JS_KB ]] && status="warn"
[[ $large_images -gt 0 ]] && status="warn"

jq -n --arg status "$status" --argjson totalJsKb ${total_js_kb:-0} --argjson largeImages ${large_images:-0} --argjson jsBudget ${BUDGET_JS_KB:-350} --argjson imgBudget ${BUDGET_IMG_KB:-512} '
{
  module:"perf_budget", status:$status, issues: ( ($totalJsKb > $jsBudget ? 1 : 0) + ($largeImages>0 ? 1 : 0) ),
  counts: { totalJsKb: $totalJsKb, largeImages: $largeImages },
  budgets: { jsKb: $jsBudget, imageKb: $imgBudget },
  affected_files: $largeImages,
  actions: ( ($totalJsKb > $jsBudget) or ($largeImages>0) ? ["Reduce total JS (code-split, remove unused libs); compress/resize large images."] : [] ),
  policy_invariants: [], eta_minutes: 25, unlocks:["cls","ttfb"]
}' > "$OUT"
BASH
chmod +x "$HUNTERS/perf_budget.sh"

cat > "$HUNTERS/determinism.sh" <<'BASH'
#!/usr/bin/env bash
# hunters/determinism.sh — Run hunters twice with FAKE_NOW and diff reports to ensure reproducibility
set -euo pipefail
OUT="__reports/hunt/determinism.json"; mkdir -p "$(dirname "$OUT")"
BASE_DIR="tmp/determinism/base"; SHIFT_DIR="tmp/determinism/shift"
rm -rf "$BASE_DIR" "$SHIFT_DIR"; mkdir -p "$BASE_DIR" "$SHIFT_DIR"

# First pass: current time
bash ./hunt.sh || true
rsync -a --delete "__reports/hunt/" "$BASE_DIR/" || true

# Second pass: shifted time
export FAKE_NOW="${FAKE_NOW:-2001-01-01T00:00:00.000Z}"
bash ./hunt.sh || true
rsync -a --delete "__reports/hunt/" "$SHIFT_DIR/" || true

DIFF=$(diff -qr "$BASE_DIR" "$SHIFT_DIR" || true)
STATUS=$([[ -z "$DIFF" ]] && echo pass || echo warn)

jq -n --arg status "$STATUS" --arg diff "${DIFF:-}" '
{
  module:"determinism", status:$status, issues: ( $diff=="" ? 0 : 1 ),
  counts: {}, affected_files: 0, actions: ( $diff=="" ? [] : ["Eliminate wall-clock dependent code in hunters/generators; honor FAKE_NOW."] ),
  policy_invariants: [], eta_minutes: 20, unlocks:["cache","reproducible_builds"],
  diff: $diff
}' > "$OUT"
BASH
chmod +x "$HUNTERS/determinism.sh"

# ----------------------------- thinker: aggregate + policy -----------------------------
cat > "$SCR/aggregate.mjs" <<'NODE'
#!/usr/bin/env node
/**
 * scripts/thinker/aggregate.mjs — Reads __reports/hunt/*.json + var/hunt-events.ndjson
 * → Writes __ai/thinker/master-insights.json and DO_NEXT.md (ranked agenda).
 */
import fs from "node:fs"; import path from "node:path";

const CFG = JSON.parse(fs.readFileSync("__ai/thinker/config.json","utf8"));
const RPT_DIR = "__reports/hunt";
const TRACE = "var/hunt-events.ndjson";
const OUT_DIR = "__ai/thinker";
fs.mkdirSync(OUT_DIR, { recursive: true });

const reports = fs.existsSync(RPT_DIR)
  ? fs.readdirSync(RPT_DIR).filter(f=>f.endsWith(".json")).map(f=>({ name:f.replace(/\.json$/,""), data: JSON.parse(fs.readFileSync(path.join(RPT_DIR,f),"utf8")) }))
  : [];

const traces = fs.existsSync(TRACE)
  ? fs.readFileSync(TRACE,"utf8").trim().split("\n").map(l=>{try{return JSON.parse(l)}catch{return null}}).filter(Boolean)
  : [];

const feat = r => ({ sev:r.status==="critical"?2:r.status==="warn"?1:0, rec:r.issues||0, br:r.affected_files||0, ttf:r.eta_minutes||15, unl:(r.unlocks||[]).length });
const N = x => Math.log(1+Math.max(0,x));
const score = f => CFG.weights.severity*f.sev + CFG.weights.recurrence*N(f.rec) + CFG.weights.blast*N(f.br) + CFG.weights.timeToFix*N(f.ttf) + CFG.weights.unlocks*f.unl;

const agenda = reports.flatMap(({name, data}) => {
  const r = data;
  const f = feat(r);
  const s = score(f);
  if (!Array.isArray(r.actions) || r.actions.length===0) return [];
  if (s < (CFG.thresholds.recommend||2)) return [];
  return [{
    module: r.module || name,
    status: r.status,
    score: +s.toFixed(2),
    evidence: { issues: r.issues||0, counts: r.counts||{}, eta: r.eta_minutes||null, unlocks: r.unlocks||[] },
    actions: r.actions.slice(0,6),
    proofs: r.policy_invariants||[]
  }];
}).sort((a,b)=>b.score-a.score).slice(0, CFG.thresholds.maxAgenda||12);

const hotMap = {}; for (const t of traces) if (t.op==="open_file" && t.data?.path) hotMap[t.data.path]=(hotMap[t.data.path]||0)+1;
const hotFiles = Object.entries(hotMap).sort((a,b)=>b[1]-a[1]).slice(0, CFG.hotFilesTopN).map(([path,count])=>({path,count}));

const memoryFile = CFG.memoryFile || path.join(OUT_DIR,"memory.json");
let memory = fs.existsSync(memoryFile) ? JSON.parse(fs.readFileSync(memoryFile,"utf8")) : { plays:{} };

// Learn: boost plays that repeatedly turned critical→pass.
for (const { module, status, evidence } of agenda) {
  const key = `${module}`;
  const prev = memory.plays[key]?.lastStatus || null;
  if (prev && prev==="critical" && status !== "critical") {
    memory.plays[key] = { success_count: (memory.plays[key]?.success_count||0) + 1, lastStatus: status };
  } else {
    memory.plays[key] = { success_count: (memory.plays[key]?.success_count||0), lastStatus: status };
  }
}
fs.writeFileSync(memoryFile, JSON.stringify(memory,null,2));

const INSIGHTS = { t: new Date().toISOString(), agenda, hotFiles, modules: reports.map(r=>r.name) };
fs.writeFileSync(path.join(OUT_DIR,"master-insights.json"), JSON.stringify(INSIGHTS,null,2));

// Render DO_NEXT.md
const lines = [];
lines.push("# Hunter Thinker — Do‑Next Agenda\n");
agenda.forEach((a,i)=>{
  lines.push(`## ${i+1}. ${a.module}  —  ${a.status.toUpperCase()}  (score ${a.score})`);
  lines.push("");
  lines.push("**Evidence**");
  lines.push("```json"); lines.push(JSON.stringify(a.evidence,null,2)); lines.push("```");
  if (a.actions?.length) { lines.push("**Actions**"); a.actions.forEach(x=>lines.push(`- ${x}`)); }
  if (a.proofs?.length)  { lines.push("**Proof invariants**"); a.proofs.forEach(x=>lines.push(`- \`${x}\``)); }
  lines.push("");
});
if (hotFiles.length) {
  lines.push("## Hot files (focus areas)");
  hotFiles.forEach(h=>lines.push(`- ${h.path}  (${h.count})`));
}
fs.writeFileSync(path.join(OUT_DIR,"DO_NEXT.md"), lines.join("\n"));

console.log("[thinker] wrote __ai/thinker/master-insights.json and DO_NEXT.md");
NODE
chmod +x "$SCR/aggregate.mjs"

cat > "$SCR/policy.mjs" <<'NODE'
#!/usr/bin/env node
/**
 * scripts/thinker/policy.mjs — Evaluate strict + warn invariants across module reports.
 * Exits 1 in --strict if any strict invariant fails.
 */
import fs from "node:fs"; import path from "node:path";

const POLICY = JSON.parse(fs.readFileSync("__ai/thinker/policy.json","utf8"));
const RPT_DIR = "__reports/hunt";
const STRICT = process.argv.includes("--strict");

const reports = {};
if (fs.existsSync(RPT_DIR)) {
  for (const f of fs.readdirSync(RPT_DIR)) {
    if (!f.endsWith(".json")) continue;
    const name = f.replace(/\.json$/,"");
    try { reports[name] = JSON.parse(fs.readFileSync(path.join(RPT_DIR,f),"utf8")); } catch {}
  }
}

function get(pathExpr) {
  // pathExpr: "module.key1.key2"
  const [mod, ...rest] = pathExpr.split(".");
  const root = reports[mod] || {};
  return rest.reduce((acc, k) => (acc && typeof acc === "object" ? acc[k] : undefined), root);
}

function evalExpr(expr) {
  // Very small evaluator for forms like: "module.counts.x == 0", "!=", ">", "<", "== \"violated\"" etc.
  // Split by operators (space-delimited assumption for simplicity).
  const tokens = expr.trim().split(/\s+/);
  if (tokens.length < 3) return { ok: true, detail: "skip" };
  const left = tokens[0];
  const op = tokens[1];
  const rightRaw = tokens.slice(2).join(" ");
  const leftVal = get(left);
  let rightVal;
  if (/^".*"$/.test(rightRaw) || /^'.*'$/.test(rightRaw)) rightVal = rightRaw.slice(1,-1);
  else if (/^\d+(\.\d+)?$/.test(rightRaw)) rightVal = Number(rightRaw);
  else if (rightRaw === "true" || rightRaw === "false") rightVal = (rightRaw === "true");
  else rightVal = get(rightRaw);

  let ok = true;
  switch (op) {
    case "==": ok = (leftVal === rightVal); break;
    case "!=": ok = (leftVal !== rightVal); break;
    case ">":  ok = (Number(leftVal) >  Number(rightVal)); break;
    case "<":  ok = (Number(leftVal) <  Number(rightVal)); break;
    case ">=": ok = (Number(leftVal) >= Number(rightVal)); break;
    case "<=": ok = (Number(leftVal) <= Number(rightVal)); break;
    default: ok = true;
  }
  return { ok, detail: JSON.stringify({ left:leftVal, op, right:rightVal }) };
}

const fails = [];
for (const inv of POLICY.strict_invariants||[]) {
  const { ok, detail } = evalExpr(inv);
  if (!ok) fails.push({ type:"strict", inv, detail });
}
const warns = [];
for (const inv of POLICY.warn_invariants||[]) {
  const { ok, detail } = evalExpr(inv);
  if (!ok) warns.push({ type:"warn", inv, detail });
}

const verdict = { strict_fails:fails, warn_fails:warns, modules:Object.keys(reports) };
fs.writeFileSync("__ai/thinker/verdict.json", JSON.stringify(verdict,null,2));
console.log("[policy] modules:", verdict.modules.join(", "));
if (fails.length) {
  console.error("[policy] STRICT FAILS:", fails);
  if (STRICT) process.exit(1);
} else {
  console.log("[policy] strict OK");
}
if (warns.length) console.warn("[policy] WARNINGS:", warns);
NODE
chmod +x "$SCR/policy.mjs"

# ----------------------------- package.json integration -----------------------------
node - <<'NODE'
const fs=require('fs'); const p='package.json';
const pkg=JSON.parse(fs.readFileSync(p,'utf8'));
pkg.scripts ||= {};
pkg.scripts["hunt:geo"]          = "bash hunters/geo_fitness.sh";
pkg.scripts["hunt:contracts"]    = "bash hunters/data_contracts.sh";
pkg.scripts["hunt:content"]      = "bash hunters/content_integrity.sh";
pkg.scripts["hunt:perf"]         = "bash hunters/perf_budget.sh";
pkg.scripts["hunt:determinism"]  = "bash hunters/determinism.sh";
pkg.scripts["hunt:thinker"]      = "node scripts/thinker/aggregate.mjs";
pkg.scripts["hunt:policy"]       = "node scripts/thinker/policy.mjs";
pkg.scripts["hunt:policy:strict"]= "node scripts/thinker/policy.mjs --strict";
pkg.scripts["hunt:all"]          = "bash ./hunt.sh && npm run hunt:geo && npm run hunt:contracts && npm run hunt:content && npm run hunt:perf && npm run hunt:determinism";
pkg.scripts["hunt:ci"]           = "npm run hunt:all && npm run hunt:thinker && npm run hunt:policy:strict";
fs.writeFileSync(p, JSON.stringify(pkg,null,2));
console.log('✅ package.json scripts updated');
NODE

# ----------------------------- README -----------------------------
cat > "HUNTER_THINKER_README.md" <<'MD'
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
MD

echo "✅ Hunter Thinker 2.0 installed.
Next:
  npm run hunt:ci
Artifacts:
  - __ai/thinker/master-insights.json
  - __ai/thinker/DO_NEXT.md
  - __ai/thinker/verdict.json
  - var/hunt-events.ndjson (if hunters emit traces)
"
