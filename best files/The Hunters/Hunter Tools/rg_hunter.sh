#!/usr/bin/env bash
# rg-hunt.sh — Repo Hygiene Hunter (all-in-one)
#
# What it does (high level):
#  - Runs fast, deterministic hygiene checks across your repo
#  - Proves detectors are alive via a self-test canary
#  - Optionally summarizes runtime FS tap evidence if you preload fs-tap.mjs elsewhere
#  - Emits timestamped logs + a Fix‑It brief with copy‑pasteable recipes
#  - Fails CI only for high-risk classes by default (tunable)
#
# Usage:
#   bash scripts/hunt/rg-hunt.sh [--root PATH] [--warn-only] [--max-results N] [--no-tsc]
#
# Exit codes:
#   0 = clean; 1 = issues (policy fail); 2 = missing dependency or fatal error
#
# Notes:
#  - Pair this with a runtime preload: node -r ./scripts/dev/fs-tap.mjs <your command>
#  - This script only *summarizes* fs-tap output (if present in __reports/fs-tap.jsonl)

set -Eeuo pipefail
IFS=$'\n\t'

# ---------------------------
# Config / Flags
# ---------------------------
ROOT="."
WARN_ONLY=0
MAX_RESULTS=50
RUN_TSC=1

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-.}"; shift 2;;
    --warn-only) WARN_ONLY=1; shift;;
    --max-results) MAX_RESULTS="${2:-50}"; shift 2;;
    --no-tsc) RUN_TSC=0; shift;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

# Normalize ROOT
ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

# ---------------------------
# Colors / formatting
# ---------------------------
if [[ -t 1 ]]; then
  BOLD='\e[1m'; DIM='\e[2m'; RED='\e[31m'; YEL='\e[33m'; GRN='\e[32m'; CYA='\e[36m'; RST='\e[0m'
else
  BOLD=''; DIM=''; RED=''; YEL=''; GRN=''; CYA=''; RST=''
fi

section() { printf "\n${BOLD}== %s ==${RST}\n" "$1"; }
info()    { printf "${CYA}ℹ %s${RST}\n" "$*"; }
okay()    { printf "${GRN}✓ %s${RST}\n" "$*"; }
warn()    { printf "${YEL}⚠ %s${RST}\n" "$*"; }
fail()    { printf "${RED}✗ %s${RST}\n" "$*"; }

# ---------------------------
# Reports
# ---------------------------
STAMP=$(date -u +%Y%m%d-%H%M%S)
REPORT_DIR="__reports"
LOG_FILE="${REPORT_DIR}/rg-hunt.${STAMP}.log"
mkdir -p "$REPORT_DIR"
# Mirror all stdout/stderr to the log
exec > >(tee -a "$LOG_FILE") 2>&1

# ---------------------------
# Dependency gate
# ---------------------------
section "Environment"
command -v rg >/dev/null 2>&1 || { fail "ripgrep (rg) is required"; exit 2; }
command -v node >/dev/null 2>&1 || { fail "node is required"; exit 2; }

okay "pwd: $(pwd)"
okay "rg: $(rg --version | head -n1)"
okay "node: $(node -v)"
if [[ $RUN_TSC -eq 1 ]]; then
  if command -v tsc >/dev/null 2>&1; then
    TSC_PRESENT=1; okay "tsc: $(tsc -v)"
  elif command -v npx >/dev/null 2>&1 && npx tsc --version >/dev/null 2>&1; then
    TSC_PRESENT=1; okay "tsc: $(npx tsc --version) (via npx)"
  else
    TSC_PRESENT=0; info "tsc: (not present or disabled)"
  fi
else
  TSC_PRESENT=0; info "tsc: (not present or disabled)"
fi

# ---------------------------
# Helper: ripgrep exclusions
# ---------------------------
# Keep excludes consistent across checks
RG_EXCL=(
  -g '!node_modules/**'
  -g '!.git/**'
  -g '!__reports/**'
  -g '!dist/**'
  -g '!build/**'
  -g '!coverage/**'
  -g '!__tmp/**'
)

# ---------------------------
# Self-test canary (proves detectors fire)
# ---------------------------
self_test_canary() {
  section "Self-Test Canary"
  local C="__tmp/rg-canary.$$"
  mkdir -p "$C/sub(dir)"
  : > "$C/file with spaces.js"
  : > "$C/hash#name.ts"
  : > "$C/weird–dash.md"      # en dash
  : > "$C/sub(dir)/readme.md" # parentheses in path

  # Use same patterns we hunt for
  local offenders
  offenders=$(find "$C" \
    -type f \
    \( -name "*#*" -o -name "*–*" -o -name "* *" -o -name "*(*" \) -print | sort)

  if [[ -n "$offenders" ]]; then
    okay "detectors caught canary filenames"; printf "%s\n" "$offenders" | sed 's/^/  • /'
  else
    fail "detectors MISSED canary filenames"; rm -rf "$C"; return 1
  fi
  rm -rf "$C"
}

if ! self_test_canary; then
  fail "Canary failed — detectors stale/broken"; exit 1
fi

# ---------------------------
# Counters / policy
# ---------------------------
declare -i ISSUES=0

# Per-bucket counts
declare -i CNT_BAD_FILENAMES=0
declare -i CNT_JSON_ERRORS=0
declare -i CNT_JSON_COMMENTS=0
declare -i CNT_EISDIR_SUSPECTS=0
declare -i CNT_ESM_CJS=0
declare -i CNT_SCRIPT_BANG=0
declare -i CNT_TODO=0
declare -i CNT_TSC=0
declare -i CNT_TAP=0

# ---------------------------
# 1) Filename hygiene
# ---------------------------
section "Filename Hygiene"
# Fast & portable: group OR names, prune heavy dirs
mapfile -t BAD_FILES < <(\
  find . \
    \( -path "./node_modules/*" -o -path "./.git/*" -o -path "./__reports/*" -o -path "./dist/*" -o -path "./build/*" -o -path "./coverage/*" -o -path "./__tmp/*" \) -prune -o \
    -type f \( -name "*#*" -o -name "*–*" -o -name "* *" -o -name "*(*" \) -print | sort
)

CNT_BAD_FILENAMES=${#BAD_FILES[@]}
if (( CNT_BAD_FILENAMES > 0 )); then
  warn "problematic filenames: $CNT_BAD_FILENAMES (showing up to $MAX_RESULTS)"
  printf '%s\n' "${BAD_FILES[@]:0:$MAX_RESULTS}" | sed 's/^/  • /'
else
  okay "no problematic filenames detected"
fi

# ---------------------------
# 2) JSON validation (strict) via Node walker
# ---------------------------
section "JSON Validation"
node <<'NODE' | sed 's/^/  /'
const fs = require('fs');
const path = require('path');
const SKIP = new Set(['node_modules','.git','__reports','dist','build','coverage','__tmp']);
function walk(dir, out=[]) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP.has(ent.name)) continue;
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}
const files = walk('.').filter(f => /\.json$/i.test(f) && !/package-lock\.json$/.test(f));
let errs = 0;
for (const f of files) {
  if (/\/tsconfig.*\.json$/i.test(f)) continue; // JSONC allowed
  try {
    JSON.parse(fs.readFileSync(f,'utf8'));
  } catch (e) {
    errs++;
    console.log(`JSON_ERROR: ${f} :: ${String(e.message).replace(/\n/g,' ')}`);
  }
}
console.log(`JSON_SUMMARY: errors=${errs}`);
NODE

# Extract counts
CNT_JSON_ERRORS=$(rg -N "^JSON_ERROR:" "$LOG_FILE" | wc -l | tr -d ' ' || true)
if (( CNT_JSON_ERRORS > 0 )); then
  fail "json parse errors: $CNT_JSON_ERRORS"
  ISSUES+=1
else
  okay "json parse: ok"
fi

# ---------------------------
# 3) Comments in JSON (except tsconfig*.json)
# ---------------------------
section "JSON Comments (forbidden except tsconfig*)"
JSON_COMMENT_MATCHES=$(rg -n --pcre2 "^\s*//|/\*|\*/|\s//[A-Za-z0-9_]" "${RG_EXCL[@]}" -g '*.json' -g '!tsconfig*.json' | head -n "$MAX_RESULTS" || true)
if [[ -n "$JSON_COMMENT_MATCHES" ]]; then
  CNT_JSON_COMMENTS=$(printf '%s\n' "$JSON_COMMENT_MATCHES" | wc -l | tr -d ' ')
  warn "json comment-like lines: $CNT_JSON_COMMENTS (sample below)"
  printf '%s\n' "$JSON_COMMENT_MATCHES" | sed 's/^/  • /'
else
  okay "no comment-like lines in strict JSON"
fi

# ---------------------------
# 4) EISDIR / glob suspects in code
# ---------------------------
section "EISDIR / Glob Suspects"
EISDIR_MATCHES=$(rg -n --pcre2 "readFile(Sync)?\(\s*['\"]([^'\"]*/)['\"]|readFile(Sync)?\(\s*['\"][^'\"]*\*[^'\"]*['\"]|readFile(Sync)?\(\s*([^'\"])\s*[,)]" "${RG_EXCL[@]}" -g '**/*.{js,ts,tsx,jsx,mjs,cjs}' || true)
if [[ -n "$EISDIR_MATCHES" ]]; then
  CNT_EISDIR_SUSPECTS=$(printf '%s\n' "$EISDIR_MATCHES" | wc -l | tr -d ' ')
  warn "possible dir/glob passed to readFile*: $CNT_EISDIR_SUSPECTS (sample up to $MAX_RESULTS)"
  printf '%s\n' "$EISDIR_MATCHES" | head -n "$MAX_RESULTS" | sed 's/^/  • /'
else
  okay "no obvious readFile* dir/glob suspects"
fi

# ---------------------------
# 5) ESM/CJS mismatches
# ---------------------------
section "ESM/CJS Mismatches"
ESM_CJS_MATCHES=$(\
  { rg -n --pcre2 "(^|[^A-Za-z0-9_])require\(" "${RG_EXCL[@]}" -g '**/*.mjs' || true; } ;\
  { rg -n --pcre2 "\bmodule\.exports\s*=" "${RG_EXCL[@]}" -g '**/*.mjs' || true; } ;\
  { rg -n --pcre2 "^\s*import\b" "${RG_EXCL[@]}" -g '**/*.cjs' || true; } ;\
  { rg -n --pcre2 "^\s*export\b" "${RG_EXCL[@]}" -g '**/*.cjs' || true; } \
)
if [[ -n "$ESM_CJS_MATCHES" ]]; then
  CNT_ESM_CJS=$(printf '%s\n' "$ESM_CJS_MATCHES" | wc -l | tr -d ' ')
  warn "esm/cjs mixed patterns: $CNT_ESM_CJS (sample up to $MAX_RESULTS)"
  printf '%s\n' "$ESM_CJS_MATCHES" | head -n "$MAX_RESULTS" | sed 's/^/  • /'
else
  okay "module system usage looks consistent"
fi

# ---------------------------
# 6) npm script hazards: '!'
# ---------------------------
section "npm Script Hazards (! in scripts)"
SCRIPT_BANG_MATCHES=$(node <<'NODE'
const fs=require('fs');
try{
  const s=fs.readFileSync('package.json','utf8');
  const j=JSON.parse(s); const out=[];
  for (const [k,v] of Object.entries(j.scripts||{})) if (String(v).includes('!')) out.push(`${k} => ${v}`);
  if(out.length) console.log(out.join('\n'));
}catch{ /* ignore */ }
NODE
)
if [[ -n "$SCRIPT_BANG_MATCHES" ]]; then
  CNT_SCRIPT_BANG=$(printf '%s\n' "$SCRIPT_BANG_MATCHES" | wc -l | tr -d ' ')
  warn "npm scripts containing '!': $CNT_SCRIPT_BANG"
  printf '%s\n' "$SCRIPT_BANG_MATCHES" | sed 's/^/  • /'
else
  okay "no risky '!' found in npm scripts"
fi

# ---------------------------
# 7) TODO / FIXME / HACK sweep (non-fatal)
# ---------------------------
section "TODO / FIXME / HACK"
TODO_MATCHES=$(rg -n --pcre2 "\b(TODO|FIXME|HACK)\b" "${RG_EXCL[@]}" || true)
if [[ -n "$TODO_MATCHES" ]]; then
  CNT_TODO=$(printf '%s\n' "$TODO_MATCHES" | wc -l | tr -d ' ')
  warn "found TODO/FIXME/HACK: $CNT_TODO (sample up to $MAX_RESULTS)"
  printf '%s\n' "$TODO_MATCHES" | head -n "$MAX_RESULTS" | sed 's/^/  • /'
else
  okay "no TODO/FIXME/HACK markers spotted"
fi

# ---------------------------
# 8) TypeScript check (optional)
# ---------------------------
if [[ $TSC_PRESENT -eq 1 ]]; then
  section "TypeScript Typecheck"
  if command -v tsc >/dev/null 2>&1; then
    if tsc --noEmit --pretty false; then
      okay "tsc: ok"
    else
      CNT_TSC=1
      warn "tsc reported errors (see output above)"
    fi
  else
    if npx tsc --noEmit --pretty false; then
      okay "tsc: ok"
    else
      CNT_TSC=1
      warn "tsc reported errors (see output above)"
    fi
  fi
fi

# ---------------------------
# 9) Runtime FS tap summary (if present)
# ---------------------------
section "Runtime Tap Summary"
if [[ -f "${REPORT_DIR}/fs-tap.jsonl" ]]; then
  CNT_TAP=$(wc -l < "${REPORT_DIR}/fs-tap.jsonl" | tr -d ' ')
  if (( CNT_TAP > 0 )); then
    fail "suspicious runtime fs calls: $CNT_TAP (see ${REPORT_DIR}/fs-tap.jsonl)"; ISSUES+=1
  else
    okay "no suspicious runtime fs calls recorded"
  fi
else
  info "no fs-tap log found; run code/tests with: node -r ./scripts/dev/fs-tap.mjs …"
fi

# ---------------------------
# 10) Fix‑It Brief (next actions + recipes)
# ---------------------------
section "Fix‑It Brief"
node <<'NODE'
const fs=require('fs'); const path=require('path');
const R='__reports', P=path.join(R,'patches'); if(!fs.existsSync(R)) fs.mkdirSync(R,{recursive:true}); if(!fs.existsSync(P)) fs.mkdirSync(P,{recursive:true});
const latest=() => fs.readdirSync(R).filter(f=>/^rg-hunt\.\d{8}-\d{6}\.log$/.test(f)).sort().pop();
const LOG=latest()?path.join(R,latest()):null; const TAP=path.join(R,'fs-tap.jsonl');
const out=[`# Hunt Fix-It Brief (${new Date().toISOString()})`];
function add(h,b){ out.push(`## ${h}`); if(b) out.push(b); }
if(LOG&&fs.existsSync(LOG)){
  const s=fs.readFileSync(LOG,'utf8');
  const jsonErr=[...s.matchAll(/^JSON_ERROR: (.*)$/gm)].slice(0,10).map(m=>`- ${m[1]}`);
  if(jsonErr.length){
    add('JSON parse errors', jsonErr.join('\n')+"\n**Recipe**:\n```bash\n# remove comments & trailing commas; JSONC only in tsconfig*\n```\n");
  }
  if(/\.mjs[^\n]*require\(/i.test(s)) add('`.mjs` uses `require()`', "**Recipe**:\n```js\n// before\nconst x = require('pkg');\n// after\nimport x from 'pkg';\n```\n");
  if(/module\.exports[^\n]*\.mjs/i.test(s)) add('`module.exports` inside `.mjs`', "**Recipe**:\n```js\n// before\nmodule.exports = fn;\n// after\nexport default fn;\n```\n");
  if(/^\s*export\b.*\.cjs/mi.test(s)) add('`export` inside `.cjs`', "**Recipe**:\n```js\n// before (CJS)\nexport const x = 1;\n// after\nmodule.exports = { x: 1 };\n```\n");
  if(/SCRIPT_BANG/.test(s)) add("npm scripts contain '!'", "**Recipe**:\n```json\n// move shell to node script and call from package.json\n```\n");
}
if(fs.existsSync(TAP)){
  const lines=fs.readFileSync(TAP,'utf8').trim().split(/\r?\n/).filter(Boolean).map(l=>JSON.parse(l));
  const bad=lines.filter(e=>/^readFile/.test(e.ev));
  if(bad.length){
    const top = Object.entries(bad.reduce((a,e)=>{a[e.p]=(a[e.p]||0)+1;return a;},{}) ).sort((a,b)=>b[1]-a[1]).slice(0,3).map(([p,c])=>`- ${p} (${c})`).join('\n');
    add(`Runtime suspicious reads (${bad.length})`, `Paths (top):\n${top}\n\n**Recipe**:\n\`\`\`js\n// before\nfs.readFileSync("schemas/");\n// after\nfor (const f of fs.readdirSync("schemas")) {\n  if (f.endsWith(".json")) {\n    const s = fs.readFileSync(require('path').join("schemas", f), "utf8");\n  }\n}\n\`\`\`\n`);
  }
}
fs.writeFileSync(path.join(R,'hunt-fixit.md'), out.join('\n\n')+"\n");
console.log('  wrote __reports/hunt-fixit.md');
NODE

# ---------------------------
# Policy evaluation (danger classes cause fail)
# ---------------------------
# Danger classes: JSON parse errors, runtime tap hits
(( CNT_JSON_ERRORS > 0 )) && ISSUES+=1

# Warnings remain warnings unless you want to escalate (example thresholds):
# if (( CNT_ESM_CJS > 20 )); then ISSUES+=1; fi

section "Summary"
printf "${BOLD}Files with bad names:${RST} %d\n" "$CNT_BAD_FILENAMES"
printf "${BOLD}JSON parse errors:${RST} %d\n" "$CNT_JSON_ERRORS"
printf "${BOLD}JSON comment-like:${RST} %d\n" "$CNT_JSON_COMMENTS"
printf "${BOLD}EISDIR/glob suspects:${RST} %d\n" "$CNT_EISDIR_SUSPECTS"
printf "${BOLD}ESM/CJS mismatches:${RST} %d\n" "$CNT_ESM_CJS"
printf "${BOLD}npm '!' scripts:${RST} %d\n" "$CNT_SCRIPT_BANG"
printf "${BOLD}TODO/FIXME/HACK:${RST} %d\n" "$CNT_TODO"
printf "${BOLD}Runtime FS tap hits:${RST} %d\n" "$CNT_TAP"

if (( ISSUES > 0 )); then
  if (( WARN_ONLY == 1 )); then
    warn "Hunt found $ISSUES issue group(s) (warn-only mode; exit 0)"; exit 0
  else
    fail "Hunt failed with $ISSUES issue group(s)"; exit 1
  fi
else
  okay "Hunt clean"; exit 0
fi
