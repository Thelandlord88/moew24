#!/usr/bin/env bash
# debug-exit1.sh
# Purpose: Wrap a failing command, capture why it exits with code 1,
# and produce a thorough, timestamped diagnostics bundle.

set -Eeuo pipefail

#############################################
#               CONFIG
#############################################
DEBUG_DIR_BASE=".debug-exit1"
TIMESTAMP="$(date +'%Y%m%d-%H%M%S')"
RUN_DIR="${DEBUG_DIR_BASE}/run-${TIMESTAMP}"
LOG="${RUN_DIR}/debug.log"
TRACE_LOG="${RUN_DIR}/trace.log"
ENV_SNAPSHOT="${RUN_DIR}/env.txt"
SYS_SNAPSHOT="${RUN_DIR}/system.txt"
PKG_SNAPSHOT="${RUN_DIR}/package.json.snapshot"
NPM_LS_LOG="${RUN_DIR}/npm-ls.log"
PNPM_LS_LOG="${RUN_DIR}/pnpm-ls.log"
YARN_LS_LOG="${RUN_DIR}/yarn-ls.log"
GIT_STATUS_LOG="${RUN_DIR}/git-status.log"
FILE_ISSUES_LOG="${RUN_DIR}/file-issues.log"
SUSPECTS_LOG="${RUN_DIR}/suspects.log"
SHELLCHECK_LOG="${RUN_DIR}/shellcheck.log"
SUMMARY="${RUN_DIR}/SUMMARY.txt"

mkdir -p "${RUN_DIR}"

# Pretty printing helpers
hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' - ; }
say() { printf "[debug-exit1] %s\n" "$*" | tee -a "${LOG}"; }
error() { printf "[debug-exit1:ERROR] %s\n" "$*" | tee -a "${LOG}" >&2; }

#############################################
#               USAGE
#############################################
if [[ "${1:-}" != "--" ]]; then
  cat <<'HELP'
Usage:
  ./debug-exit1.sh -- <your command and args>

Examples:
  ./debug-exit1.sh -- npm run build
  ./debug-exit1.sh -- bash scripts/deploy.sh --flag
  ./debug-exit1.sh -- ./scripts/my-task.mjs

This tool:
  • Snapshots environment, PATH, Node/npm/pnpm/yarn, git status, disk, ulimit, etc.
  • Scans for common causes (CRLF, bad shebang, non-executable files, missing deps).
  • Re-runs your command with xtrace to capture the exact failing line.
  • Produces a human-readable SUMMARY with likely root causes.
HELP
  exit 64
fi
shift # remove --

#############################################
#           GENERIC REQUIREMENTS
#############################################
has() { command -v "$1" >/dev/null 2>&1; }

require_dir_writable() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || true
  fi
  if ! test -w "$dir"; then
    error "Directory not writable: $dir"
  fi
}

require_dir_writable "${DEBUG_DIR_BASE}"
require_dir_writable "${RUN_DIR}"

#############################################
#           SNAPSHOT: ENV & SYSTEM
#############################################
{
  hr
  echo "TIME:        $(date -Is)"
  echo "PWD:         $(pwd)"
  echo "SHELL:       ${SHELL:-unknown}"
  echo "BASH:        ${BASH:-n/a} (version: ${BASH_VERSION:-n/a})"
  echo "USER:        $(id -un) ($(id -u))"
  echo "GROUP:       $(id -gn) ($(id -g))"
  echo "UMASK:       $(umask)"
  echo "PATH:        $PATH"
  echo "HOME:        $HOME"
  echo "TMPDIR:      ${TMPDIR:-/tmp}"
  echo
  echo "ULIMITS:"
  ulimit -a 2>&1 || true
  echo
  echo "DISK (df -h .):"
  df -h . 2>&1 || true
  echo
  echo "OS VERSION:"
  if has lsb_release; then lsb_release -a 2>&1 || true; fi
  if [[ -f /etc/os-release ]]; then cat /etc/os-release; fi
  uname -a
  echo
  echo "LOCALE:"
  locale 2>&1 || true
  echo
  echo "ENV (sorted):"
  env | sort
} > "${ENV_SNAPSHOT}"

{
  echo "WHICH interpreters & package managers:"
  for bin in bash sh zsh node npm pnpm yarn corepack git python python3 dos2unix shellcheck perl ruby deno bun; do
    printf " - %-10s " "$bin"
    if has "$bin"; then
      printf "%s\n" "$(command -v "$bin")"
    else
      printf "NOT FOUND\n"
    fi
  done
  echo
  echo "VERSIONS:"
  has node && node -v || true
  has npm && npm -v || true
  has pnpm && pnpm -v || true
  has yarn && yarn -v || true
  has corepack && corepack -v || true
  has git && git --version || true
  has bash && bash --version | head -n 1 || true
} > "${SYS_SNAPSHOT}"

#############################################
#           PROJECT SNAPSHOTS
#############################################
if [[ -f package.json ]]; then
  cp package.json "${PKG_SNAPSHOT}" || true
  if has npm; then
    (npm ls --depth=0 || true) &> "${NPM_LS_LOG}"
  fi
  if has pnpm; then
    (pnpm ls --depth=0 || true) &> "${PNPM_LS_LOG}"
  fi
  if has yarn; then
    (yarn list --depth=0 || true) &> "${YARN_LS_LOG}"
  fi
fi

if has git; then
  {
    echo "GIT STATUS:"
    git status -sb 2>&1 || true
    echo
    echo "RECENT COMMITS:"
    git --no-pager log --oneline -n 20 2>&1 || true
    echo
    echo "UNTRACKED/IGNORED CHECKS:"
    git ls-files -o --exclude-standard | sed 's/^/  U: /'
  # Some git versions require -i to be paired with -o or -c; use -o to list ignored others
  git ls-files -i -o --exclude-standard | sed 's/^/  I: /'
  } > "${GIT_STATUS_LOG}"
fi

#############################################
#           COMMON FILE/LINE-ENDING ISSUES
#############################################
detect_crlf() {
  # scan shell scripts and top-level scripts for CRLF
  echo "Scanning for CRLF and executable bit issues..." | tee -a "${LOG}"
  {
    echo "---- CRLF & perms scan ----"
    mapfile -t CANDIDATES < <(git ls-files 2>/dev/null || printf "%s\n" *)
    for f in "${CANDIDATES[@]}"; do
      [[ -f "$f" ]] || continue
      case "$f" in
        *.sh|*.bash|*.zsh|*.mjs|*.cjs|*.js|*.ts|scripts/*|bin/*)
          # CRLF?
          if grep -qU $'\r' "$f" 2>/dev/null; then
            echo "[CRLF] $f"
          fi
          # Executable expectation in bin/scripts
          if [[ "$f" == bin/* || "$f" == scripts/* ]]; then
            if head -n1 "$f" | grep -Eq '^#!'; then
              if [[ ! -x "$f" ]]; then
                echo "[NO+X] $f has shebang but is not executable (chmod +x suggested)"
              fi
            fi
          fi
          # Bad shebang?
          if head -n1 "$f" | grep -Eq '^#!'; then
            # ensure interpreter exists
            interp="$(head -n1 "$f" | sed 's/^#![ ]*//')"
            if [[ "$interp" == "/usr/bin/env"* ]]; then
              cmd="$(echo "$interp" | awk '{print $3}')"
              # e.g. #!/usr/bin/env bash => cmd = bash
              if [[ -n "$cmd" ]] && ! has "$cmd"; then
                echo "[BAD-SHEBANG] $f -> interpreter '$cmd' not found on PATH"
              fi
            else
              # absolute path
              if [[ ! -x "${interp%% *}" ]]; then
                echo "[BAD-SHEBANG] $f -> interpreter '${interp}' not executable/present"
              fi
            fi
          fi
        ;;
      esac
    done
  } > "${FILE_ISSUES_LOG}"
}
detect_crlf

#############################################
#           OPTIONAL SHELLCHECK
#############################################
if has shellcheck; then
  {
    echo "shellcheck on *.sh and scripts/* ..."
    mapfile -t SHFILES < <(git ls-files '*.sh' 2>/dev/null; ls scripts/*.sh 2>/dev/null || true)
    for f in "${SHFILES[@]}"; do
      [[ -f "$f" ]] || continue
      echo "---- $f ----"
      shellcheck -x "$f" || true
      echo
    done
  } > "${SHELLCHECK_LOG}"
fi

#############################################
#           SMART HINTS ENGINE
#############################################
generate_suspects() {
  {
    echo "Likely culprits and checks (auto-generated):"
    echo
    # 1) File issues
    if grep -q '\[CRLF\]' "${FILE_ISSUES_LOG}" 2>/dev/null; then
      echo "• Windows CRLF line endings detected. Run 'dos2unix' on the listed files or set git config:"
      echo "    git config core.autocrlf false"
      echo "    git rm --cached -r . && git reset --hard"
      echo "  Then re-run the task."
      echo
    fi
    if grep -q '\[NO\+X\]' "${FILE_ISSUES_LOG}" 2>/dev/null; then
      echo "• Script(s) with shebang lack executable bit. Fix with:"
      echo "    xargs -0 chmod +x < <(grep -lZ '\\#!/' scripts/* bin/* 2>/dev/null || true)"
      echo
    fi
    if grep -q '\[BAD-SHEBANG\]' "${FILE_ISSUES_LOG}" 2>/dev/null; then
      echo "• Bad shebang or missing interpreter on PATH. Ensure /usr/bin/env bash (or node, python) exists."
      echo
    fi

    # 2) Node toolchain mismatch
    if [[ -f package.json ]]; then
      echo "• Node/PM sanity:"
      echo "  - Verify Node version matches .nvmrc or engines field."
      echo "  - If using pnpm/yarn, ensure lockfile matches (pnpm-lock.yaml / yarn.lock vs package-lock.json)."
      echo
      echo "• If the failure mentions PostCSS/Tailwind:"
      echo "  - Avoid double-processing Tailwind (choose vite plugin OR postcss, not both)."
      echo "  - Remove stray postcss.config.* if using @tailwindcss/vite only."
      echo
      echo "• If the failure mentions Astro SSR/hybrid builds:"
      echo "  - Ensure astro.config has output: 'server' or 'hybrid' and a valid adapter."
      echo "  - Mark dynamic routes with 'export const prerender = false'."
      echo
    fi

    # 3) Permissions / Disk / PATH
    echo "• Check disk space (df -h) and TMPDIR perms if builds write to /tmp."
    echo "• Ensure the command’s first token exists and is executable (PATH issues)."
    echo

    # 4) Git ignore / missing files
    echo "• Sometimes CI fails because required files are .gitignored. Confirm required inputs exist."
    echo

    echo "• To re-run with local, verbose trace:"
    echo "    bash -x -euo pipefail <your-script>.sh 2> trace.err"
  } > "${SUSPECTS_LOG}"
}
generate_suspects

#############################################
#           RUN THE TARGET COMMAND
#############################################
TARGET_CMD=("$@")
say "Running command: ${TARGET_CMD[*]}"
EXIT_CODE=0

# 1st pass: normal run (capture stderr/stdout)
{
  set +e
  "${TARGET_CMD[@]}"
  EXIT_CODE=$?
  set -e
} &> "${RUN_DIR}/command.log"

# Collect quick pattern hints from log
collect_patterns() {
  grep -Ei 'error|not found|permission denied|no such file|module not found|stack trace|traceback|EADDRINUSE|EACCES|EEXIST|ERR_|TypeError|SyntaxError|ReferenceError|node:internal' \
    "${RUN_DIR}/command.log" 2>/dev/null | sed -e 's/^/  > /' | head -n 200 > "${RUN_DIR}/quick-hints.txt" || true
}
collect_patterns

if [[ $EXIT_CODE -ne 0 ]]; then
  say "Command failed with code: ${EXIT_CODE}. Retrying with xtrace..."
  # 2nd pass: xtrace
  {
    set +e
    # run in a subshell with xtrace so we capture expanded lines
    (
      set -x
      set -euo pipefail
      "${TARGET_CMD[@]}"
    )
    EXIT_CODE=$?
    set -e
  } &> "${TRACE_LOG}" || true
else
  say "Command succeeded (exit 0). This suggests the error may be intermittent/env-specific."
fi

#############################################
#           SUMMARY & NEXT STEPS
#############################################
{
  echo "Command: ${TARGET_CMD[*]}"
  echo "Exit code: ${EXIT_CODE}"
  echo
  echo "Artifacts:"
  echo "  - ${ENV_SNAPSHOT}     (env, PATH, limits, disk)"
  echo "  - ${SYS_SNAPSHOT}     (tool versions, interpreters)"
  [[ -f "${PKG_SNAPSHOT}" ]] && echo "  - ${PKG_SNAPSHOT} (package.json snapshot)"
  [[ -f "${NPM_LS_LOG}" ]] && echo "  - ${NPM_LS_LOG} (npm ls --depth=0)"
  [[ -f "${PNPM_LS_LOG}" ]] && echo "  - ${PNPM_LS_LOG} (pnpm ls --depth=0)"
  [[ -f "${YARN_LS_LOG}" ]] && echo "  - ${YARN_LS_LOG} (yarn list --depth=0)"
  [[ -f "${GIT_STATUS_LOG}" ]] && echo "  - ${GIT_STATUS_LOG} (git status/log)"
  echo "  - ${RUN_DIR}/command.log (first run log)"
  echo "  - ${TRACE_LOG}          (xtrace re-run)"
  echo "  - ${FILE_ISSUES_LOG}    (CRLF, perms, shebang)"
  [[ -f "${SHELLCHECK_LOG}" ]] && echo "  - ${SHELLCHECK_LOG} (shellcheck results)"
  echo "  - ${SUSPECTS_LOG}       (auto-generated hints)"
  [[ -f "${RUN_DIR}/quick-hints.txt" ]] && echo "  - ${RUN_DIR}/quick-hints.txt (error snippets)"
  echo
  echo "Top hints:"
  echo "---------"
  if [[ -s ${RUN_DIR}/quick-hints.txt ]]; then
    head -n 50 "${RUN_DIR}/quick-hints.txt"
  else
    echo "  (No obvious strings found; inspect ${TRACE_LOG} for the failing line.)"
  fi
  echo
  echo "Next steps:"
  echo "  1) Open ${TRACE_LOG} and jump to the final lines to see the exact failing command."
  echo "  2) Check ${FILE_ISSUES_LOG} for CRLF/perms/shebang issues and fix accordingly."
  echo "  3) If Node project, ensure one package manager, a single lockfile, and correct Node version."
  echo "  4) Re-run your command directly with:"
  echo "       bash -x -euo pipefail <script>.sh 2> local-trace.err"
  echo "  5) Commit minimal fixes; run again via this tool to confirm resolution."
} > "${SUMMARY}"

say "Diagnostics complete."
say "See: ${SUMMARY}"
exit "${EXIT_CODE}"
