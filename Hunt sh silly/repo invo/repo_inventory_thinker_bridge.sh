#!/usr/bin/env bash
# Bridge script: Convert repo_inventory_v2.json into Thinker agenda + DO_NEXT markdown.
# Usage: bash hunters/repo_inventory_thinker_bridge.sh [--json __reports/hunt/repo_inventory_v2.json]
# Outputs:
#   __ai/thinker/agenda_repo_inventory.json
#   __ai/thinker/DO_NEXT_REPO_INVENTORY.md
#   (Optional) appends NDJSON events to var/hunt-events.ndjson
set -euo pipefail

INPUT_JSON="__reports/hunt/repo_inventory_v2.json"
for arg in "$@"; do
  case "$arg" in
    --json) shift; INPUT_JSON="$1" ;;
  esac
  shift || true
done

if [[ ! -f "$INPUT_JSON" ]]; then
  echo "[bridge] Input JSON not found: $INPUT_JSON" >&2
  exit 1
fi

THINKER_DIR="__ai/thinker"
mkdir -p "$THINKER_DIR" "var"
AGENDA_JSON="$THINKER_DIR/agenda_repo_inventory.json"
AGENDA_MD="$THINKER_DIR/DO_NEXT_REPO_INVENTORY.md"
EVENTS_FILE="var/hunt-events.ndjson"

# Use existing reasons if present; otherwise synthesize (backward compatibility)
JQ_FILTER='def synth_reasons(f): [
    (if f.imported_by_count==0 then "unused" else empty end),
    (if f.role=="backup" then "backup" else empty end),
    (if f.duplicate_group_size>1 then "duplicate_group" else empty end),
    (if (f.loc==0 or f.empty_stub==1) then "empty_stub" else empty end),
    (if f.is_orphaned==1 then "orphan_page" else empty end),
    (if f.age_days>60 then "stale" else empty end),
    (if f.bytes<400 then "small" else empty end),
    (if f.imported_by_count>3 then "high_fan_in" else empty end),
    (if f.fan_out>12 then "fan_out12" else (if f.fan_out>6 then "fan_out6" else empty end) end),
    (if f.age_days<7 then "recent" else empty end),
    (if (f.dist_presence==1 and f.role=="page") then "live_page" else empty end)
  ] | unique;
def reasons(f): (if (f.reasons|type? == "array" and (f.reasons|length) > 0) then f.reasons else synth_reasons(f) end);
{module:"repo_inventory", generated:.generated, tasks:(.files
  | map(select(.action=="delete" or .action=="archive" or .action=="review"))
  | sort_by(-.score)
  | to_entries
  | map(. as $e | {priority:($e.key+1), path:$e.value.path, action:$e.value.action, score:$e.value.score, reasons:reasons($e.value), fan_out:($e.value.fan_out // 0), imported_by_count:$e.value.imported_by_count})) }'

jq "$JQ_FILTER" "$INPUT_JSON" > "$AGENDA_JSON"

# Markdown rendering
{
  echo "# Repo Inventory — Thinker Agenda"
  echo "Generated: $(date -Iseconds)"
  echo "Source: $INPUT_JSON"
  echo ""
  echo "| # | Action | Path | Score | Reasons | FanOut | FanIn |"
  echo "| -:| ------ | ---- | -----:| ------- | ------:| -----:|"
  jq -r '.tasks[] | "| " + (.priority|tostring) + " | " + .action + " | " + .path + " | " + (.score|tostring) + " | " + (.reasons|join(",")) + " | " + (.fan_out|tostring) + " | " + (.imported_by_count|tostring) + " |"' "$AGENDA_JSON" | head -80
  echo ""
  echo "Total candidates: $(jq '.tasks|length' "$AGENDA_JSON")"
} > "$AGENDA_MD"

# Append events (optional, non-fatal)
if [[ -s "$AGENDA_JSON" ]]; then
  jq -c '.tasks[] | {ts:(now|floor), kind:"repo_inventory_candidate", path:.path, action:.action, score:.score}' "$AGENDA_JSON" >> "$EVENTS_FILE" || true
fi

echo "[bridge] Wrote $AGENDA_JSON and $AGENDA_MD (events appended to $EVENTS_FILE)" >&2
