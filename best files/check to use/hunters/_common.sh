#!/usr/bin/env bash
# _common.sh — Shared utilities for Hunter modules
# Provides: init_report, update_report_kv, append_array, finalize_report_status
# Keeps backward compatibility with existing per-hunter custom fields.

set -euo pipefail

ensure_dir() { mkdir -p "${REPORT_DIR:-__reports/hunt}"; }
timestamp_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# init_report <module>
init_report() {
  ensure_dir
  local mod="$1"; local path="${REPORT_DIR:-__reports/hunt}/${mod}.json";
  cat > "$path" <<EOF
{
  "module": "$mod",
  "schema_version": 1,
  "timestamp": "$(timestamp_utc)",
  "status": "running",
  "critical_issues": 0,
  "warning_issues": 0,
  "issues_total": 0,
  "findings": {},
  "upstream_analysis": {"box":"","closet":"","policy":""},
  "recommendations": [],
  "policy_invariants": []
}
EOF
  echo "$path"
}

# update_report_kv <path> <jq expression>
update_report_kv() {
  local path="$1"; shift
  tmp="${path}.tmp"; jq -S "$@" "$path" > "$tmp" && mv "$tmp" "$path"
}

# append_array <path> <json_array_field> <string_item>
append_array() {
  local path="$1" field="$2" item="$3"; update_report_kv "$path" ".${field} += [\"${item//\"/\\\"}\"]";
}

# finalize_report_status <path> <critical_count> <warning_count>
finalize_report_status() {
  local path="$1" crit="$2" warn="$3"; local status="pass"; local exit=0
  if (( crit > 0 )); then status="critical"; exit=2; elif (( warn > 0 )); then status="warn"; exit=1; fi
  update_report_kv "$path" ".critical_issues=$crit | .warning_issues=$warn | .issues_total=($crit+$warn) | .status=\"$status\""
  echo $exit
}
