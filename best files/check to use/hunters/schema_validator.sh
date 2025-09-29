#!/usr/bin/env bash
# schema_validator.sh — Ensures all hunter JSON reports conform to unified schema contract
# Exit codes: 0 pass, 1 warnings (minor drift), 2 critical (missing required keys)

set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/schema_validator.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed — skipping schema validation (warn)" >&2
  cat > "$REPORT_FILE" <<EOF
{ "module":"schema_validator","status":"warn","warning_issues":1,"critical_issues":0,"notes":"jq missing" }
EOF
  exit 1
fi

required_keys=(module timestamp status critical_issues warning_issues findings recommendations upstream_analysis issues_total policy_invariants)
critical_issues=0; warning_issues=0
declare -a problems

AUTOFIX=${SCHEMA_AUTOFIX:-0}

for f in "$REPORT_DIR"/*.json; do
  [[ "$(basename "$f")" == "master.json" ]] && continue
  [[ -s "$f" ]] || { problems+=("empty:$f"); ((critical_issues++)); continue; }
  for k in "${required_keys[@]}"; do
    if ! jq -e ". | has(\"$k\")" "$f" >/dev/null; then
      problems+=("missing:$f:$k")
      if [[ "$k" =~ ^(module|status|critical_issues|warning_issues)$ ]]; then
        ((critical_issues++))
      else
        ((warning_issues++))
      fi
      if (( AUTOFIX == 1 )); then
        case "$k" in
          issues_total) jq '.issues_total=(.critical_issues//0 + .warning_issues//0)' "$f" > "$f.tmp" && mv "$f.tmp" "$f";;
          findings) jq '.findings={}' "$f" > "$f.tmp" && mv "$f.tmp" "$f";;
          recommendations) jq '.recommendations=[]' "$f" > "$f.tmp" && mv "$f.tmp" "$f";;
          upstream_analysis) jq '.upstream_analysis={"box":"","closet":"","policy":""}' "$f" > "$f.tmp" && mv "$f.tmp" "$f";;
          policy_invariants) jq '.policy_invariants=[]' "$f" > "$f.tmp" && mv "$f.tmp" "$f";;
          *) :;;
        esac
      fi
    fi
  done
  # Backfill issues_total if absent
  if ! jq -e '. | has("issues_total")' "$f" >/dev/null; then
    total=$(jq '(.critical_issues // 0)+(.warning_issues // 0)' "$f")
    jq --argjson total "$total" '.issues_total=$total' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    ((warning_issues++))
    problems+=("added:issues_total:$f")
  fi
done

status="pass"; exit_code=0
(( critical_issues > 0 )) && { status="critical"; exit_code=2; } || (( warning_issues > 0 )) && { status="warn"; exit_code=1; }

problems_json=$(printf '%s\n' "${problems[@]}" | jq -R . | jq -s .)
cat > "$REPORT_FILE" <<EOF
{
  "module": "schema_validator",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$status",
  "critical_issues": $critical_issues,
  "warning_issues": $warning_issues,
  "issues_total": $((critical_issues+warning_issues)),
  "findings": {"problems": $problems_json},
  "recommendations": ["Normalize hunter reports to include unified keys","Adopt _common.sh helpers", "Run with SCHEMA_AUTOFIX=1 to patch missing fields"],
  "upstream_analysis": {"box":"Report schema drift","closet":"Inconsistent hunter implementations","policy":"Centralize shared report helpers + enforce via validator"},
  "policy_invariants": ["all_reports_have_required_keys"]
}
EOF

echo "schema_validator: $status (crit=$critical_issues warn=$warning_issues)" >&2
exit $exit_code
