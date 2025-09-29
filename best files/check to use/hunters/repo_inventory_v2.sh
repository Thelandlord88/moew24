#!/usr/bin/env bash
# Repository Inventory Hunter v2 (Extended)
# Adds: import graph, git age/churn, size metrics, duplication clusters, action scoring.
# Usage:
#   bash hunters/repo_inventory_v2.sh [--full] [--root DIR]
# Outputs:
#   __reports/hunt/repo_inventory_v2.json
#   __reports/hunt/repo_inventory_v2.md

set -euo pipefail

ROOT_DIR="."
MODE="fast"  # fast | full
for arg in "$@"; do
  case "$arg" in
    --full) MODE="full" ;;
    --root) shift; ROOT_DIR="$1" ;;
  esac
  shift || true
done

OUT_DIR="__reports/hunt"
JSON_OUT="$OUT_DIR/repo_inventory_v2.json"
MD_OUT="$OUT_DIR/repo_inventory_v2.md"
mkdir -p "$OUT_DIR"

echo "[repo-inventory-v2] Mode=$MODE root=$ROOT_DIR" >&2

# Collect candidate files (exclude heavy/build dirs)
mapfile -t FILES < <(find "$ROOT_DIR" -type f \
  ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/.git/*' \
  ! -path '*/.netlify/*' ! -path '*/__reports/hunt/*' | sed 's|^./||' | sort)

# Data structures
declare -A meta_loc meta_bytes meta_hash meta_role meta_imports meta_imported_by meta_git_time meta_git_commits
declare -A meta_import_specs meta_external_import_count meta_internal_import_count
declare -A meta_fan_out
declare -A hash_group
declare -A flag_dist_presence flag_is_orphaned flag_empty_stub

sha_cmd() { command -v sha1sum >/dev/null && echo sha1sum || echo shasum; }
SHA_BIN=$(sha_cmd)

# Single source of truth for code-like roles that can be "unused"
readonly CODE_LIKE_ROLES="code|component|style|backup|script|hunter"

infer_role() {
  local f="$1"
  case "$f" in
    src/components/*.astro|src/components/**/*.astro) echo component ;;
    src/components/sections/*.astro) echo section_component ;;
    src/pages/*.astro|src/pages/**/*.astro) echo page ;;
    hunters/*.sh) echo hunter ;;
    scripts/*) echo script ;;
    src/data/*) echo data ;;
    src/content/*) echo content_entry ;;
    *.schema.*) echo schema ;;
    *.config.*|*.config|*rc|*rc.*|*.json) echo config ;;
    *.md) echo doc ;;
    *.css|*.scss|*.sass|*.pcss) echo style ;;
    *.mjs|*.cjs|*.js|*.ts|*.tsx) echo code ;;
    *.bak|*.old|*.orig) echo backup ;;
    *) echo other ;;
  esac
}

is_text() { grep -Iq . "$1" 2>/dev/null; }

build_import_graph() {
  echo "[repo-inventory-v2] Building import graph" >&2
  for f in "${FILES[@]}"; do
    case "$f" in
      *.js|*.mjs|*.cjs|*.ts|*.tsx|*.astro)
        # Extract import specifiers (very heuristic)
        if is_text "$f"; then
          local imports
          imports=$(grep -Eo "(^|[[:space:]])import[[:space:]]+[^;]*from[[:space:]]+['\"][^'\"]+['\"]|(^|[[:space:]])import[[:space:]]+['\"][^'\"]+['\"]" "$f" 2>/dev/null | sed -E "s/.*from['\"]|import['\"]|['\"]//g") || true
          if [[ -n "$imports" ]]; then
            while IFS= read -r imp; do
              imp=${imp// /}
              [[ -z "$imp" ]] && continue
              meta_imports[$f]+="${imp};;;"  # raw spec
            done <<< "$imports"
          fi
        fi
        ;;
    esac
  done
  # Resolve relative imports to normalized paths
  for f in "${FILES[@]}"; do
    local basedir="${f%/*}"; [[ "$basedir" == "$f" ]] && basedir="."
    local raw="${meta_imports[$f]:-}"; [[ -z $raw ]] && continue
    IFS=';' read -r -a parts <<< "$raw"
    for p in "${parts[@]}"; do
      [[ -z "$p" ]] && continue
      # Only handle relative for usage graph now
      if [[ "$p" == .* ]]; then
        # Try common extensions
        local resolved="$(realpath -m "$basedir/$p" 2>/dev/null || echo '')"
        # Map back to repo-relative
        if [[ -n "$resolved" && -f "$resolved" ]]; then
          local rel="${resolved#$(pwd)/}"
          meta_imported_by[$rel]+="$f;;;"
          meta_internal_import_count[$f]=$(( ${meta_internal_import_count[$f]:-0} + 1 ))
          meta_import_specs[$f]+="${rel};;;"
        else
          # Try with extensions
          for ext in .ts .js .mjs .astro .tsx; do
            if [[ -f "$basedir/${p}${ext}" ]]; then
              local rel2="$basedir/${p}${ext}"
              rel2=${rel2#./}
              meta_imported_by[$rel2]+="$f;;;"
              meta_internal_import_count[$f]=$(( ${meta_internal_import_count[$f]:-0} + 1 ))
              meta_import_specs[$f]+="${rel2};;;"
              break
            fi
          done
        fi
      else
        # external or package import
        # Alias handling for ~/ (treat as internal pointing to src/)
        if [[ "$p" == "~/"* ]]; then
          local alias_path="src/${p#~/}"
          if [[ -f "$alias_path" ]]; then
            meta_internal_import_count[$f]=$(( ${meta_internal_import_count[$f]:-0} + 1 ))
            meta_import_specs[$f]+="${alias_path};;;"
            meta_imported_by[$alias_path]+="$f;;;"
          else
            meta_external_import_count[$f]=$(( ${meta_external_import_count[$f]:-0} + 1 ))
            meta_import_specs[$f]+="${p};;;"
          fi
        else
          meta_external_import_count[$f]=$(( ${meta_external_import_count[$f]:-0} + 1 ))
          meta_import_specs[$f]+="${p};;;"
        fi
      fi
    done
  done
}

# Map source page files to built dist output presence
compute_dist_presence() {
  echo "[repo-inventory-v2] Mapping dist page presence" >&2
  # Collect all built html paths relative to dist/
  mapfile -t DIST_HTML < <(find dist -type f -name '*.html' 2>/dev/null | sed 's|^dist/||') || true
  for f in "${FILES[@]}"; do
    local role="${meta_role[$f]}"
    local present=0 orphan=0
    if [[ "$role" == "page" ]]; then
      # Derive route key
      local base="${f#src/pages/}"
      base="${base%.astro}"
      # Skip dynamic routes containing '['
      if [[ "$base" =~ \[.*\] ]]; then
        present=1 # assume dynamic pages are valid (cannot reliably map)
      else
        local candidate1="${base}/index.html"
        local candidate2="${base}.html"
        local found=0
        for h in "${DIST_HTML[@]}"; do
          if [[ "$h" == "$candidate1" || "$h" == "$candidate2" ]]; then
            found=1; break
          fi
        done
        if [[ $found -eq 1 ]]; then
          present=1
        else
          present=0; orphan=1
        fi
      fi
    fi
    flag_dist_presence[$f]=$present
    flag_is_orphaned[$f]=$orphan
  done
}

collect_git_meta() {
  echo "[repo-inventory-v2] Collecting git metadata" >&2
  for f in "${FILES[@]}"; do
    if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
      local ts commits
      ts=$(git log -1 --format=%ct -- "$f" 2>/dev/null || echo 0)
      commits=$(git rev-list --count HEAD -- "$f" 2>/dev/null || echo 0)
      meta_git_time[$f]="$ts"
      meta_git_commits[$f]="$commits"
    else
      meta_git_time[$f]=0
      meta_git_commits[$f]=0
    fi
  done
}

collect_basics() {
  echo "[repo-inventory-v2] Collecting size/hash/role" >&2
  for f in "${FILES[@]}"; do
    local role loc bytes hash
    role=$(infer_role "$f")
    meta_role[$f]="$role"
    if is_text "$f"; then
      loc=$(wc -l < "$f" 2>/dev/null || echo 0)
    else
      loc=0
    fi
    bytes=$(wc -c < "$f" 2>/dev/null || echo 0)
    hash=$($SHA_BIN "$f" 2>/dev/null | awk '{print $1}')
    meta_loc[$f]="$loc"
    meta_bytes[$f]="$bytes"
    meta_hash[$f]="$hash"
    hash_group[$hash]+="$f;;;"
  done
}

score_file() {
  local f="$1"
  local role="${meta_role[$f]}"
  local imports_raw="${meta_imported_by[$f]:-}"
  local imported_by_count=0
  if [[ -n "$imports_raw" ]]; then
    imported_by_count=$(echo "$imports_raw" | tr ';' '\n' | grep -E '.+' | sort -u | wc -l | tr -d ' ')
  fi
  local git_ts="${meta_git_time[$f]:-0}"
  local age_days=0
  if [[ "$git_ts" != 0 ]]; then
    age_days=$(( ( $(date +%s) - git_ts ) / 86400 ))
  fi
  local commits="${meta_git_commits[$f]:-0}"
  local bytes="${meta_bytes[$f]:-0}"
  local hash="${meta_hash[$f]:-none}"
  local dup_group_size=0
  if [[ -n "${hash_group[$hash]:-}" ]]; then
    dup_group_size=$(echo "${hash_group[$hash]}" | tr ';' '\n' | grep -E '.+' | wc -l | tr -d ' ')
  fi

  local score=0
  local dist_p="${flag_dist_presence[$f]:-0}"
  local orphan="${flag_is_orphaned[$f]:-0}"
  local empty_stub=0
  local loc="${meta_loc[$f]}"
  if (( loc == 0 || bytes < 40 )); then empty_stub=1; fi
  flag_empty_stub[$f]=$empty_stub

  # Fan-out (protect high-dependency modules)
  local fan_out=$(( ${meta_internal_import_count[$f]:-0} + ${meta_external_import_count[$f]:-0} ))
  meta_fan_out[$f]=$fan_out

  # Positive toward deletion (boosted)
  if [[ $imported_by_count -eq 0 ]] && [[ $role =~ ^($CODE_LIKE_ROLES)$ ]]; then
    score=$((score+35))
  fi
  [[ $role == backup ]] && score=$((score+30))
  [[ $dup_group_size -gt 1 && $bytes -lt 600 ]] && score=$((score+10))
  [[ $empty_stub -eq 1 && $imported_by_count -eq 0 && $age_days -gt 7 ]] && score=$((score+15))
  [[ $orphan -eq 1 ]] && score=$((score+20))
  [[ $age_days -gt 60 ]] && score=$((score+10))
  [[ $bytes -lt 400 ]] && score=$((score+5))

  # Negative toward deletion
  # Exempt backup files from fan_out / high fan-in penalties (they're inert snapshots)
  if [[ $role != backup ]]; then
    [[ $imported_by_count -gt 3 ]] && score=$((score-40))
    [[ $fan_out -gt 12 ]] && score=$((score-50)) || ([[ $fan_out -gt 6 ]] && score=$((score-30)))
  fi
  [[ $commits -gt 10 ]] && score=$((score-15))
  [[ $age_days -lt 7 ]] && score=$((score-10))
  [[ $dist_p -eq 1 && $role == page ]] && score=$((score-20)) # live page protection

    # --- Reason combo multipliers (semantic boosts) ---
    # We re-derive minimal reason flags here (lightweight) to avoid changing earlier logic.
    local r_unused=0 r_backup=0 r_empty=0 r_stale=0 r_small=0 r_orphan=0 r_recent=0
    if [[ $imported_by_count -eq 0 ]] && [[ $role =~ ^($CODE_LIKE_ROLES)$ ]]; then
      r_unused=1
    fi
    [[ $role == backup ]] && r_backup=1
    (( loc == 0 || empty_stub == 1 )) && r_empty=1
    (( age_days > 60 )) && r_stale=1
    (( bytes < 400 )) && r_small=1
    (( orphan == 1 )) && r_orphan=1
    (( age_days < 7 )) && r_recent=1

    local combo_boost=0
    # Toxic triad: unused + backup + empty
    if (( r_unused && r_backup && r_empty )); then combo_boost=$((combo_boost+15)); fi
    # Stale + unused (long-term dead weight)
    if (( r_unused && r_stale )); then combo_boost=$((combo_boost+10)); fi
    # Orphan + small (low impact likely obsolete)
    if (( r_orphan && r_small )); then combo_boost=$((combo_boost+8)); fi
  # Recent backup without unused/empty (probably intentional snapshot) -> slight dampen
  if (( r_recent && r_backup && ! r_unused && ! r_empty )); then combo_boost=$((combo_boost-5)); fi
  # Promote unused + backup even if not empty (encourage archival triage)
  if (( r_unused && r_backup && ! r_empty )); then combo_boost=$((combo_boost+8)); fi

    score=$((score + combo_boost))

  # Floor unused + backup to at least archive threshold (after combo adjustments, before clamp)
  if (( r_backup && r_unused )) && (( score < 50 )); then
    score=50
  fi

  # Normalize to 0-100 clamp
  (( score < 0 )) && score=0
  (( score > 100 )) && score=100

  local action="keep"
  local confidence=0.85
  if (( score >= 65 )); then action="delete"; confidence=0.92
  elif (( score >= 45 )); then action="archive"; confidence=0.8
  elif (( score >= 20 )); then action="review"; confidence=0.6
  fi

  echo "$action|$confidence|$score|$imported_by_count|$age_days|$commits|$dup_group_size|$dist_p|$orphan|$empty_stub"
}

# Execute collection phases
collect_basics
build_import_graph
[[ $MODE == full ]] && collect_git_meta || echo "[repo-inventory-v2] Skipping git metadata (fast mode)" >&2
compute_dist_presence
trap '' PIPE

generate_json(){
  set +o pipefail
  {
    echo '{'
    printf '  "module": "repo_inventory_v2",\n'
    printf '  "mode": "%s",\n' "$MODE"
    printf '  "generated": "%s",\n' "$(date -Iseconds)"
    echo '  "files": ['
  local first=true
  declare -A reason_counts
  for f in "${FILES[@]}"; do
      action_data=$(score_file "$f")
      IFS='|' read -r action confidence score imported_by_count age_days commits dup_size dist_p orphan empty_stub <<< "$action_data"
      imports_list="${meta_import_specs[$f]:-}"
      if [[ -n $imports_list ]]; then
        imports_json=$(echo "$imports_list" | tr ';' '\n' | grep -E '.+' | sort -u | awk 'NR>1{printf ","}{printf "\""$0"\""}')
      else
        imports_json=""
      fi
      internal_count=${meta_internal_import_count[$f]:-0}
      external_count=${meta_external_import_count[$f]:-0}
      fan_out=$(( internal_count + external_count ))
      imports_raw="${meta_imported_by[$f]:-}"
      if [[ -n $imports_raw ]]; then
        imported_by_json=$(echo "$imports_raw" | tr ';' '\n' | grep -E '.+' | sort -u | awk 'NR>1{printf ","}{printf "\""$0"\""}')
      else
        imported_by_json=""
      fi
      if [[ "$first" == true ]]; then
        first=false
      else
        echo ','
      fi
      # Compute reasons inline (mirrors bridge heuristic)
      reasons=()
      role="${meta_role[$f]}"; loc="${meta_loc[$f]}"; bytes="${meta_bytes[$f]}"
      fan_out=$(( internal_count + external_count ))
      if [[ $imported_by_count -eq 0 ]]; then
        if [[ "$role" =~ ^($CODE_LIKE_ROLES)$ ]]; then
          reasons+=("unused")
        fi
      fi
      [[ "$role" == "backup" ]] && reasons+=("backup")
      (( dup_size > 1 )) && reasons+=("duplicate_group")
      (( loc == 0 || empty_stub == 1 )) && reasons+=("empty_stub")
      (( orphan == 1 )) && reasons+=("orphan_page")
      (( age_days > 60 )) && reasons+=("stale")
      (( bytes < 400 )) && reasons+=("small")
      (( imported_by_count > 3 )) && reasons+=("high_fan_in")
      if (( fan_out > 12 )); then reasons+=("fan_out12"); elif (( fan_out > 6 )); then reasons+=("fan_out6"); fi
      (( age_days < 7 )) && reasons+=("recent")
      if (( dist_p == 1 )) && [[ "$role" == "page" ]]; then reasons+=("live_page"); fi
      # unique
      if (( ${#reasons[@]} > 1 )); then mapfile -t reasons < <(printf '%s\n' "${reasons[@]}" | awk '!a[$0]++'); fi
      reasons_json=""
      for r in "${reasons[@]}"; do
        if [[ -z "$reasons_json" ]]; then reasons_json="\"$r\""; else reasons_json+=",\"$r\""; fi
        reason_counts[$r]=$(( ${reason_counts[$r]:-0} + 1 ))
      done
      printf '    {"path":"%s","role":"%s","loc":%s,"bytes":%s,"age_days":%s,"commits":%s,"imported_by_count":%s,"duplicate_group_size":%s,"internal_imports":%s,"external_imports":%s,"fan_out":%s,"score":%s,"action":"%s","confidence":%.2f,"hash":"%s","dist_presence":%s,"is_orphaned":%s,"empty_stub":%s,"imports":[%s],"imported_by":[%s],"reasons":[%s]}' \
        "$f" "${meta_role[$f]}" "${meta_loc[$f]}" "${meta_bytes[$f]}" "$age_days" "$commits" "$imported_by_count" "$dup_size" "$internal_count" "$external_count" "$fan_out" "$score" "$action" "$confidence" "${meta_hash[$f]}" "$dist_p" "$orphan" "$empty_stub" "$imports_json" "$imported_by_json" "$reasons_json"
    done
    echo
    echo '  ],'
    echo '  "reasons_summary": {'
    local first_reason=true
    for r in $(printf '%s\n' "${!reason_counts[@]}" | sort); do
      if [[ $first_reason == true ]]; then first_reason=false; else echo -n ','; fi
      echo -n $'\n    '"\"$r\": ${reason_counts[$r]}"
    done
    echo -e '\n  }'
    echo '}'
  } > "$JSON_OUT"
  set -o pipefail
}

generate_json > "$JSON_OUT"

# Generate Markdown summary
generate_md(){
  echo "# Repository Inventory v2"
  echo "Mode: $MODE  Generated: $(date -Iseconds)"
  echo ""
  echo "## Top Deletion Candidates (score>=80)"
  jq -r '(.files[] | select(.action=="delete") | "- " + .path + " (score " + (.score|tostring) + ", imports " + (.imported_by_count|tostring) + ", age " + (.age_days|tostring) + "d)") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Top Archive Candidates (60<=score<80)"
  jq -r '(.files[] | select(.action=="archive") | "- " + .path + " (score " + (.score|tostring) + ", dupGroup " + (.duplicate_group_size|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Usage Outliers (high fan-in)"
  jq -r '(.files[] | select(.imported_by_count>5) | "- " + .path + " (imports " + (.imported_by_count|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## High Fan-Out Modules (top 15)"
  jq -r '[.files[] | {p:.path,f:.fan_out} ] | sort_by(-.f) | .[0:15][] | "- " + .p + " (fan_out " + (.f|tostring) + ")"' "$JSON_OUT"
  echo ""
  echo "## Recent Files (<7d, protect)"
  jq -r '(.files[] | select(.age_days>=0 and .age_days<7) | "- " + .path + " (age " + (.age_days|tostring) + "d, score " + (.score|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Metrics Summary"
  echo "Total files: $(jq '.files|length' "$JSON_OUT")"
  echo "Delete candidates: $(jq '[.files[]|select(.action=="delete")] | length' "$JSON_OUT")"
  echo "Archive candidates: $(jq '[.files[]|select(.action=="archive")] | length' "$JSON_OUT")"
  echo "Keep candidates: $(jq '[.files[]|select(.action=="keep")] | length' "$JSON_OUT")"
  echo "Review candidates: $(jq '[.files[]|select(.action=="review")] | length' "$JSON_OUT")"
}

generate_md > "$MD_OUT"

echo "[repo-inventory-v2] Wrote $JSON_OUT and $MD_OUT" >&2

# Invariant: all backup files should score >=50 (archive/delete). If not, signal for scoring tuning.
backup_low=$(jq '[.files[] | select(.role=="backup" and .score < 50)] | length' "$JSON_OUT")
if (( backup_low > 0 )); then
  echo "[repo-inventory-v2] Invariant WARNING: $backup_low backup files scored <50 (expected archive/delete)." >&2
fi

exit 0

# Markdown summary (top candidates)
{
  echo "# Repository Inventory v2"
  echo "Mode: $MODE  Generated: $(date -Iseconds)"
  echo ""
  echo "## Top Deletion Candidates (score>=80)"
  jq -r '(.files[] | select(.action=="delete") | "- " + .path + " (score " + (.score|tostring) + ", imports " + (.imported_by_count|tostring) + ", age " + (.age_days|tostring) + "d)") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Top Archive Candidates (60<=score<80)"
  jq -r '(.files[] | select(.action=="archive") | "- " + .path + " (score " + (.score|tostring) + ", dupGroup " + (.duplicate_group_size|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Usage Outliers (high fan-in)"
  jq -r '(.files[] | select(.imported_by_count>5) | "- " + .path + " (imports " + (.imported_by_count|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Recent Files (<7d, protect)"
  jq -r '(.files[] | select(.age_days>=0 and .age_days<7) | "- " + .path + " (age " + (.age_days|tostring) + "d, score " + (.score|tostring) + ")") | .[:10000]' "$JSON_OUT"
  echo ""
  echo "## Metrics Summary"
  echo "Total files: ${#FILES[@]}"
  echo "Delete candidates: $(jq '.files | map(select(.action=="delete")) | length' "$JSON_OUT")"
  echo "Archive candidates: $(jq '.files | map(select(.action=="archive")) | length' "$JSON_OUT")"
  echo "Keep candidates: $(jq '.files | map(select(.action=="keep")) | length' "$JSON_OUT")"
  echo "Review candidates: $(jq '.files | map(select(.action=="review")) | length' "$JSON_OUT")"
} > "$MD_OUT"

echo "[repo-inventory-v2] Wrote $JSON_OUT and $MD_OUT" >&2
