#!/usr/bin/env bash
# code_quality.sh — dead code signals, duplication, long functions, magic numbers (static, heuristic)
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/code_quality.json"
mkdir -p "$REPORT_DIR"

# thresholds
LONG_LINE="${LONG_LINE:-160}"          # characters

scan() {
  local todos=0 long_lines=0 magic_numbers=0 duplication=0

  todos=$(( $(grep -RIn --binary-files=without-match -E 'TODO|FIXME|HACK' src 2>/dev/null | wc -l | tr -d ' ') ))
  magic_numbers=$(( $(grep -RIn --binary-files=without-match -E '\b[0-9]{3,}\b' src 2>/dev/null | wc -l | tr -d ' ') ))

  # Long lines: count lines > LONG_LINE across source files
  long_lines=0
  while IFS= read -r -d '' f; do
    cnt=$(awk -v n="$LONG_LINE" 'length($0)>n{c++} END{print c+0}' "$f")
    long_lines=$(( long_lines + cnt ))
  done < <(find src -type f -name '*.*' -print0 2>/dev/null)

  # Dup heuristic: identical 40+ char lines occurring 3+ times across repo
  duplication=$(( $(grep -Rho --binary-files=without-match -E '.{40,}' src 2>/dev/null | sort | uniq -c | awk '$1>=3{c+=1} END{print c+0}') ))

  local issues=$(( todos + long_lines + magic_numbers + duplication ))
  local status="pass"; [[ $issues -gt 0 ]] && status="warn"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "code_quality",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "todos": $todos,
    "long_lines": $long_lines,
    "magic_numbers": $magic_numbers,
    "duplication_hints": $duplication
  },
  "actions": [
    "Convert TODO/FIXME to tracked issues; pay down in batches",
    "Split long lines; refactor long modules/functions",
    "Extract magic numbers to named constants",
    "Deduplicate helpers; share utilities across packages"
  ],
  "policy_invariants": [],
  "eta_minutes": 20,
  "unlocks": ["performance","accessibility"]
}
JSON
}

scan "."
