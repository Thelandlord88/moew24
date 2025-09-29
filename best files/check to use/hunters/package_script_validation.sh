#!/usr/bin/env bash
# Package.json Script Validation Hunter  
# Policy Invariant: All npm scripts must reference existing files

set -euo pipefail

echo "[package-script-validation] Validating npm scripts..." >&2

BROKEN_COUNT=0
TOTAL_SCRIPTS=0

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
  echo "❌ CRITICAL: package.json not found" >&2
  exit 2
fi

# Validate scripts that reference files
echo "📋 Checking script file references..." >&2

while IFS= read -r script_entry; do
  ((TOTAL_SCRIPTS++))
  script_name=$(echo "$script_entry" | cut -d: -f1)
  script_command=$(echo "$script_entry" | cut -d: -f2-)
  
  # Extract file paths that start with scripts/
  script_files=$(echo "$script_command" | grep -o 'scripts/[^[:space:]"]*' || true)
  
  for script_file in $script_files; do
    if [[ -n "$script_file" && ! -f "$script_file" ]]; then
      ((BROKEN_COUNT++))
      echo "❌ BROKEN: $script_name references missing file: $script_file" >&2
    fi
  done
done < <(jq -r '.scripts // {} | to_entries[] | "\(.key):\(.value)"' package.json 2>/dev/null)

# Create simple JSON report
cat > "__reports/hunt/package_script_validation.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "module": "package_script_validation", 
  "critical_issues": $BROKEN_COUNT,
  "warning_issues": 0,
  "findings": {
    "broken_scripts": $BROKEN_COUNT,
    "total_scripts": $TOTAL_SCRIPTS,
    "validation_status": "$(if [[ $BROKEN_COUNT -eq 0 ]]; then echo "passed"; else echo "failed"; fi)"
  }
}
EOF

# Summary
echo "[package-script-validation] Results:" >&2
echo "  Total scripts: $TOTAL_SCRIPTS" >&2
echo "  Broken scripts: $BROKEN_COUNT" >&2

if [[ $BROKEN_COUNT -gt 0 ]]; then
  echo "❌ CRITICAL: Found $BROKEN_COUNT broken script references" >&2
  exit 2
else
  echo "✅ All npm scripts reference existing files" >&2
  exit 0
fi
