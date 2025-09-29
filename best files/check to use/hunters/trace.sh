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
