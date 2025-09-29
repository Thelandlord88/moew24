#!/usr/bin/env bash
set +H  # Disable history expansion
# hunters/suburb_forensics.sh — Migration Command Center
#
# PURPOSE: Map every reference, then generate migration scripts for 121→345 expansion
# STRATEGY: Forensic analysis → Dependency mapping → Automated migration planning

set -euo pipefail
REPORT_COMPLETED=0
trap 'if [[ ! -s "$FORENSICS_REPORT" || "$REPORT_COMPLETED" != 1 ]]; then mkdir -p "${REPORT_DIR:-__reports/hunt}"; printf "{\n  \"module\": \"suburb_forensics\", \"status\": \"error\", \"issues\": %s, \"critical\": %s, \"counts\": { \"suburbs_analyzed\": 0 }\n}\n" "${ISSUES:-0}" "${CRITICAL:-0}" > "$FORENSICS_REPORT"; fi' EXIT

# Inherit environment from parent hunt.sh
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"
TIMESTAMP="${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}"
mkdir -p "$REPORT_DIR"

# Colors
if [[ -t 1 ]]; then
  RED='\e[31m'; YEL='\e[33m'; GRN='\e[32m'; CYA='\e[36m'; BLU='\e[34m'; MAG='\e[35m'; RST='\e[0m'
else
  RED=''; YEL=''; GRN=''; CYA=''; BLU=''; MAG=''; RST=''
fi

okay() { printf "${GRN}✓ %s${RST}\n" "$*"; }
warn() { printf "${YEL}⚠ %s${RST}\n" "$*"; }
fail() { printf "${RED}✗ %s${RST}\n" "$*"; }
info() { printf "${BLU}ℹ %s${RST}\n" "$*"; }
debug() { printf "${MAG}🔍 %s${RST}\n" "$*"; }

# Output files
FORENSICS_REPORT="$REPORT_DIR/suburb_forensics.json"
FORENSICS_LOG="$REPORT_DIR/suburb_forensics.log"
FORENSICS_DETAILED="$REPORT_DIR/suburb_forensics_detailed.json"
MIGRATION_SCRIPTS_DIR="$REPORT_DIR/migration_scripts"
mkdir -p "$MIGRATION_SCRIPTS_DIR"

echo "� Suburb Forensics Hunter - Migration Command Center" > "$FORENSICS_LOG"
echo "=====================================================" >> "$FORENSICS_LOG"

ISSUES=0
CRITICAL=0

# Data source paths
REGISTRY_FILE="src/data/suburbs.registry.json"
COVERAGE_FILE="src/data/serviceCoverage.json"
ADJACENCY_FILE="src/data/adjacency.json"
CLUSTERS_FILE="src/data/areas.clusters.json"

# Allow detection to proceed even if a command returns non-zero
set +e

echo "🎯 Starting comprehensive 121 suburb forensic analysis..." | tee -a "$FORENSICS_LOG"

# Check if required files exist
for file in "$REGISTRY_FILE" "$COVERAGE_FILE" "$ADJACENCY_FILE"; do
    if [[ ! -f "$file" ]]; then
        fail "Missing required file: $file"
        ((CRITICAL++))
    fi
done

if (( CRITICAL > 0 )); then
    exit 2
fi

# Extract the 121 suburbs from registry
echo "📊 Extracting 121 suburb list from registry..." | tee -a "$FORENSICS_LOG"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

jq -r '.suburbs | keys[]' "$REGISTRY_FILE" 2>/dev/null | sort > "$TEMP_DIR/suburbs_121.txt" || touch "$TEMP_DIR/suburbs_121.txt"
SUBURB_COUNT=$(wc -l < "$TEMP_DIR/suburbs_121.txt" 2>/dev/null || echo "0")

if [[ "$SUBURB_COUNT" -eq 0 ]]; then
    fail "Could not extract suburbs from registry"
    ((CRITICAL++))
    exit 2
fi

# Load target suburbs from adjacency.json (345 suburbs)
jq -r 'keys[]' "$ADJACENCY_FILE" 2>/dev/null | sort > "$TEMP_DIR/suburbs_345.txt" || touch "$TEMP_DIR/suburbs_345.txt"
TARGET_SUBURB_COUNT=$(wc -l < "$TEMP_DIR/suburbs_345.txt" 2>/dev/null || echo "0")

okay "Found $SUBURB_COUNT legacy suburbs for analysis"
info "Target: $TARGET_SUBURB_COUNT suburbs for migration"

# Initialize forensics data structure
cat > "$TEMP_DIR/forensics_data.json" <<EOF
{
  "analysis_metadata": {
    "timestamp": "$TIMESTAMP",
    "legacy_suburbs": $SUBURB_COUNT,
    "target_suburbs": $TARGET_SUBURB_COUNT,
    "analysis_scope": ["pages", "components", "utils", "data", "scripts", "styles"]
  },
  "suburbs": {},
  "dependency_matrix": {},
  "migration_blockers": [],
  "recommended_actions": [],
  "cross_references": {}
}
EOF

echo "🔍 Phase 1: Direct File References Analysis" | tee -a "$FORENSICS_LOG"

# Analyze each suburb individually
ANALYZED_COUNT=0
while IFS= read -r suburb; do
    if [[ -n "$suburb" ]]; then
        debug "Analyzing suburb: $suburb" | tee -a "$FORENSICS_LOG"
        
        # Initialize suburb data
        SUBURB_DATA=$(cat <<EOF
{
  "slug": "$suburb",
  "direct_references": {
    "count": 0,
    "files": []
  },
  "page_generation": {
    "service_pages": [],
    "area_pages": [],
    "suburb_pages": []
  },
  "component_usage": {
    "imported_by": [],
    "props_references": [],
    "getStaticPaths": []
  },
  "link_targets": {
    "internal_links_to": [],
    "internal_links_from": [],
    "navigation_items": []
  },
  "button_analysis": {
    "cta_buttons": [],
    "navigation_buttons": [],
    "form_buttons": []
  },
  "data_relationships": {
    "in_service_coverage": false,
    "in_adjacency": false,
    "state_in_registry": "unknown"
  }
}
EOF
)
        
        # 1. Find all direct file references
        echo "  🔍 Searching for direct references to '$suburb'..." | tee -a "$FORENSICS_LOG"
        
        # Search in all source files (simplified ripgrep) - with sanitization
        DIRECT_REFS=$(rg -i "$suburb" src/ -g '!node_modules' -g '!dist' -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # Search for slug patterns - with sanitization
        SLUG_REFS=$(rg -i "slug.*$suburb|$suburb.*slug" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # Search for URL patterns - with sanitization
        URL_REFS=$(rg -i "/$suburb/|/$suburb\"|'$suburb'|\"$suburb\"" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # Ensure all variables are valid numbers
        DIRECT_REFS=$(echo "$DIRECT_REFS" | grep -o '^[0-9]\+' || echo "0")
        SLUG_REFS=$(echo "$SLUG_REFS" | grep -o '^[0-9]\+' || echo "0")
        URL_REFS=$(echo "$URL_REFS" | grep -o '^[0-9]\+' || echo "0")
        
        TOTAL_REFS=$((DIRECT_REFS + SLUG_REFS + URL_REFS))
        
        echo "    📈 Found $TOTAL_REFS total references ($DIRECT_REFS direct, $SLUG_REFS slug, $URL_REFS URL)" | tee -a "$FORENSICS_LOG"
        
        # 2. Check data source presence
        echo "  🗄️ Checking data source presence..." | tee -a "$FORENSICS_LOG"
        
        # Fix: Clean variable extraction with sanitization
        IN_COVERAGE=$(jq -e ".[] | index(\"$suburb\")" "$COVERAGE_FILE" 2>/dev/null | wc -l | head -1 | tr -d '\n' | xargs || echo "0")
        IN_ADJACENCY=$(jq -e "has(\"$suburb\")" "$ADJACENCY_FILE" 2>/dev/null | head -1 | tr -d '\n' || echo "false")
        
        # Check clusters file if it exists
        IN_CLUSTERS=$([ -f "$CLUSTERS_FILE" ] && jq -e ".clusters[].suburbs | index(\"$suburb\")" "$CLUSTERS_FILE" 2>/dev/null | wc -l | head -1 | tr -d '\n' | xargs || echo "0")
        
        REGISTRY_STATE=$(jq -r ".suburbs.\"$suburb\".state // \"not_found\"" "$REGISTRY_FILE" 2>/dev/null | head -1 | tr -d '\n' || echo "not_found")
        
        # Sanitize all variables thoroughly
        IN_COVERAGE=$(echo "$IN_COVERAGE" | grep -o '^[0-9]\+' | head -1 || echo "0")
        IN_CLUSTERS=$(echo "$IN_CLUSTERS" | grep -o '^[0-9]\+' | head -1 || echo "0")
        
        echo "    📊 Coverage: $IN_COVERAGE, Adjacency: $IN_ADJACENCY, Clusters: $IN_CLUSTERS, Registry: $REGISTRY_STATE" | tee -a "$FORENSICS_LOG"
        
        # 3. Find getStaticPaths usage
        echo "  ⚡ Analyzing page generation patterns..." | tee -a "$FORENSICS_LOG"
        STATIC_PATHS_COUNT=$(rg -A5 -B5 "getStaticPaths" src/pages/ 2>/dev/null | rg -i "$suburb" -c 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        
        # 4. Find component imports and usage
        echo "  🧩 Analyzing component usage..." | tee -a "$FORENSICS_LOG"
        COMPONENT_IMPORT_COUNT=$(rg "import.*$suburb|from.*$suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # 5. Find button and link patterns
        echo "  🔗 Analyzing links and buttons..." | tee -a "$FORENSICS_LOG"
        LINK_COUNT=$(rg -i "href.*$suburb|to.*$suburb|link.*$suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        BUTTON_COUNT=$(rg -i "button.*$suburb|onclick.*$suburb|click.*$suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # 6. Find FAQ, navigation, and selector usage
        FAQ_COUNT=$(rg -i "faq.*$suburb|$suburb.*faq" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        NAV_COUNT=$(rg -i "nav.*$suburb|$suburb.*nav|navigation.*$suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        SELECTOR_COUNT=$(rg -i "select.*$suburb|$suburb.*select|dropdown.*$suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # Sanitize all count variables
        STATIC_PATHS_COUNT=$(echo "$STATIC_PATHS_COUNT" | grep -o '^[0-9]\+' || echo "0")
        COMPONENT_IMPORT_COUNT=$(echo "$COMPONENT_IMPORT_COUNT" | grep -o '^[0-9]\+' || echo "0")
        LINK_COUNT=$(echo "$LINK_COUNT" | grep -o '^[0-9]\+' || echo "0")
        BUTTON_COUNT=$(echo "$BUTTON_COUNT" | grep -o '^[0-9]\+' || echo "0")
        FAQ_COUNT=$(echo "$FAQ_COUNT" | grep -o '^[0-9]\+' || echo "0")
        NAV_COUNT=$(echo "$NAV_COUNT" | grep -o '^[0-9]\+' || echo "0")
        SELECTOR_COUNT=$(echo "$SELECTOR_COUNT" | grep -o '^[0-9]\+' || echo "0")
        
        # 7. Find hardcoded arrays (migration blockers)
        echo "  ⚠️ Identifying hardcoded dependencies..." | tee -a "$FORENSICS_LOG"
        
        # Ensure we get clean numeric values
        HARDCODED_ARRAYS=$(rg -A2 -B2 '\[.*"[^"]*",.*"[^"]*",.*"[^"]*".*\]' src/ 2>/dev/null | rg -i "\"$suburb\"" -c 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        HARDCODED_OBJECTS=$(rg -A2 -B2 '\{.*"[^"]*":.*"[^"]*",.*"[^"]*":.*"[^"]*".*\}' src/ 2>/dev/null | rg -i "\"$suburb\"" -c 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        SWITCH_CASES=$(rg -A5 -B5 'case.*"[^"]*":|case.*\([^)]*\):' src/ 2>/dev/null | rg -i "\"$suburb\"" -c 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        CONDITIONALS=$(rg -i "if.*===.*\"$suburb\"|\"$suburb\".*===.*if" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' | head -1 | tr -d '\n' || echo "0")
        
        # Clean up any non-numeric characters and ensure valid numbers
        HARDCODED_ARRAYS=$(echo "$HARDCODED_ARRAYS" | grep -o '[0-9]*' | head -1)
        HARDCODED_OBJECTS=$(echo "$HARDCODED_OBJECTS" | grep -o '[0-9]*' | head -1)
        SWITCH_CASES=$(echo "$SWITCH_CASES" | grep -o '[0-9]*' | head -1)
        CONDITIONALS=$(echo "$CONDITIONALS" | grep -o '[0-9]*' | head -1)
        
        # Set default values if empty
        HARDCODED_ARRAYS=${HARDCODED_ARRAYS:-0}
        HARDCODED_OBJECTS=${HARDCODED_OBJECTS:-0}
        SWITCH_CASES=${SWITCH_CASES:-0}
        CONDITIONALS=${CONDITIONALS:-0}
        
        HARD_TOTAL=$((HARDCODED_ARRAYS + HARDCODED_OBJECTS + SWITCH_CASES + CONDITIONALS))
        
        if [[ "$HARD_TOTAL" -gt 0 ]]; then
            echo "    🚨 Found $HARD_TOTAL hardcoded dependencies for $suburb" | tee -a "$FORENSICS_LOG"
            ((ISSUES++))
        fi
        
        # Update detailed data (fix jq parameter handling)
        jq --arg suburb "$suburb" \
           --arg total_refs "$TOTAL_REFS" \
           --arg in_coverage "$IN_COVERAGE" \
           --arg in_adjacency "$IN_ADJACENCY" \
           --arg in_clusters "$IN_CLUSTERS" \
           --arg registry_state "$REGISTRY_STATE" \
           --arg static_paths_count "$STATIC_PATHS_COUNT" \
           --arg component_count "$COMPONENT_IMPORT_COUNT" \
           --arg link_count "$LINK_COUNT" \
           --arg button_count "$BUTTON_COUNT" \
           --arg faq_count "$FAQ_COUNT" \
           --arg nav_count "$NAV_COUNT" \
           --arg selector_count "$SELECTOR_COUNT" \
           --arg hard_arrays "$HARDCODED_ARRAYS" \
           --arg hard_objects "$HARDCODED_OBJECTS" \
           --arg switch_cases "$SWITCH_CASES" \
           --arg conditionals "$CONDITIONALS" \
           --arg hard_total "$HARD_TOTAL" \
           '.suburbs[$suburb] = {
             "slug": $suburb,
             "total_references": ($total_refs | tonumber),
             "data_relationships": {
               "in_service_coverage": (($in_coverage | tonumber) > 0),
               "in_adjacency": ($in_adjacency == "true"),
               "in_clusters": (($in_clusters | tonumber) > 0),
               "state_in_registry": $registry_state
             },
             "usage_analysis": {
               "static_paths_count": ($static_paths_count | tonumber),
               "component_import_count": ($component_count | tonumber),
               "link_count": ($link_count | tonumber),
               "button_count": ($button_count | tonumber),
               "faq_usage_count": ($faq_count | tonumber),
               "navigation_usage_count": ($nav_count | tonumber),
               "selector_usage_count": ($selector_count | tonumber)
             },
             "hardcoded_dependencies": {
               "arrays": ($hard_arrays | tonumber),
               "objects": ($hard_objects | tonumber),
               "switch_cases": ($switch_cases | tonumber),
               "conditionals": ($conditionals | tonumber),
               "total": ($hard_total | tonumber)
             }
           }' "$TEMP_DIR/forensics_data.json" > "$TEMP_DIR/forensics_data.tmp" && mv "$TEMP_DIR/forensics_data.tmp" "$TEMP_DIR/forensics_data.json"
        
        ((ANALYZED_COUNT++))
        
        # Progress indicator
        if (( ANALYZED_COUNT % 10 == 0 )); then
            info "Progress: $ANALYZED_COUNT/$SUBURB_COUNT suburbs analyzed"
        fi
        
    fi
done < "$TEMP_DIR/suburbs_121.txt"

echo "🔍 Phase 2: Cross-Reference Analysis" | tee -a "$FORENSICS_LOG"

# Analyze cross-references between suburbs
echo "  🔗 Building suburb cross-reference matrix..." | tee -a "$FORENSICS_LOG"

# Find adjacent suburb references
while IFS= read -r suburb; do
    if [[ -n "$suburb" ]]; then
        # Find other suburbs mentioned in same files as this suburb
        RELATED_SUBURBS=$(rg -l "$suburb" src/ --type astro --type js --type ts 2>/dev/null | xargs -I {} rg -o '[a-z][a-z-]*[a-z]' {} 2>/dev/null | grep -v "$suburb" | sort | uniq -c | sort -nr | head -10 || true)
        
        # Add to cross-reference data
        if [[ -n "$RELATED_SUBURBS" ]]; then
            debug "Found cross-references for $suburb" | tee -a "$FORENSICS_LOG"
        fi
    fi
done < "$TEMP_DIR/suburbs_121.txt"

echo "🔍 Phase 3: Component and Pattern Analysis" | tee -a "$FORENSICS_LOG"

# Analyze common patterns
echo "  🧩 Analyzing common component patterns..." | tee -a "$FORENSICS_LOG"

# Find FAQ components
FAQ_USAGE_COUNT=$(rg -i "faq.*suburb|suburb.*faq" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' || echo "0")

# Find navigation components  
NAV_USAGE_COUNT=$(rg -i "nav.*suburb|suburb.*nav|navigation.*suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' || echo "0")

# Find selector/dropdown components
SELECTOR_USAGE_COUNT=$(rg -i "select.*suburb|suburb.*select|dropdown.*suburb" src/ -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}' || echo "0")

echo "    📊 FAQ usage: $FAQ_USAGE_COUNT, Navigation: $NAV_USAGE_COUNT, Selectors: $SELECTOR_USAGE_COUNT" | tee -a "$FORENSICS_LOG"

echo "🔍 Phase 3: Migration Blocker Analysis" | tee -a "$FORENSICS_LOG"

# Identify migration blockers
BLOCKER_COUNT=0

# Find all hardcoded dependencies
HARDCODED_TOTAL=$(jq '[.suburbs[] | .hardcoded_dependencies.total] | add // 0' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")
SWITCH_TOTAL=$(jq '[.suburbs[] | .hardcoded_dependencies.switch_cases] | add // 0' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")

echo "  🚨 Total hardcoded dependencies: $HARDCODED_TOTAL" | tee -a "$FORENSICS_LOG"
echo "  🚨 Total switch cases: $SWITCH_TOTAL" | tee -a "$FORENSICS_LOG"

# Generate migration scripts for critical files
if [[ "$HARDCODED_TOTAL" -gt 0 ]]; then
    echo "  🛠️ Generating migration scripts for hardcoded dependencies..." | tee -a "$FORENSICS_LOG"
    
    # Create migration script for service coverage
    cat > "$MIGRATION_SCRIPTS_DIR/update_service_coverage.sh" <<'EOF'
#!/bin/bash
# Migration script: Update serviceCoverage.json to include all 345 suburbs

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
COVERAGE_FILE="$ROOT/src/data/serviceCoverage.json"
ADJACENCY_FILE="$ROOT/src/data/adjacency.json"

# Backup current file
cp "$COVERAGE_FILE" "$COVERAGE_FILE.bak.$(date +%Y%m%d-%H%M%S)"

# Get all suburbs from adjacency.json
ALL_SUBURBS=$(jq -r 'keys[]' "$ADJACENCY_FILE" | sort)

# Update serviceCoverage.json
jq --argjson suburbs "$(echo "$ALL_SUBURBS" | jq -R -s 'split("\n")[:-1]')" '
  .[] = $suburbs
' "$COVERAGE_FILE" > "$COVERAGE_FILE.tmp" && mv "$COVERAGE_FILE.tmp" "$COVERAGE_FILE"

echo "✅ Updated serviceCoverage.json with all $(echo "$ALL_SUBURBS" | wc -l) suburbs"
EOF

    chmod +x "$MIGRATION_SCRIPTS_DIR/update_service_coverage.sh"
    okay "Generated service coverage migration script"
    
    # Create component migration script
    cat > "$MIGRATION_SCRIPTS_DIR/migrate_components.sh" <<'EOF'
#!/bin/bash
# Migration script: Replace hardcoded suburb arrays with dynamic providers

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)

# Create dynamic suburb provider
cat > "$ROOT/src/lib/suburbProvider.js" << 'EOL'
// src/lib/suburbProvider.js
import fs from 'node:fs';
import path from 'node:path';

const DATA_DIR = path.join(process.cwd(), 'src/data');

class SuburbProvider {
    constructor() {
        this.suburbs = null;
        this.adjacency = null;
        this.coverage = null;
    }
    
    async loadSuburbs() {
        if (!this.suburbs) {
            const adjacencyPath = path.join(DATA_DIR, 'adjacency.json');
            const adjacency = JSON.parse(fs.readFileSync(adjacencyPath, 'utf-8'));
            
            // Extract all unique suburbs from adjacency data
            this.suburbs = [...new Set(Object.keys(adjacency).flatMap(key => [key, ...adjacency[key]]))];
        }
        return this.suburbs;
    }
    
    async loadServiceCoverage() {
        if (!this.coverage) {
            const coveragePath = path.join(DATA_DIR, 'serviceCoverage.json');
            this.coverage = JSON.parse(fs.readFileSync(coveragePath, 'utf-8'));
        }
        return this.coverage;
    }
    
    async getSuburbsForService(service) {
        const coverage = await this.loadServiceCoverage();
        return coverage[service] || [];
    }
    
    async getAllServices() {
        const coverage = await this.loadServiceCoverage();
        return Object.keys(coverage);
    }
    
    async getAdjacentSuburbs(suburb) {
        if (!this.adjacency) {
            const adjacencyPath = path.join(DATA_DIR, 'adjacency.json');
            this.adjacency = JSON.parse(fs.readFileSync(adjacencyPath, 'utf-8'));
        }
        return this.adjacency[suburb] || [];
    }
}

export const suburbProvider = new SuburbProvider();
EOL

echo "✅ Created dynamic suburb provider"

# Update components to use dynamic provider (example)
echo "⚠️ Manual update required: Replace hardcoded arrays in components with dynamic provider"
echo "Example replacement:"
echo "BEFORE: const suburbs = ['anstead', 'ashgrove', ...];"
echo "AFTER: const suburbs = await suburbProvider.loadSuburbs();"
EOF

    chmod +x "$MIGRATION_SCRIPTS_DIR/migrate_components.sh"
    okay "Generated component migration script"
fi

echo "🔍 Phase 4: Migration Readiness Assessment" | tee -a "$FORENSICS_LOG"

# Determine status
STATUS="pass"
if (( CRITICAL > 0 )); then
    STATUS="critical"
elif (( ISSUES > 0 )); then
    STATUS="warn"
fi

# Generate comprehensive JSON report
set +e

# Calculate summary statistics
TOTAL_REFERENCES=$(jq '[.suburbs[] | .total_references] | add // 0' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")
SUBURBS_IN_COVERAGE=$(jq '[.suburbs[] | select(.data_relationships.in_service_coverage == true)] | length' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")
SUBURBS_IN_ADJACENCY=$(jq '[.suburbs[] | select(.data_relationships.in_adjacency == true)] | length' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")
SUBURBS_IN_CLUSTERS=$(jq '[.suburbs[] | select(.data_relationships.in_clusters == true)] | length' "$TEMP_DIR/forensics_data.json" 2>/dev/null || echo "0")

# Determine status
STATUS="pass"
if (( CRITICAL > 0 )); then
    STATUS="critical"
elif (( ISSUES > 0 )); then
    STATUS="warn"
fi

# Migration readiness
READY_FOR_MIGRATION="false"
if [[ "$HARDCODED_TOTAL" -eq 0 && "$SWITCH_TOTAL" -eq 0 ]]; then
    READY_FOR_MIGRATION="true"
fi

# Generate comprehensive JSON report
set +e

cp "$TEMP_DIR/forensics_data.json" "$FORENSICS_DETAILED"

cat > "$FORENSICS_REPORT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "suburb_forensics",
  "status": "$STATUS",
  "critical_issues": $CRITICAL,
  "warning_issues": $ISSUES,
  "issues_total": $((CRITICAL + ISSUES)),
  "findings": {
    "suburbs_analyzed": $ANALYZED_COUNT,
    "total_references_found": $TOTAL_REFERENCES,
    "suburbs_in_coverage": $SUBURBS_IN_COVERAGE,
    "suburbs_in_adjacency": $SUBURBS_IN_ADJACENCY,
    "suburbs_in_clusters": $SUBURBS_IN_CLUSTERS,
    "hardcoded_dependencies": {
      "total": $HARDCODED_TOTAL,
      "switch_cases": $SWITCH_TOTAL
    }
  },
  "detailed_analysis_file": "suburb_forensics_detailed.json",
  "migration_scripts_dir": "migration_scripts",
  "policy_invariants": [
    "findings.hardcoded_dependencies.total == 0",
    "findings.suburbs_analyzed == $SUBURB_COUNT",
    "findings.critical_issues == 0"
  ],
  "recommendations": [
    "Run generated migration scripts to update serviceCoverage.json",
    "Replace hardcoded suburb arrays with dynamic suburbProvider",
    "Implement feature flags for staged migration",
    "Test adjacency-based navigation before full deployment"
  ],
  "migration_readiness": {
    "ready_for_migration": $READY_FOR_MIGRATION,
    "blockers_found": $HARDCODED_TOTAL,
    "complexity_score": $([ "$ANALYZED_COUNT" -gt 0 ] && echo $((TOTAL_REFERENCES / ANALYZED_COUNT)) || echo "0"),
    "migration_scripts_generated": $([ "$HARDCODED_TOTAL" -gt 0 ] && echo "true" || echo "false")
  },
  "upstream_analysis": {
    "box": "121 legacy suburbs blocking geo expansion to 345",
    "closet": "Hidden dependencies, hardcoded references, component coupling",
    "policy": "Complete forensic analysis before migration (zero blind spots)",
    "vision": "Geographic market domination through mathematical adjacency intelligence"
  }
}
EOF
set -e

REPORT_COMPLETED=1
sync || true

# Summary
echo | tee -a "$FORENSICS_LOG"
echo "Suburb Forensics Analysis Summary:" | tee -a "$FORENSICS_LOG"
echo "=================================" | tee -a "$FORENSICS_LOG"
echo "Suburbs Analyzed: $ANALYZED_COUNT" | tee -a "$FORENSICS_LOG"
echo "Total References: $TOTAL_REFERENCES" | tee -a "$FORENSICS_LOG"
echo "Hardcoded Dependencies: $HARDCODED_TOTAL" | tee -a "$FORENSICS_LOG"
echo "Switch Cases: $SWITCH_TOTAL" | tee -a "$FORENSICS_LOG"
echo "Issues: $ISSUES" | tee -a "$FORENSICS_LOG"
echo "Critical: $CRITICAL" | tee -a "$FORENSICS_LOG"
echo "Status: $STATUS" | tee -a "$FORENSICS_LOG"
echo "Migration Ready: $READY_FOR_MIGRATION" | tee -a "$FORENSICS_LOG"
echo "Main Report: $FORENSICS_REPORT" | tee -a "$FORENSICS_LOG"
echo "Detailed Data: $FORENSICS_DETAILED" | tee -a "$FORENSICS_LOG"
echo "Migration Scripts: $MIGRATION_SCRIPTS_DIR" | tee -a "$FORENSICS_LOG"

# Exit with appropriate code
if (( CRITICAL > 0 )); then
    exit 2  # Critical issues
elif (( ISSUES > 0 )); then
    exit 1  # Warning issues
else
    exit 0  # Clean
fi
