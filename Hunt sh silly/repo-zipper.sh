#!/usr/bin/env bash
set -euo pipefail

# repo-zipper.sh — Create a ZIP of the repo that:
#  - Includes all tracked files at HEAD
#  - Includes untracked files that are NOT ignored by .gitignore
#  - Excludes anything ignored by .gitignore (node_modules, .env, build outputs, etc.)
#  - Produces: dist/<repo>-YYYYMMDD-HHMMSS.zip
#
# Usage:
#   bash repo-zipper.sh
#
# Notes:
#  * Requires: git, zip
#  * Run it from anywhere inside the repo (it auto-detects the top-level)
#  * To download in GitHub Codespaces: open the VS Code File Explorer, right‑click the ZIP under "dist/" → Download

# Detect repo root
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" || ! -d "$ROOT/.git" ]]; then
  echo "❌ Not inside a git repository."
  exit 1
fi
cd "$ROOT"

# Ensure dependencies
command -v zip >/dev/null 2>&1 || { echo "❌ 'zip' is required. Try: sudo apt-get update && sudo apt-get install -y zip"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ 'git' is required."; exit 1; }

# Prepare output path
REPO_NAME="$(basename "$ROOT")"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="dist"
OUT_ZIP="$OUT_DIR/${REPO_NAME}-${TS}.zip"
mkdir -p "$OUT_DIR"

echo "📦 Creating archive: $OUT_ZIP"

# 1) Start with tracked files at HEAD (respects .gitattributes export-ignore)
git archive --format=zip --worktree-attributes -o "$OUT_ZIP" HEAD

# 2) Add untracked but NOT ignored files (respect .gitignore)
#    --others: shows untracked
#    --exclude-standard: respects .gitignore, .git/info/exclude, and global excludes
# We pass the file list to zip in chunks via xargs -0 to handle spaces and many files.
# If there are none, zip exits with code 12 when given no files; guard for empty set.
mapfile -d '' UNTRACKED < <(git ls-files -z --others --exclude-standard || true)
if (( ${#UNTRACKED[@]} > 0 )); then
  printf '%s\0' "${UNTRACKED[@]}" | xargs -0 zip -9 -q "$OUT_ZIP"
fi

# 3) Verify the zip (list a few entries)
echo "✅ Done. Preview of contents:"
zip -sf "$OUT_ZIP" | head -n 25 || true

echo ""
echo "➡️  Archive saved at: $OUT_ZIP"
echo "ℹ️  To download in Codespaces: right‑click the file in VS Code web → Download"
