#!/usr/bin/env bash
# ai_files.sh — enumerate AI-related files and write a JSON report
set -euo pipefail
export LC_ALL=C
IFS=$'\n\t'

REPORT_DIR="__reports/hunt"

# Resolve repo root (prefer git, else walk up, else fallback relative to this script)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_CANDIDATE="$PWD"
if command -v git >/dev/null 2>&1; then
  git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$git_root" && -d "$git_root" ]]; then
    ROOT_CANDIDATE="$git_root"
  fi
fi
ROOT="$ROOT_CANDIDATE"
while [[ ! -d "$ROOT/.git" && "$ROOT" != "/" ]]; do
  ROOT="$(dirname "$ROOT")"
done
if [[ ! -d "$ROOT/.git" ]]; then
  # Fallback: assume pack lives under repo/Hunt sh silly/hunters/hunter-pack
  ROOT="$(cd "$script_dir/../../../../" 2>/dev/null && pwd)"
fi

mkdir -p "$ROOT/$REPORT_DIR"
out="$ROOT/$REPORT_DIR/ai_files.json"

# Collect files by category
collect_paths() {
  # $1 = a single -path pattern (root-relative like 'scripts/daedalus/*' or absolute)
  local pattern="$1"
  if [[ "$pattern" != /* ]]; then
    # drop leading ./ if present and prefix ROOT
    pattern="$ROOT/${pattern#./}"
  fi
  find "$ROOT" -type f -path "$pattern" \
    -not -path "$ROOT/node_modules/*" -not -path "$ROOT/.git/*" 2>/dev/null \
    | sed "s#^$ROOT/##" | sort -u || true
}

daedalus=$(collect_paths 'scripts/daedalus/*')
daedalus_levels=$( {
  collect_paths 'daedalus_level*/*'
  collect_paths 'phases/*/daedalus_level*/*'
} | sort -u)
personalities=$( {
  collect_paths 'scripts/personalities/*'
  collect_paths 'personalities/*'
} | sort -u)
profiles=$( {
  collect_paths 'profiles/*'
  collect_paths 'personalities/*/profiles/*'
} | sort -u)
ai_root=$(find "$ROOT" -maxdepth 1 -type f -name 'ai-*.mjs' -not -path "$ROOT/node_modules/*" -not -path "$ROOT/.git/*" 2>/dev/null | sed "s#^$ROOT/##" | sort -u)
ai_dir=$(collect_paths '__ai/*')
api_systems=$(collect_paths 'src/pages/api/systems/*')

# Merge flat list
flat=$(printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$daedalus" "$daedalus_levels" "$personalities" "$profiles" "$ai_root" "$ai_dir" "$api_systems" | sed '/^$/d' | sort -u)

# Emit JSON
tmp=$(mktemp)
{
  echo '{'
  echo '  "schemaVersion": 1,'
  echo '  "module": "ai_files",'
  echo '  "status": "pass",'
  echo '  "issues": 0,'
  echo '  "counts": {'
  echo "    \"daedalus\": $(printf '%s\n' "$daedalus" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"daedalus_levels\": $(printf '%s\n' "$daedalus_levels" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"personalities\": $(printf '%s\n' "$personalities" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"profiles\": $(printf '%s\n' "$profiles" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"ai_root\": $(printf '%s\n' "$ai_root" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"ai_dir\": $(printf '%s\n' "$ai_dir" | sed '/^$/d' | wc -l | tr -d ' '),"
  echo "    \"api_systems\": $(printf '%s\n' "$api_systems" | sed '/^$/d' | wc -l | tr -d ' ')"
  echo '  },'
  echo '  "files": ['
  first=1
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ $first -eq 1 ]]; then
      printf '    "%s"\n' "$f"; first=0
    else
      printf '    ,"%s"\n' "$f"
    fi
  done <<< "$flat"
  echo '  ]'
  echo '}'
} > "$tmp"
mv "$tmp" "$out"
printf "Wrote %s (total files: %d)\n" "$out" "$(printf '%s\n' "$flat" | sed '/^$/d' | wc -l | tr -d ' ')"
