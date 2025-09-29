#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/geo_consistency.sh — Geo System Data Integrity
#
# PURPOSE: Detect data inconsistencies between geo data sources
# ELIMINATION TARGET: Orphaned adjacency refs, data source mismatches, broken links
#
# Box: Geo system data inconsistencies causing 404s and user confusion
# Closet: Multiple disconnected data sources without sync validation
# Policy: Geo consistency hunter + invariant: zero orphaned references (strict mode)

set -euo pipefail
REPORT_COMPLETED=0
trap 'if [[ ! -s "$GEO_REPORT" || "$REPORT_COMPLETED" != 1 ]]; then mkdir -p "${REPORT_DIR:-__reports/hunt}"; printf "{\n  \"module\": \"geo_consistency\", \"status\": \"error\", \"issues\": %s, \"critical\": %s, \"counts\": { \"orphaned_adjacency\": 0 }\n}\n" "${ISSUES:-0}" "${CRITICAL:-0}" > "$GEO_REPORT"; fi' EXIT

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
GEO_REPORT="$REPORT_DIR/geo_consistency.json"
GEO_LOG="$REPORT_DIR/geo_consistency.log"

echo "🧭 Geo Consistency Hunter - Data Integrity Validation" > "$GEO_LOG"
echo "====================================================" >> "$GEO_LOG"

ISSUES=0
CRITICAL=0

# Data source paths
ADJACENCY_FILE="src/data/adjacency.json"
REGISTRY_FILE="src/data/suburbs.registry.json"
COVERAGE_FILE="src/data/serviceCoverage.json"

# Allow detection to proceed even if a command returns non-zero
set +e

echo "📊 Analyzing suburb counts across systems..." | tee -a "$GEO_LOG"

# Check if required files exist
for file in "$ADJACENCY_FILE" "$REGISTRY_FILE" "$COVERAGE_FILE"; do
    if [[ ! -f "$file" ]]; then
        fail "Missing required geo data file: $file"
        ((CRITICAL++))
        # Can't continue without data files
        set -e
        REPORT_COMPLETED=1
        exit 2
    fi
done

# Extract suburb counts safely
ADJACENCY_COUNT=$(jq -r 'keys | length' "$ADJACENCY_FILE" 2>/dev/null || echo "0")
REGISTRY_COUNT=$(jq -r '.suburbs | keys | length' "$REGISTRY_FILE" 2>/dev/null || echo "0")
COVERAGE_BOND_COUNT=$(jq -r '.["bond-cleaning"] | length' "$COVERAGE_FILE" 2>/dev/null || echo "0")
COVERAGE_SPRING_COUNT=$(jq -r '.["spring-cleaning"] | length' "$COVERAGE_FILE" 2>/dev/null || echo "0")
COVERAGE_BATHROOM_COUNT=$(jq -r '.["bathroom-deep-clean"] | length' "$COVERAGE_FILE" 2>/dev/null || echo "0")

echo "  • Adjacency system: $ADJACENCY_COUNT suburbs" | tee -a "$GEO_LOG"
echo "  • Registry system: $REGISTRY_COUNT suburbs" | tee -a "$GEO_LOG"
echo "  • Service coverage - bond-cleaning: $COVERAGE_BOND_COUNT suburbs" | tee -a "$GEO_LOG"
echo "  • Service coverage - spring-cleaning: $COVERAGE_SPRING_COUNT suburbs" | tee -a "$GEO_LOG"
echo "  • Service coverage - bathroom-deep-clean: $COVERAGE_BATHROOM_COUNT suburbs" | tee -a "$GEO_LOG"

# Check for service coverage inconsistencies
if [[ "$COVERAGE_BOND_COUNT" != "$COVERAGE_SPRING_COUNT" ]] || [[ "$COVERAGE_BOND_COUNT" != "$COVERAGE_BATHROOM_COUNT" ]]; then
    fail "Service coverage counts are inconsistent across services"
    ((CRITICAL++))
else
    okay "Service coverage counts are consistent across all services"
fi

echo "🔗 Checking for orphaned adjacency references..." | tee -a "$GEO_LOG"

# Create temp files for comparison
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract suburb lists (with error handling)
jq -r 'keys[]' "$ADJACENCY_FILE" 2>/dev/null | sort > "$TEMP_DIR/adjacency_suburbs.txt" || touch "$TEMP_DIR/adjacency_suburbs.txt"
jq -r '.suburbs | keys[]' "$REGISTRY_FILE" 2>/dev/null | sort > "$TEMP_DIR/registry_suburbs.txt" || touch "$TEMP_DIR/registry_suburbs.txt"
jq -r '.["bond-cleaning"][]' "$COVERAGE_FILE" 2>/dev/null | sort > "$TEMP_DIR/coverage_suburbs.txt" || touch "$TEMP_DIR/coverage_suburbs.txt"

# Find orphaned adjacency suburbs
ORPHANED_COUNT=0
if [[ -s "$TEMP_DIR/adjacency_suburbs.txt" && -s "$TEMP_DIR/registry_suburbs.txt" ]]; then
    ORPHANED_COUNT=$(comm -23 "$TEMP_DIR/adjacency_suburbs.txt" "$TEMP_DIR/registry_suburbs.txt" | wc -l || echo "0")
    if [[ "$ORPHANED_COUNT" -gt 0 ]]; then
        fail "Found $ORPHANED_COUNT orphaned suburbs in adjacency system (exist in adjacency but not in registry)"
        ((CRITICAL++))
        
        # Show some examples
        ORPHANED_EXAMPLES=$(comm -23 "$TEMP_DIR/adjacency_suburbs.txt" "$TEMP_DIR/registry_suburbs.txt" 2>/dev/null | head -3 | paste -sd ',' - 2>/dev/null || echo "unable to extract examples")
        echo "  Examples: $ORPHANED_EXAMPLES" | tee -a "$GEO_LOG"
    else
        okay "No orphaned adjacency references found"
    fi
fi

# Check for registry suburbs missing from service coverage
MISSING_FROM_COVERAGE_COUNT=0
DEPRECATED_COUNT=0
if [[ -s "$TEMP_DIR/registry_suburbs.txt" && -s "$TEMP_DIR/coverage_suburbs.txt" ]]; then
    echo "🔍 Analyzing registry vs service coverage..." | tee -a "$GEO_LOG"
    
    MISSING_FROM_COVERAGE=$(comm -23 "$TEMP_DIR/registry_suburbs.txt" "$TEMP_DIR/coverage_suburbs.txt" 2>/dev/null || true)
    
    if [[ -n "$MISSING_FROM_COVERAGE" ]]; then
        while IFS= read -r suburb; do
            if [[ -n "$suburb" ]]; then
                STATE=$(jq -r ".suburbs.\"$suburb\".state // \"unknown\"" "$REGISTRY_FILE" 2>/dev/null || echo "unknown")
                if [[ "$STATE" == "deprecated" ]]; then
                    ((DEPRECATED_COUNT++))
                    echo "  • Suburb '$suburb' correctly excluded from coverage (deprecated)" | tee -a "$GEO_LOG"
                elif [[ "$STATE" == "staged" ]]; then
                    warn "Suburb '$suburb' is staged in registry but missing from service coverage"
                    ((ISSUES++))
                elif [[ "$STATE" == "published" ]]; then
                    fail "Suburb '$suburb' is published in registry but missing from service coverage"
                    ((CRITICAL++))
                else
                    warn "Suburb '$suburb' has unknown state '$STATE' in registry"
                    ((ISSUES++))
                fi
                ((MISSING_FROM_COVERAGE_COUNT++))
            fi
        done <<< "$MISSING_FROM_COVERAGE"
    fi
    
    if [[ "$MISSING_FROM_COVERAGE_COUNT" -eq "$DEPRECATED_COUNT" && "$DEPRECATED_COUNT" -gt 0 ]]; then
        okay "Registry/coverage difference explained by $DEPRECATED_COUNT deprecated suburbs"
    fi
fi

# Check for coverage suburbs missing from registry
COVERAGE_MISSING_FROM_REGISTRY_COUNT=0
if [[ -s "$TEMP_DIR/registry_suburbs.txt" && -s "$TEMP_DIR/coverage_suburbs.txt" ]]; then
    COVERAGE_MISSING_FROM_REGISTRY=$(comm -13 "$TEMP_DIR/registry_suburbs.txt" "$TEMP_DIR/coverage_suburbs.txt" 2>/dev/null || true)
    if [[ -n "$COVERAGE_MISSING_FROM_REGISTRY" ]]; then
        COVERAGE_MISSING_FROM_REGISTRY_COUNT=$(echo "$COVERAGE_MISSING_FROM_REGISTRY" | grep -v '^$' | wc -l || echo "0")
    fi
    
    if [[ "$COVERAGE_MISSING_FROM_REGISTRY_COUNT" -gt 0 ]]; then
        fail "Found $COVERAGE_MISSING_FROM_REGISTRY_COUNT suburbs in service coverage but missing from registry"
        ((CRITICAL++))
        COVERAGE_MISSING_EXAMPLES=$(echo "$COVERAGE_MISSING_FROM_REGISTRY" | head -3 | paste -sd ',' - 2>/dev/null || echo "none")
        echo "  Examples: $COVERAGE_MISSING_EXAMPLES" | tee -a "$GEO_LOG"
    else
        okay "All service coverage suburbs exist in registry"
    fi
fi

# Determine status
STATUS="pass"
if (( CRITICAL > 0 )); then
    STATUS="critical"
elif (( ISSUES > 0 )); then
    STATUS="warn"
fi

# Generate JSON report
set +e
cat > "$GEO_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "geo_consistency",
  "status": "$STATUS",
  "critical_issues": $CRITICAL,
  "warning_issues": $ISSUES,
  "issues_total": $((CRITICAL + ISSUES)),
  "findings": {
    "adjacency_count": $ADJACENCY_COUNT,
    "registry_count": $REGISTRY_COUNT,
    "coverage_bond_count": $COVERAGE_BOND_COUNT,
    "coverage_spring_count": $COVERAGE_SPRING_COUNT,
    "coverage_bathroom_count": $COVERAGE_BATHROOM_COUNT,
    "orphaned_adjacency_suburbs": $ORPHANED_COUNT,
    "registry_missing_from_coverage": $MISSING_FROM_COVERAGE_COUNT,
    "coverage_missing_from_registry": $COVERAGE_MISSING_FROM_REGISTRY_COUNT,
    "deprecated_suburbs_found": $DEPRECATED_COUNT
  },
  "policy_invariants": [
    "findings.orphaned_adjacency_suburbs == 0",
    "findings.coverage_missing_from_registry == 0",
    "findings.critical_issues == 0"
  ],
  "recommendations": [
    "Clean up orphaned adjacency references",
    "Sync registry and service coverage data",
    "Implement automated data validation",
    "Add build-time consistency checks"
  ],
  "upstream_analysis": {
    "box": "Geo system data inconsistencies causing 404s and user confusion",
    "closet": "Multiple disconnected data sources without sync validation",
    "policy": "Geo consistency hunter + invariant: zero orphaned references (strict mode)"
  }
}
EOF
set -e

REPORT_COMPLETED=1
sync || true

# Summary
echo | tee -a "$GEO_LOG"
echo "Geo Consistency Analysis Summary:" | tee -a "$GEO_LOG"
echo "================================" | tee -a "$GEO_LOG"
echo "Issues: $ISSUES" | tee -a "$GEO_LOG"
echo "Critical: $CRITICAL" | tee -a "$GEO_LOG"
echo "Status: $STATUS" | tee -a "$GEO_LOG"
echo "Report: $GEO_REPORT" | tee -a "$GEO_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
    exit 2  # Critical issues
elif (( ISSUES > 0 )); then
    exit 1  # Warning issues
else
    exit 0  # Clean
fi
