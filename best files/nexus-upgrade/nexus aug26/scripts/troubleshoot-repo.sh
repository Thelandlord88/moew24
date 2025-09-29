#!/usr/bin/env bash
# Troubleshoot Repo – Astro + Netlify + Tailwind v4
# Idempotent fixes for:
# - CRLF→LF normalization
# - Shebang exec bits (+x) in scripts/
# - Git LF policy (.gitattributes)
# - NPM-only dependency hygiene
# - Tailwind v4 pipeline audit (Vite plugin vs PostCSS)
# - Build with local trace (via npm exec astro)
# - Output verification (dist/ and Netlify SSR)
set -euo pipefail

# -------- Config -----------------------------
REPO_ROOT="${REPO_ROOT:-$(pwd)}"
RUN_DIR="${REPO_ROOT}/.debug-exit1"
OUT_DIR="${RUN_DIR}/fix-$(date -u +%Y%m%d-%H%M%S)"
LOG="${OUT_DIR}/troubleshoot.log"
TRACE_ERR="${OUT_DIR}/local-trace.err"
WARNINGS="${OUT_DIR}/warnings.txt"
SCRIPTS_DIR="scripts"
PKG_JSON="${REPO_ROOT}/package.json"
GATTR="${REPO_ROOT}/.gitattributes"

# Common CRLF hotspots (add more paths if needed)
CRLF_TARGETS=(
  "astro.config.mjs"
  "tailwind.config.js"
  "src/utils/math.js"
  "src/utils/schemamanager.js"
  "src/utils/slugify.js"
  "src/utils/slugify.test.js"
)

# -------- Flags ------------------------------
FIX_CRLF=0
FIX_EXEC=0
FIX_GIT=0
FIX_DEPS=0
RUN_BUILD=0
CHECK_ONLY=0
ALL=0

usage() {
  cat <<'EOF'
Usage:
  troubleshoot-repo.sh [--fix-crlf] [--fix-exec] [--fix-git] [--fix-deps] [--build] [--check-only] [--fix-all]

Flags:
  --fix-crlf    Normalize CRLF→LF in known files
  --fix-exec    chmod +x any shebang'd files under scripts/
  --fix-git     Enforce LF policy via .gitattributes (text=auto eol=lf)
  --fix-deps    npm-only cleanup (remove other lockfiles, prune, npm ci)
  --build       Run Astro build with local trace (npm exec) and extract warnings
  --check-only  Report only; no changes
  --fix-all     Do everything above

Examples:
  bash scripts/troubleshoot-repo.sh --fix-all
  bash scripts/troubleshoot-repo.sh --check-only --build
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix-crlf) FIX_CRLF=1;;
    --fix-exec) FIX_EXEC=1;;
    --fix-git)  FIX_GIT=1;;
    --fix-deps) FIX_DEPS=1;;
    --build)    RUN_BUILD=1;;
    --check-only) CHECK_ONLY=1;;
    --fix-all)  ALL=1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
  shift
done
if [[ "$ALL" -eq 1 ]]; then
  FIX_CRLF=1; FIX_EXEC=1; FIX_GIT=1; FIX_DEPS=1; RUN_BUILD=1
fi

# -------- Utils ------------------------------
mkdir -p "$OUT_DIR"
: > "$LOG"

log() { printf "%s\n" "$*" | tee -a "$LOG"; }
section() { printf "\n== %s ==\n" "$*" | tee -a "$LOG"; }
have() { command -v "$1" >/dev/null 2>&1; }

normalize_file_lf() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if have dos2unix; then
    dos2unix -q "$f" || true
  else
    # Portable CR strip
    perl -i -pe 's/\r$//g' "$f"
  fi
  log "LF normalized: $f"
}

# -------- Env snapshot -----------------------
section "Environment snapshot"
{
  echo "PWD: $REPO_ROOT"
  echo "Date UTC: $(date -u)"
  echo "Node: $(node -v 2>/dev/null || echo 'missing')"
  echo "npm:  $(npm -v 2>/dev/null || echo 'missing')"
  echo "pnpm: $(pnpm -v 2>/dev/null || echo 'missing')"
  echo "yarn: $(yarn -v 2>/dev/null || echo 'missing')"
  echo "git:  $(git --version 2>/dev/null || echo 'missing')"
} | tee -a "$LOG"

# -------- CRLF → LF --------------------------
section "CRLF → LF audit"
if [[ "$FIX_CRLF" -eq 1 && "$CHECK_ONLY" -eq 0 ]]; then
  for f in "${CRLF_TARGETS[@]}"; do normalize_file_lf "$f"; done
else
  for f in "${CRLF_TARGETS[@]}"; do
    [[ -f "$f" ]] && if file "$f" | grep -qi 'CRLF'; then
      log "Would fix (add --fix-crlf): $f"
    fi
  done
fi

# -------- Shebang exec bits ------------------
section "Shebang (+x) audit in ${SCRIPTS_DIR}/"
if [[ -d "$SCRIPTS_DIR" ]]; then
  mapfile -d '' SHELL_SCRIPTS < <(grep -rlZ '^#!' -- "$SCRIPTS_DIR" || true)
  if ((${#SHELL_SCRIPTS[@]})); then
    for f in "${SHELL_SCRIPTS[@]}"; do
      if [[ "$FIX_EXEC" -eq 1 && "$CHECK_ONLY" -eq 0 ]]; then
        chmod +x "$f"
        log "chmod +x: $f"
      else
        [[ -x "$f" ]] || log "Would chmod +x (add --fix-exec): $f"
      fi
    done
  else
    log "No shebang'd files found under ${SCRIPTS_DIR}/"
  fi
else
  log "No scripts/ directory."
fi

# -------- Git LF policy ----------------------
section "Git LF policy (.gitattributes)"
WANTED='* text=auto eol=lf'
if [[ "$FIX_GIT" -eq 1 && "$CHECK_ONLY" -eq 0 ]]; then
  if [[ ! -f "$GATTR" ]] || ! grep -qxF "$WANTED" "$GATTR"; then
    printf "%s\n" "$WANTED" > "$GATTR"
    log "Wrote $GATTR → '$WANTED'"
  else
    log "$GATTR already enforces LF."
  fi
  git config core.autocrlf false || true
  log "git config core.autocrlf=false"
else
  if [[ -f "$GATTR" ]] && grep -qxF "$WANTED" "$GATTR"; then
    log ".gitattributes already enforces LF."
  else
    log "Would write LF policy (add --fix-git): $GATTR"
  fi
fi

# -------- NPM hygiene ------------------------
section "Package manager hygiene (npm-first)"
if [[ ! -f "$PKG_JSON" ]]; then
  log "No package.json found; skipping deps."
else
  if [[ "$FIX_DEPS" -eq 1 && "$CHECK_ONLY" -eq 0 ]]; then
    rm -f pnpm-lock.yaml yarn.lock
    log "Removed pnpm/yarn lockfiles if present."
    npm prune || true
    rm -rf node_modules
    log "Removed node_modules; running npm ci…"
    if ! npm ci | tee -a "$LOG"; then
      log "npm ci failed."; exit 1
    fi
  else
    [[ -f yarn.lock ]] && log "Would remove yarn.lock (add --fix-deps)"
    [[ -f pnpm-lock.yaml ]] && log "Would remove pnpm-lock.yaml (add --fix-deps)"
  fi
  (npm ls --depth=0 >/dev/null 2>&1) || true
  npm ls --depth=0 | sed -n '1,160p' | tee -a "$LOG" || true
fi

# -------- Tailwind v4 / PostCSS audit --------
section "Tailwind v4 / PostCSS double-processing audit"
TW_V=$(node -p "try{require('tailwindcss/package.json').version}catch{''}" 2>/dev/null || true)
POSTCSS_CFG=$(ls -1 postcss.config.* .postcssrc* 2>/dev/null || true)
HAS_TW_VITE=$(node -p "try{require.resolve('@tailwindcss/vite');1}catch{0}" 2>/dev/null || echo 0)
log "tailwindcss version: ${TW_V:-unknown}"
log "postcss config files: ${POSTCSS_CFG:-none}"
log "@tailwindcss/vite present: $HAS_TW_VITE"
if [[ "$HAS_TW_VITE" -eq 1 && -n "$POSTCSS_CFG" ]]; then
  log "Potential double-processing: Vite plugin + PostCSS config coexist."
  log "→ Choose one: keep @tailwindcss/vite (simpler) OR keep PostCSS (if you need plugins)."
fi
if [[ "$HAS_TW_VITE" -eq 0 && -z "$POSTCSS_CFG" ]]; then
  log "Tailwind v4 detected but neither PostCSS config nor @tailwindcss/vite found."
  log "→ Install @tailwindcss/vite OR add a postcss.config.js."
fi

# -------- Build + local trace ---------------
section "Build + Local Trace"
if [[ "$RUN_BUILD" -eq 1 ]]; then
  : > "$TRACE_ERR"

  # Always run CLI under Node using npm exec (prevents bash mis-parsing)
  set -x
  npm exec -- astro build --verbose 2> "$TRACE_ERR" || true
  { set +x; } 2>/dev/null

  log "Local trace captured: $TRACE_ERR"
  tail -n 200 "$TRACE_ERR" | tee -a "$LOG" >/dev/null || true

  : > "$WARNINGS"
  grep -iE "warn|deprec|ignored|fallback|prerender|no adapter|couldn.?t resolve" "$TRACE_ERR" \
    | sed -e 's/^[[:space:]]*//g' | sort -u | tee "$WARNINGS" >/dev/null || true
  log "Warnings extracted → $WARNINGS (top 50 below)"
  sed -n '1,50p' "$WARNINGS" | tee -a "$LOG" >/dev/null || true
else
  log "Skipping build (add --build or --fix-all)."
fi

# -------- Output verification ----------------
section "Output verification (dist/, Netlify SSR)"
if [[ -d "dist" ]]; then
  log "dist/ exists:"
  ls -la dist | sed -n '1,40p' | tee -a "$LOG" >/dev/null || true
else
  log "dist/ missing (build may have failed or project is SSR-only)."
fi
MANIFEST=$(ls -1 .netlify/build/manifest_*.mjs 2>/dev/null || true)
if [[ -n "$MANIFEST" ]]; then
  log "Netlify SSR manifest present: $(basename "$MANIFEST")"
else
  if [[ -d ".netlify/build" ]]; then
    log "Netlify build dir exists but manifest not found."
  else
    log ".netlify/build missing (adapter absent or SSG-only build)."
  fi
fi

# -------- Final summary ----------------------
section "Summary"
{
  echo "Log:        $LOG"
  [[ -f "$TRACE_ERR" ]] && echo "Trace:      $TRACE_ERR"
  [[ -f "$WARNINGS" ]] && echo "Warnings:   $WARNINGS"
  echo "Actions:"
  [[ "$FIX_CRLF" -eq 1 && "$CHECK_ONLY" -eq 0 ]] && echo " - CRLF→LF normalization applied"
  [[ "$FIX_EXEC" -eq 1 && "$CHECK_ONLY" -eq 0 ]] && echo " - Shebang exec bits (+x) applied in scripts/"
  [[ "$FIX_GIT"  -eq 1 && "$CHECK_ONLY" -eq 0 ]] && echo " - .gitattributes set to enforce LF; core.autocrlf=false"
  [[ "$FIX_DEPS" -eq 1 && "$CHECK_ONLY" -eq 0 ]] && echo " - npm prune + npm ci executed; removed other lockfiles"
  [[ "$RUN_BUILD" -eq 1 ]] && echo " - Build ran via npm exec; warnings extracted"
  [[ "$CHECK_ONLY" -eq 1 ]] && echo " - CHECK-ONLY: no changes were made"
} | tee -a "$LOG"

exit 0
