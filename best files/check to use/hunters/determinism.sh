#!/usr/bin/env bash
# hunters/determinism.sh — Run hunters twice with FAKE_NOW and diff reports to ensure reproducibility
set -euo pipefail
OUT="__reports/hunt/determinism.json"; mkdir -p "$(dirname "$OUT")"
BASE_DIR="tmp/determinism/base"; SHIFT_DIR="tmp/determinism/shift"
rm -rf "$BASE_DIR" "$SHIFT_DIR"; mkdir -p "$BASE_DIR" "$SHIFT_DIR"

# First pass: current time
bash ./hunt.sh || true
rsync -a --delete "__reports/hunt/" "$BASE_DIR/" || true

# Second pass: shifted time
export FAKE_NOW="${FAKE_NOW:-2001-01-01T00:00:00.000Z}"
bash ./hunt.sh || true
rsync -a --delete "__reports/hunt/" "$SHIFT_DIR/" || true

DIFF=$(diff -qr "$BASE_DIR" "$SHIFT_DIR" || true)
STATUS=$([[ -z "$DIFF" ]] && echo pass || echo warn)

jq -n --arg status "$STATUS" --arg diff "${DIFF:-}" '
{
  module:"determinism", status:$status, issues: ( $diff=="" ? 0 : 1 ),
  counts: {}, affected_files: 0, actions: ( $diff=="" ? [] : ["Eliminate wall-clock dependent code in hunters/generators; honor FAKE_NOW."] ),
  policy_invariants: [], eta_minutes: 20, unlocks:["cache","reproducible_builds"],
  diff: $diff
}' > "$OUT"
