# hunters/trace.sh — append-only trace events
TRACE_FILE="var/hunt-events.ndjson"
mkdir -p "$(dirname "$TRACE_FILE")"

trace_event() {
  # usage: trace_event <op> <json-data-or-empty>
  local op="$1"; shift || true
  local data="${*:-{}}"
  printf '{"t":"%s","module":"%s","op":"%s","data":%s}\n' \
    "$(date -Iseconds)" "${HUNTER_MODULE:-unknown}" "$op" "$data" >> "$TRACE_FILE"
}

trace_open_file() { trace_event "open_file" "{\"path\":\"$1\"}"; }
trace_issue()     { trace_event "issue" "${1:-{}}"; }      # pass JSON string: {"class":"...","path":"...","severity":"..."}
trace_invariant() { trace_event "invariant" "${1:-{}}"; }  # pass JSON string: {"name":"...","status":"pass|fail"}
trace_timing()    { trace_event "timing" "${1:-{}}"; }     # pass JSON string: {"phase":"...","ms":123}
