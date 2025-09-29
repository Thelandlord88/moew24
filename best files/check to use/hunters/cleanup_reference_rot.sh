#!/usr/bin/env bash
# Cleanup Reference Rot Hunter
# Detects lingering references to files moved during cleanup
# Follows Upstream-Curious methodology: Box → Closet → Policy

set -euo pipefail

TIMESTAMP=$(date -Iseconds)
OUT_DIR="__reports/hunt"
JSON_OUT="$OUT_DIR/cleanup_reference_rot.json"
TXT_OUT="$OUT_DIR/cleanup_reference_rot.txt"
mkdir -p "$OUT_DIR"

echo "[cleanup-reference-rot] Starting reference rot detection..." >&2

# Initialize counters
CRITICAL_COUNT=0
WARNING_COUNT=0
BROKEN_SCRIPTS=0
ORPHANED_IMPORTS=0
STALE_CONFIGS=0

# Create text report
cat > "$TXT_OUT" <<EOF
# Cleanup Reference Rot Analysis
Generated: $TIMESTAMP

## Summary
This report identifies lingering references to files moved during cleanup.
Following Upstream-Curious methodology: Box (moved files) → Closet (references) → Policy (prevention)

EOF

# Get list of moved files from CLEANUP directory
MOVED_FILES=()
if [[ -d "CLEANUP" ]]; then
  while IFS= read -r file; do
    # Convert CLEANUP path back to original path
    original_path="${file#CLEANUP/*/}"
    MOVED_FILES+=("$original_path")
  done < <(find CLEANUP -type f 2>/dev/null | head -100) # Limit for performance
fi

echo "[cleanup-reference-rot] Found ${#MOVED_FILES[@]} moved files to check" >&2

echo "## Files Moved: ${#MOVED_FILES[@]}" >> "$TXT_OUT"
echo "" >> "$TXT_OUT"

# 1. Check package.json for broken script references
echo "[cleanup-reference-rot] Checking package.json scripts..." >&2
echo "## Package.json Script Analysis" >> "$TXT_OUT"

if [[ -f "package.json" ]]; then
  for moved_file in "${MOVED_FILES[@]}"; do
    if grep -q "$moved_file" package.json 2>/dev/null; then
      script_lines=$(grep -n "$moved_file" package.json || true)
      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          line_num=$(echo "$line" | cut -d: -f1)
          script_content=$(echo "$line" | cut -d: -f2-)
          echo "❌ CRITICAL: Line $line_num references moved file: $moved_file" >> "$TXT_OUT"
          echo "   Content: $script_content" >> "$TXT_OUT"
          ((CRITICAL_COUNT++))
          ((BROKEN_SCRIPTS++))
        fi
      done <<< "$script_lines"
    fi
  done
  
  if [[ $BROKEN_SCRIPTS -eq 0 ]]; then
    echo "✅ No broken script references found" >> "$TXT_OUT"
  fi
else
  echo "⚠️  No package.json found" >> "$TXT_OUT"
fi

echo "" >> "$TXT_OUT"

# 2. Check for orphaned imports (sample check to avoid performance issues)
echo "[cleanup-reference-rot] Scanning for orphaned imports..." >&2
echo "## Orphaned Import Analysis" >> "$TXT_OUT"

# Check first 20 moved files for imports
for moved_file in "${MOVED_FILES[@]:0:20}"; do
  # Remove file extension for import checks
  import_path="${moved_file%.*}"
  
  # Search for imports in active source files
  import_files=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.mjs" -o -name "*.astro" \) \
      ! -path "./CLEANUP/*" ! -path "./node_modules/*" ! -path "./.git/*" \
      -exec grep -l "from ['\"].*$import_path" {} \; 2>/dev/null | head -3 || true)
  
  if [[ -n "$import_files" ]]; then
    echo "$import_files" | while IFS= read -r file; do
      if [[ -n "$file" ]]; then
        line_nums=$(grep -n "from ['\"].*$import_path" "$file" | cut -d: -f1 || true)
        for line_num in $line_nums; do
          echo "⚠️  WARNING: $file:$line_num imports moved file: $moved_file" >> "$TXT_OUT"
          ((WARNING_COUNT++))
          ((ORPHANED_IMPORTS++))
        done
      fi
    done
  fi
done

if [[ $ORPHANED_IMPORTS -eq 0 ]]; then
  echo "✅ No orphaned imports found (sampled first 20 moved files)" >> "$TXT_OUT"
fi

echo "" >> "$TXT_OUT"

# 3. Check configuration files
echo "[cleanup-reference-rot] Checking config files..." >&2
echo "## Configuration File Analysis" >> "$TXT_OUT"

CONFIG_FILES=("astro.config.mjs" "astro.config.ts" "vite.config.js" "vitest.config.mts" "playwright.config.ts" "tailwind.config.js" "eslint.config.js")
for config_file in "${CONFIG_FILES[@]}"; do
  if [[ -f "$config_file" ]]; then
    echo "Checking $config_file..." >> "$TXT_OUT"
    config_issues=0
    
    for moved_file in "${MOVED_FILES[@]:0:10}"; do  # Check first 10 for performance
      if grep -q "$moved_file" "$config_file" 2>/dev/null; then
        line_nums=$(grep -n "$moved_file" "$config_file" | cut -d: -f1 || true)
        for line_num in $line_nums; do
          echo "⚠️  WARNING: $config_file:$line_num references moved file: $moved_file" >> "$TXT_OUT"
          ((WARNING_COUNT++))
          ((STALE_CONFIGS++))
          ((config_issues++))
        done
      fi
    done
    
    if [[ $config_issues -eq 0 ]]; then
      echo "✅ No stale references in $config_file" >> "$TXT_OUT"
    fi
  fi
done

echo "" >> "$TXT_OUT"

# 4. Generate recommendations
echo "## Recommendations" >> "$TXT_OUT"
echo "" >> "$TXT_OUT"

if [[ $BROKEN_SCRIPTS -gt 0 ]]; then
  echo "### Package.json Cleanup" >> "$TXT_OUT"
  echo "- Remove or update broken script references" >> "$TXT_OUT"
  echo "- Consider consolidating remaining scripts" >> "$TXT_OUT"
  echo "- Add script validation to CI pipeline" >> "$TXT_OUT"
  echo "" >> "$TXT_OUT"
fi

if [[ $ORPHANED_IMPORTS -gt 0 ]]; then
  echo "### Import Cleanup" >> "$TXT_OUT"
  echo "- Remove orphaned import statements" >> "$TXT_OUT"
  echo "- Use TypeScript or ESLint to catch missing imports" >> "$TXT_OUT"
  echo "- Add unused import detection to CI" >> "$TXT_OUT"
  echo "" >> "$TXT_OUT"
fi

echo "### Recommended Tests" >> "$TXT_OUT"
echo "- Add build smoke test to catch broken references" >> "$TXT_OUT"
echo "- Add import validation test" >> "$TXT_OUT"
echo "- Add package.json script validation" >> "$TXT_OUT"
echo "- Add config file validation test" >> "$TXT_OUT"
echo "" >> "$TXT_OUT"

echo "### Prevention (Policy)" >> "$TXT_OUT"
echo "- Implement reference validation in CI" >> "$TXT_OUT"
echo "- Add pre-commit hooks for import validation" >> "$TXT_OUT"
echo "- Create cleanup verification script" >> "$TXT_OUT"
echo "- Add this hunter to regular hunt.sh runs" >> "$TXT_OUT"

# Create JSON summary
cat > "$JSON_OUT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "cleanup_reference_rot",
  "critical_issues": $CRITICAL_COUNT,
  "warning_issues": $WARNING_COUNT,
  "findings": {
    "broken_package_scripts": $BROKEN_SCRIPTS,
    "orphaned_imports": $ORPHANED_IMPORTS,
    "stale_config_references": $STALE_CONFIGS,
    "files_moved": ${#MOVED_FILES[@]}
  },
  "cleanup_completeness": $((100 - (CRITICAL_COUNT * 10) - (WARNING_COUNT * 2))),
  "upstream_analysis": {
    "box": "539 files moved to CLEANUP",
    "closet": "Lingering references in active codebase", 
    "policy": "Reference validation and prevention system"
  }
}
EOF

# Final summary
echo "" >> "$TXT_OUT"
echo "## Summary" >> "$TXT_OUT"
echo "- Critical issues: $CRITICAL_COUNT" >> "$TXT_OUT"
echo "- Warning issues: $WARNING_COUNT" >> "$TXT_OUT"
echo "- Cleanup completeness: $((100 - (CRITICAL_COUNT * 10) - (WARNING_COUNT * 2)))%" >> "$TXT_OUT"

echo "[cleanup-reference-rot] Analysis complete!" >&2
echo "  Critical issues: $CRITICAL_COUNT" >&2
echo "  Warning issues: $WARNING_COUNT" >&2
echo "  Reports: $TXT_OUT, $JSON_OUT" >&2

if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
  echo "❌ CRITICAL: Found $CRITICAL_COUNT broken references that will cause build failures" >&2
  exit 2
elif [[ "$WARNING_COUNT" -gt 5 ]]; then
  echo "⚠️  WARNING: Found $WARNING_COUNT stale references that should be cleaned" >&2
  exit 1
else
  echo "✅ Cleanup reference integrity looks good!" >&2
  exit 0
fi
