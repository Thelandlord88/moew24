#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/build_dependencies.sh — Build Pipeline & File Generation Monitor
#
# PURPOSE: Track build scripts, file generation, and prevent fix conflicts
# ELIMINATION TARGET: Manual fixes being overwritten by build-time generators
#
# Box: Fixed files get regenerated, undoing manual changes
# Closet: Build pipeline scripts and file generation workflows
# Policy: No build script overwrites manually fixed files without warning

set -uo pipefail

# Trace (optional)
HUNTER_MODULE="build_dependencies"; if [[ -f hunters/trace.sh ]]; then source hunters/trace.sh || true; fi

# Inherit environment from parent hunt.sh
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"
TIMESTAMP="${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}"
mkdir -p "$REPORT_DIR"

# Colors
if [[ -t 1 ]]; then
  RED='\e[31m'; YEL='\e[33m'; GRN='\e[32m'; CYA='\e[36m'; RST='\e[0m'
else
  RED=''; YEL=''; GRN=''; CYA=''; RST=''
fi

okay() { printf "${GRN}✓ %s${RST}\n" "$*"; }
warn() { printf "${YEL}⚠ %s${RST}\n" "$*"; }
fail() { printf "${RED}✗ %s${RST}\n" "$*"; }

# Output files
BUILD_REPORT="$REPORT_DIR/build_dependencies.json"
BUILD_LOG="$REPORT_DIR/build_dependencies.log"

echo "🏗️ Build Dependencies Analysis" > "$BUILD_LOG"
echo "==============================" >> "$BUILD_LOG"

# Initialize report
cat > "$BUILD_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "build_dependencies",
  "status": "running",
  "findings": {
    "build_scripts": [],
    "file_generators": [],
    "generated_files": [],
    "potential_conflicts": [],
    "build_order": []
  },
  "issues": 0,
  "critical": 0
}
EOF

declare -i ISSUES=0
declare -i CRITICAL=0

# 1) Parse package.json build pipeline
echo "Analyzing package.json build pipeline..." | tee -a "$BUILD_LOG"
if [[ -f package.json ]]; then
  # Extract build-related scripts
  BUILD_SCRIPTS=$(node -e "
    const pkg = require('./package.json');
    const scripts = pkg.scripts || {};
    const buildRelated = Object.entries(scripts)
      .filter(([k,v]) => /build|prebuild|postbuild/.test(k))
      .map(([k,v]) => ({name: k, command: v}));
    console.log(JSON.stringify(buildRelated, null, 2));
  ")
  
  if [[ -n "$BUILD_SCRIPTS" ]]; then
    okay "Found $(echo "$BUILD_SCRIPTS" | jq '. | length') build-related scripts"
    echo "$BUILD_SCRIPTS" | jq -r '.[] | "  • \(.name): \(.command)"' | tee -a "$BUILD_LOG"
  else
    warn "No build-related scripts found in package.json"
  fi
else
  fail "package.json not found"
  ((CRITICAL++))
fi

# 2) Identify file generators in scripts
echo "Scanning for file generation patterns..." | tee -a "$BUILD_LOG"
FILE_GENERATORS=$(find scripts/ -name "*.mjs" -o -name "*.js" -o -name "*.ts" | \
  xargs grep -l "writeFile\|fs\.write\|createWriteStream\|>\s*['\"].*\.\(json\|ts\|js\)" 2>/dev/null || true)

if [[ -n "$FILE_GENERATORS" ]]; then
  GENERATOR_COUNT=$(echo "$FILE_GENERATORS" | wc -l | tr -d ' ')
  warn "Found $GENERATOR_COUNT scripts that generate files:"
  echo "$FILE_GENERATORS" | while IFS= read -r file; do
    echo "  • $file" | tee -a "$BUILD_LOG"
  done <<< "$FILE_GENERATORS"
  ((ISSUES++))
else
  okay "No obvious file generators found"
fi

# 3) Analyze specific generated files
echo "Analyzing generated file patterns..." | tee -a "$BUILD_LOG"
GENERATED_FILES=""

# Check for common generation patterns
for script in scripts/*.mjs scripts/*.js; do
  if [[ -f "$script" ]]; then
    # Look for writeFileSync patterns
    WRITES=$(grep -n "writeFileSync\|writeFile" "$script" 2>/dev/null | head -3 || true)
    if [[ -n "$WRITES" ]]; then
      echo "  $script generates files:" | tee -a "$BUILD_LOG"
      echo "$WRITES" | sed 's/^/    /' | tee -a "$BUILD_LOG"
      
      # Extract file paths from writeFileSync calls
      PATHS=$(echo "$WRITES" | grep -o "'[^']*\.\(json\|ts\|js\)'" | tr -d "'" || true)
      if [[ -n "$PATHS" ]]; then
        GENERATED_FILES="$GENERATED_FILES"$'\n'"$PATHS"
      fi
    fi
  fi
done

# 4) Check for potential conflicts with src/ files
echo "Checking for potential file conflicts..." | tee -a "$BUILD_LOG"
CONFLICTS=""

if [[ -n "$GENERATED_FILES" ]]; then
  while IFS= read -r file; do
    if [[ -n "$file" && -f "$file" ]]; then
      # Check if this is a source file that might be manually edited
      if [[ "$file" =~ ^src/ ]]; then
        echo "  ⚠ Generated file in source tree: $file" | tee -a "$BUILD_LOG"
        CONFLICTS="$CONFLICTS"$'\n'"$file"
        ((ISSUES++))
      fi
    fi
  done <<< "$GENERATED_FILES"
fi

# 5) Build order analysis
echo "Analyzing build execution order..." | tee -a "$BUILD_LOG"
BUILD_ORDER=""

if [[ -f package.json ]]; then
  # Extract build command breakdown
  BUILD_CMD=$(jq -r '.scripts.build // ""' package.json)
  PREBUILD_CMD=$(jq -r '.scripts.prebuild // ""' package.json)
  POSTBUILD_CMD=$(jq -r '.scripts.postbuild // ""' package.json)
  
  if [[ -n "$PREBUILD_CMD" ]]; then
    echo "  1. PREBUILD: $PREBUILD_CMD" | tee -a "$BUILD_LOG"
    BUILD_ORDER="$BUILD_ORDER"$'\n'"prebuild"
  fi
  
  if [[ -n "$BUILD_CMD" ]]; then
    echo "  2. BUILD: $BUILD_CMD" | tee -a "$BUILD_LOG"
    BUILD_ORDER="$BUILD_ORDER"$'\n'"build"
  fi
  
  if [[ -n "$POSTBUILD_CMD" ]]; then
    echo "  3. POSTBUILD: $POSTBUILD_CMD" | tee -a "$BUILD_LOG"
    BUILD_ORDER="$BUILD_ORDER"$'\n'"postbuild"
  fi
fi

# 6) Critical conflict detection
echo "Detecting critical build conflicts..." | tee -a "$BUILD_LOG"

# Check if any generated files are in git and have recent changes
if command -v git >/dev/null 2>&1; then
  RECENT_CHANGES=$(git log --since="7 days ago" --name-only --pretty=format: | \
    grep -E "\.(json|ts|js)$" | sort | uniq | head -10 || true)
  
  if [[ -n "$RECENT_CHANGES" && -n "$GENERATED_FILES" ]]; then
    echo "  Recent file changes that might conflict with generators:" | tee -a "$BUILD_LOG"
    while IFS= read -r changed_file; do
      if echo "$GENERATED_FILES" | grep -q "$changed_file"; then
        fail "CONFLICT: $changed_file was manually changed but is also generated"
        ((CRITICAL++))
      fi
    done <<< "$RECENT_CHANGES"
  fi
fi

# 7) Generation frequency analysis
echo "Analyzing generation frequency..." | tee -a "$BUILD_LOG"
FREQUENT_GENERATORS=""

# Check which scripts run in every build
for phase in "prebuild" "build" "postbuild"; do
  PHASE_CMD=$(jq -r ".scripts.$phase // \"\"" package.json)
  if [[ -n "$PHASE_CMD" ]]; then
    # Count how many generators run in this phase
    SCRIPT_COUNT=$(echo "$PHASE_CMD" | grep -o "node scripts/[^.]*\.mjs" | wc -l || echo "0")
    if (( SCRIPT_COUNT > 3 )); then
      warn "$phase runs $SCRIPT_COUNT scripts (potential bottleneck)"
      ((ISSUES++))
    else
      okay "$phase runs $SCRIPT_COUNT scripts"
    fi
  fi
done

# 8) Build dependency recommendations
echo "Generating build dependency recommendations..." | tee -a "$BUILD_LOG"
RECOMMENDATIONS=""

if (( CRITICAL > 0 )); then
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• CRITICAL: Resolve file generation conflicts immediately"
fi

if (( ISSUES > 0 )); then
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• Consider separating generated files from source files"
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• Add build script execution monitoring"
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• Implement file generation locks to prevent conflicts"
fi

if [[ -n "$GENERATED_FILES" ]]; then
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• Document which files are generated vs manually maintained"
  RECOMMENDATIONS="$RECOMMENDATIONS"$'\n'"• Consider build artifacts in separate directories"
fi

# Count findings (must occur before trace usage)
GENERATOR_COUNT=$(echo "$FILE_GENERATORS" | wc -l | tr -d ' ')
CONFLICT_COUNT=$(echo "$CONFLICTS" | grep -v '^$' | wc -l | tr -d ' ')
GENERATED_COUNT=$(echo "$GENERATED_FILES" | grep -v '^$' | wc -l | tr -d ' ')

# Update final report status
STATUS="pass"
if (( CRITICAL > 0 )); then
  STATUS="critical"
elif (( ISSUES > 0 )); then
  STATUS="warn"
fi

# Trace summary (after variables defined)
trace_issue "generator_scripts" "scripts/*" "$( (( GENERATOR_COUNT>0 )) && echo warn || echo pass )" || true
trace_issue "potential_conflicts" "src/*" "$( (( CONFLICT_COUNT>0 )) && echo critical || echo pass )" || true

# Generate final JSON report
cat > "$BUILD_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "build_dependencies",
  "status": "$STATUS",
  "findings": {
    "generator_scripts": $GENERATOR_COUNT,
    "generated_files": $GENERATED_COUNT,
    "potential_conflicts": $CONFLICT_COUNT,
    "build_phases": ["prebuild", "build", "postbuild"],
    "critical_conflicts": $(echo "$CONFLICTS" | grep "src/" | wc -l | tr -d ' ')
  },
  "counts": {
    "potential_conflicts": $CONFLICT_COUNT,
    "illegal_targets": 0
  },
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "actions": [
    $(if (( CRITICAL > 0 )); then echo '"Resolve file generation conflicts immediately",'; fi)
    $(if (( ISSUES > 0 )); then echo '"Separate generated files from source files",'; fi)
    $(if [[ -n "$GENERATED_FILES" ]]; then echo '"Document generated vs manual files",'; fi)
    "Monitor build script execution order",
    "Implement file generation conflict detection"
  ],
  "policy_invariants": [
    "counts.potential_conflicts==0",
    "counts.illegal_targets==0"
  ],
  "build_pipeline_health": {
    "has_prebuild": $(if jq -e '.scripts.prebuild' package.json >/dev/null 2>&1; then echo "true"; else echo "false"; fi),
    "has_postbuild": $(if jq -e '.scripts.postbuild' package.json >/dev/null 2>&1; then echo "true"; else echo "false"; fi),
    "script_count": $(jq '.scripts | length' package.json),
    "generator_risk": "$(if (( CRITICAL > 0 )); then echo "high"; elif (( ISSUES > 0 )); then echo "medium"; else echo "low"; fi)"
  }
}
EOF

echo "Build Dependencies Analysis Summary:" | tee -a "$BUILD_LOG"
echo "====================================" | tee -a "$BUILD_LOG"
echo "Generator scripts: $GENERATOR_COUNT" | tee -a "$BUILD_LOG"
echo "Generated files: $GENERATED_COUNT" | tee -a "$BUILD_LOG"
echo "Potential conflicts: $CONFLICT_COUNT" | tee -a "$BUILD_LOG"
echo "Issues: $ISSUES" | tee -a "$BUILD_LOG"
echo "Critical: $CRITICAL" | tee -a "$BUILD_LOG"
echo "Status: $STATUS" | tee -a "$BUILD_LOG"
echo "Report: $BUILD_REPORT" | tee -a "$BUILD_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
  exit 2
elif (( ISSUES > 0 )); then
  exit 1
else
  exit 0
fi
