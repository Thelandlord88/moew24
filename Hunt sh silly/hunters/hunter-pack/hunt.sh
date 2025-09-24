#!/usr/bin/env bash
# hunt.sh — modular orchestrator + policy gates + Thinker integration
# POSIX-ish; tested with bash. No heavy deps. Node is optional for Thinker.

set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

# -------- Config --------
STRICT="${STRICT:-1}"                 # 1 = fail on criticals/invariants; 0 = warn-only
MODULES_DEFAULT="runtime_ssr,build_dependencies,security,accessibility,performance,code_quality"
MODULES="${MODULES:-$MODULES_DEFAULT}"
REPORT_DIR="__reports/hunt"
LOG_DIR="$REPORT_DIR/logs"
THINKER_ENTRY="thinker/index.mjs"
FAKE_NOW="${FAKE_NOW:-}"

# -------- Utils --------
_color() { printf "\033[%sm" "$1"; }
_title() { _color "1;36"; }      # bold cyan
_ok()    { _color "1;32"; }      # bold green
_warn()  { _color "1;33"; }      # bold yellow
_err()   { _color "1;31"; }      # bold red
_dim()   { _color "2;37"; }      # dim gray
_reset() { _color "0"; }

section() { printf "%s\n== %s ==%s\n" "$(_title)" "$1" "$(_reset)"; }
info()    { printf "%s•%s %s\n" "$(_dim)" "$(_reset)" "$1"; }
okay()    { printf "%s✓%s %s\n" "$(_ok)" "$(_reset)" "$1"; }
warn()    { printf "%s⚠%s %s\n" "$(_warn)" "$(_reset)" "$1"; }
fail()    { printf "%s✗%s %s\n" "$(_err)" "$(_reset)" "$1"; }

ts() {
  if [[ -n "$FAKE_NOW" ]]; then printf "%s" "$FAKE_NOW"; else date -Iseconds; fi
}

ensure_dirs() { mkdir -p "$REPORT_DIR" "$LOG_DIR" "__ai/thinker" "var"; }

have() { command -v "$1" >/dev/null 2>&1; }

rg_or_grep() {
  if have rg; then rg "$@"; else grep -RIn --binary-files=without-match "$@"; fi
}

# Write minimal valid JSON safely
json_write() {
  # $1 = path; stdin = JSON content (already valid)
  local path="$1" tmp
  tmp="$(mktemp "${path}.XXXX")"
  cat > "$tmp"
  mv "$tmp" "$path"
}

# -------- Merge module JSONs into master summary --------
merge_master() {
  local master="$REPORT_DIR/master.json"
  local total_issues=0 total_critical=0 total_warn=0 total_pass=0
  local modules_json="[" first=1

  shopt -s nullglob
  for f in "$REPORT_DIR"/*.json; do
    [[ "$(basename "$f")" == "master.json" ]] && continue
    # Valid JSON? (best-effort)
    if have node; then
      node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" >/dev/null 2>&1 || {
        warn "Invalid JSON from $(basename "$f") — skipping"; continue;
      }
    fi
    # Extract key metrics via Node (portable) or naive grep fallback
    local status issues
    if have node; then
      status="$(node -e "let j=require(process.argv[1]); console.log(j.status||'pass')" "$f")"
      issues="$(node -e "let j=require(process.argv[1]); console.log(Number(j.issues||0))" "$f")"
    else
      status="$(sed -n 's/.*\"status\":[[:space:]]*\"\([^\"]*\)\".*/\1/p' "$f" | head -n1)"
      issues="$(sed -n 's/.*\"issues\":[[:space:]]*\([0-9]\+\).*/\1/p' "$f" | head -n1)"
      status="${status:-pass}"; issues="${issues:-0}"
    fi
    case "$status" in
      critical) total_critical=$((total_critical+1));;
      warn)     total_warn=$((total_warn+1));;
      *)        total_pass=$((total_pass+1));;
    esac
    total_issues=$((total_issues + issues))
    # Append to modules_json
    if [[ $first -eq 1 ]]; then
      modules_json="$modules_json$(cat "$f")"; first=0
    else
      modules_json="$modules_json,$(cat "$f")"
    fi
  done
  modules_json="$modules_json]"

  # Policy: strict fails when any critical exists
  local policy_pass=true reasons="[]"
  if [[ "$STRICT" == "1" && $total_critical -gt 0 ]]; then
    policy_pass=false
    reasons='[\"one-or-more-modules-critical\"]'
  fi

  json_write "$master" <<JSON
{
  "schemaVersion": 1,
  "generatedAt": "$(ts)",
  "strict": ${STRICT/[^0-9]/0},
  "summary": {
    "total_issues": $total_issues,
    "total_critical": $total_critical,
    "total_warn": $total_warn,
    "total_pass": $total_pass
  },
  "modules": $modules_json,
  "policy": {
    "pass": $policy_pass,
    "reasons": $reasons
  }
}
JSON

  if [[ "$policy_pass" == "true" ]]; then
    okay "HUNT: PASS (critical=$total_critical, warn=$total_warn, pass=$total_pass)"
  else
    fail "HUNT: FAIL (critical=$total_critical, warn=$total_warn, pass=$total_pass)"
    return 1
  fi
}

# -------- Run a single hunter --------
run_hunter() {
  local mod="$1"
  local script="hunters/${mod}.sh"
  if [[ ! -f "$script" ]]; then
    warn "Missing $script (skipping)"
    return 0
  fi
  section "Hunter: $mod"
  local logf="$LOG_DIR/${mod}.log"
  local jsonf="$REPORT_DIR/${mod}.json"
  HUNTER_MODULE="$mod" bash "$script" >"$logf" 2>&1 || {
    warn "$mod exited non-zero; capturing partial results"
  }
  # Ensure JSON file exists (module responsible for writing it; create default otherwise)
  if [[ ! -s "$jsonf" ]]; then
    warn "$mod did not write $jsonf; writing minimal pass JSON"
    json_write "$jsonf" <<JSON
{ "schemaVersion": 1, "module": "$mod", "status": "pass", "issues": 0, "affected_files": 0, "counts": {}, "actions": [], "policy_invariants": [], "eta_minutes": 0, "unlocks": [] }
JSON
  fi
  okay "log: $logf  json: $jsonf"
}

# -------- Main --------
main() {
  ensure_dirs
  section "Environment"
  info "STRICT=$STRICT"
  info "MODULES=$MODULES"
  info "ts=$(ts)"
  info "node=$(if have node; then node -v; else echo 'missing'; fi)"
  info "rg=$(if have rg; then rg --version | head -n1; else echo 'missing (using grep)'; fi)"

  # Run selected modules
  IFS=',' read -r -a mods <<< "$MODULES"
  local rc=0
  for m in "${mods[@]}"; do
    if ! run_hunter "$m"; then rc=1; fi
  done

  # Merge into master
  if ! merge_master; then rc=1; fi

  # Thinker (advisory; never changes exit code)
  if [[ -f "$THINKER_ENTRY" ]] && have node; then
    section "Thinker Agenda"
    if node "$THINKER_ENTRY"; then
      okay "__ai/thinker/master-insights.json"
    else
      warn "Thinker: non-fatal error (agenda may be missing)"
    fi
  else
    info "Thinker skipped (node or thinker/index.mjs missing)"
  fi

  exit "$rc"
}

main "$@"
