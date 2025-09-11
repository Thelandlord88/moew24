#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Troubleshoot Repo – Astro + Netlify + Tailwind v4
# - CRLF → LF normalization (config + known hotspots)
# - Shebang scripts ⇒ +x
# - Git LF enforcement (.gitattributes)
# - Package manager hygiene (npm-only by default)
# - Tailwind v4 double-processing audit (PostCSS vs Vite)
# - Build with local trace; extract warnings
# - Verify dist/ and Netlify SSR outputs
# ============================================

# -------- Configurable defaults --------------
REPO_ROOT="${REPO_ROOT:-$(pwd)}"
RUN_DIR="${REPO_ROOT}/.debug-exit1"
OUT_DIR="${RUN_DIR}/fix-$(date -u +%Y%m%d-%H%M%S)"
LOG="${OUT_DIR}/troubleshoot.log"
TRACE_ERR="${OUT_DIR}/local-trace.err"
WARNINGS="${OUT_DIR}/warnings.txt"
CRLF_TARGETS=(
  "astro.config.mjs"
  "tailwind.config.js"
  "src/utils/math.js"
  "src/utils/schemamanager.js"
  "src/utils/slugify.js"
  "src/utils/slugify.test.js"
)
SCRIPTS_DIR="scripts"
PKG_JSON="${REPO_ROOT}/package.json"

# -------- CLI flags --------------------------
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
  --build       Run Astro build with local trace and warnings extraction
  --check-only  Do not modify anything; just report
  --fix-all     Do everything above

Examples:
  bash scripts/troubleshoot-repo.sh --fix-all
  bash scripts/troubleshoot-repo.sh --fix-crlf --fix-exec --build
EOF
}

log() { printf "%s\n" "$*" | tee -a "$LOG" ; }
section() { printf "\n== %s ==\n" "$*" | tee -a "$LOG" ; }

mkdir -p "$OUT_DIR"
: > "$LOG"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix-crlf) FIX_CRLF=1 ;;
    --fix-exec) FIX_EXEC=1 ;;
    --fix-git)  FIX_GIT=1 ;;
    --fix-deps) FIX_DEPS=1 ;;
    --build)    RUN_BUILD=1 ;;
    --check-only) CHECK_ONLY=1 ;;
    --fix-all)  ALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) log "Unknown arg: $1"; usage; exit 2 ;;
  esac
  shift
done

if [[ "$ALL" -eq 1 ]]; then
  FIX_CRLF=1; FIX_EXEC=1; FIX_GIT=1; FIX_DEPS=1; RUN_BUILD=1
fi

# -------- Helpers ----------------------------
have() { command -v "$1" >/dev/null 2>&1; }

normalize_file_lf() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if have dos2unix; then
    dos2unix -q "$f" || true
  else
    # portable: strip CRs
    perl -i -pe 's/\r$//g' "$f"
  fi
  log "LF normalized: $f"
}

# -------- Environment snapshot ---------------
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
if [[ "$FIX_CRLF" -eq 1 ]]; then
  for f in "${CRLF_TARGETS[@]}"; do
    normalize_file_lf "$f"
  done
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
      if [[ "$FIX_EXEC" -eq 1 ]]; then
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
GATTR="${REPO_ROOT}/.gitattributes"
WANTED='* text=auto eol=lf'
if [[ "$FIX_GIT" -eq 1 ]]; then
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
    log ".gitattributes OK"
  else
    log "Would write LF policy (add --fix-git): $GATTR"
  fi
fi

# -------- Package manager hygiene ------------
section "Package manager hygiene (npm-first)"
if [[ ! -f "$PKG_JSON" ]]; then
  log "No package.json found; skipping deps."
else
  if [[ "$FIX_DEPS" -eq 1 ]]; then
    rm -f pnpm-lock.yaml yarn.lock
    log "Removed pnpm/yarn lockfiles if present."
    npm prune || true
    rm -rf node_modules
    log "Removed node_modules; running npm ci…"
    if ! npm ci | tee -a "$LOG"; then
      log "npm ci failed."
      exit 1
    fi
  else
    [[ -f yarn.lock ]] && log "Would remove yarn.lock (add --fix-deps)"
    [[ -f pnpm-lock.yaml ]] && log "Would remove pnpm-lock.yaml (add --fix-deps)"
  fi

  # Extraneous check
  (npm ls --depth=0 >/dev/null 2>&1) || true
  npm ls --depth=0 | sed -n '1,150p' | tee -a "$LOG" || true
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
  log "If you don't need PostCSS transforms, remove postcss + nesting."
fi

# -------- Build + local trace ----------------
section "Build + Local Trace"
if [[ "$RUN_BUILD" -eq 1 ]]; then
  : > "$TRACE_ERR"
  if [[ -f "$REPO_ROOT/node_modules/.bin/astro" ]]; then
    ( set -x
      bash -x -euo pipefail "$REPO_ROOT/node_modules/.bin/astro" build 2> "$TRACE_ERR"
    ) || true
    log "Local trace captured: $TRACE_ERR"
    tail -n 200 "$TRACE_ERR" | tee -a "$LOG" >/dev/null || true

    # Extract warnings
    : > "$WARNINGS"
    grep -iE "warn|deprec|ignored|fallback|prerender|no adapter|couldn.?t resolve" "$TRACE_ERR" \
      | sed -e 's/^[[:space:]]*//g' | sort -u | tee "$WARNINGS" >/dev/null || true
    log "Warnings extracted → $WARNINGS (top 50 below)"
    sed -n '1,50p' "$WARNINGS" | tee -a "$LOG" >/dev/null || true
  else
    log "Astro not found; run npm ci first or add --fix-deps."
  fi
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
    log ".netlify/build missing (adapter may be absent or SSG-only build)."
  fi
fi

# -------- Final summary ----------------------
section "Summary"
{
  echo "Log:        $LOG"
  [[ -f "$TRACE_ERR" ]] && echo "Trace:      $TRACE_ERR"
  [[ -f "$WARNINGS" ]] && echo "Warnings:   $WARNINGS"
  echo "Actions:"
  [[ "$FIX_CRLF" -eq 1 ]] && echo " - CRLF→LF normalization applied"
  [[ "$FIX_EXEC" -eq 1 ]] && echo " - Shebang exec bits (+x) applied in scripts/"
  [[ "$FIX_GIT"  -eq 1 ]] && echo " - .gitattributes set to enforce LF; core.autocrlf=false"
  [[ "$FIX_DEPS" -eq 1 ]] && echo " - npm prune + npm ci executed; removed other lockfiles"
  [[ "$RUN_BUILD" -eq 1 ]] && echo " - Build ran with bash -x; warnings extracted"
  [[ "$CHECK_ONLY" -eq 1 ]] && echo " - CHECK-ONLY: no changes were made"
} | tee -a "$LOG"

exit 0
