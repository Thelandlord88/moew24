#!/bin/bash
# Magic Numbers Hunter
# Detects hardcoded numbers that should be named constants
# Part of Hunter Thinker 2.0 System - Upstream-Curious Constants Architecture

set -euo pipefail

HUNTER_NAME="magic_numbers"
REPORT_FILE="__reports/hunt/${HUNTER_NAME}.json"
MAX_MAGIC_NUMBERS=20
CRITICAL_THRESHOLD=100
WARNING_ISSUES=0
CRITICAL_ISSUES=0

# ---- Intensity & CLI flags ---------------------------------------------------
SEARCH_MODE="fast"            # fast | deep
MAX_PER_DOMAIN_DEFAULT=20     # used in fast mode
COMMON_SAMPLE_LINES_DEFAULT=100

# Defaults (fast)
MAX_PER_DOMAIN="$MAX_PER_DOMAIN_DEFAULT"
COMMON_SAMPLE_LINES="$COMMON_SAMPLE_LINES_DEFAULT"
INCLUDE_TESTS=0
INCLUDE_DIST=0
INCLUDE_MINIFIED=0

# File globs and excludes (fast)
FILE_GLOBS=( "*.ts" "*.js" "*.mjs" "*.cjs" "*.astro" )
EXCLUDES=( "node_modules" "build" "coverage" ".git" ".cache" )

# Helpers
cap() {                       # cap <N>  -> head -n N, or pass-through if N<=0
  local n="${1:-0}"
  if [[ "$n" -le 0 ]]; then cat; else head -n "$n"; fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --intense|--mode=deep) SEARCH_MODE="deep" ;;
    --mode=fast)           SEARCH_MODE="fast" ;;
    --max-per-domain=*)    MAX_PER_DOMAIN="${1#*=}" ;;
    --common-sample=*)     COMMON_SAMPLE_LINES="${1#*=}" ;;
    --include-tests)       INCLUDE_TESTS=1 ;;
    --include-dist)        INCLUDE_DIST=1 ;;
    --include-minified)    INCLUDE_MINIFIED=1 ;;
    --help|-h)
      cat <<'USAGE'
Magic Numbers Hunter — extra flags:
  --intense | --mode=deep     Run a thorough search (no caps, broader file types)
  --mode=fast                 Use quick defaults (caps & narrower scope)
  --max-per-domain=N          Override per-domain preview cap (0 = unlimited)
  --common-sample=N           Override "common values" sample lines (0 = unlimited)
  --include-tests             Include tests/specs/mocks directories
  --include-dist              Include dist/build/public (usually excluded)
  --include-minified          Do not auto-skip *.min.* files
USAGE
      exit 0
      ;;
  esac
  shift
done

# Apply mode presets
if [[ "$SEARCH_MODE" == "deep" ]]; then
  MAX_PER_DOMAIN=0
  COMMON_SAMPLE_LINES=0
  FILE_GLOBS=( "*.ts" "*.tsx" "*.js" "*.jsx" "*.mjs" "*.cjs" "*.astro" "*.vue" "*.svelte" "*.md" "*.mdx" "*.html" "*.css" )
  EXCLUDES=( ".git" )  # only ignore VCS in deep mode
  INCLUDE_TESTS=1
fi

# Expand excludes based on flags
if [[ $INCLUDE_TESTS -eq 0 ]]; then
  EXCLUDES+=( "tests" "test" "__tests__" "spec" "mocks" "fixtures" )
fi
if [[ $INCLUDE_DIST -eq 0 ]]; then
  EXCLUDES+=( "dist" "build" "public" ".next" ".output" ".vercel" )
fi

# Grep driver: prefer ripgrep for speed, fall back to grep/find
SEARCHER="grep"
if has_cmd rg; then SEARCHER="rg"; fi

collect_hits() {
  # collect_hits <pattern> <root>
  local pattern="$1"; shift
  local root="${1:-.}"

  if [[ "$SEARCHER" == "rg" ]]; then
    # Build ripgrep args
    local args=( -n --no-ignore --hidden -U -I )
    for e in "${EXCLUDES[@]}"; do args+=( -g "!$e/**" ); done
    if [[ $INCLUDE_MINIFIED -eq 0 ]]; then args+=( -g "!**/*.min.*" ); fi
    for g in "${FILE_GLOBS[@]}"; do args+=( -g "$g" ); done
    rg "${args[@]}" -e "$pattern" "$root"
  else
    # POSIX-ish fallback: find + grep
    local find_cmd=( find "$root" -type f )
    # include only files matching FILE_GLOBS
    local glob_expr=()
    for g in "${FILE_GLOBS[@]}"; do
      glob_expr+=( -name "$g" -o )
    done
    # trim trailing -o
    [[ ${#glob_expr[@]} -gt 0 ]] && unset 'glob_expr[${#glob_expr[@]}-1]'
    local prune_expr=()
    for e in "${EXCLUDES[@]}"; do
      prune_expr+=( -path "*/$e/*" -prune -o )
    done
    # assemble: prune -> (name globs) -> print
    # shellcheck disable=SC2016
    "${find_cmd[@]}" \( "${prune_expr[@]}" -false \) -o \( "${glob_expr[@]}" -print \) \
      | ( [[ $INCLUDE_MINIFIED -eq 0 ]] && grep -Ev '\.min\.' || cat ) \
      | xargs -r grep -nE -- "$pattern" || true
  fi
}
# ------------------------------------------------------------------------------

echo "🔢 MAGIC NUMBERS HUNTER"
echo "======================="
echo "Upstream Focus: Eliminate hardcoded numbers through centralized constants"
echo "Search Mode: $SEARCH_MODE | Max per domain: $MAX_PER_DOMAIN | Searcher: $SEARCHER"
echo "Max magic numbers: $MAX_MAGIC_NUMBERS (Critical: >$CRITICAL_THRESHOLD)"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize report structure
cat > "$REPORT_FILE" << 'EOF'
{
  "hunter": "magic_numbers",
  "version": "2.0",
  "methodology": "upstream_curious",
  "timestamp": "",
  "critical_issues": 0,
  "warning_issues": 0,
  "status": "unknown",
  "config": {
    "max_magic_numbers": 20,
    "critical_threshold": 100,
    "search_mode": "fast",
    "limits": {
      "max_per_domain": 20,
      "common_sample_lines": 100
    },
    "files": {
      "globs": "",
      "excludes": ""
    }
  },
  "findings": {
    "magic_numbers": [],
    "patterns_detected": {},
    "domains_affected": [],
    "refactoring_opportunities": []
  },
  "metrics": {
    "total_magic_count": 0,
    "files_with_magic": 0,
    "domains_count": 0
  },
  "upstream_analysis": {
    "box": "",
    "closet": "",
    "policy": ""
  },
  "recommendations": []
}
EOF

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TIMESTAMP" '.timestamp = $ts' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Persist mode & caps in the JSON report (optional, safe if jq present)
if has_cmd jq && [[ -f "$REPORT_FILE" ]]; then
  jq \
    --arg mode "$SEARCH_MODE" \
    --argjson mpd "${MAX_PER_DOMAIN:-0}" \
    --argjson csl "${COMMON_SAMPLE_LINES:-0}" \
    --arg ftypes "$(printf '%s ' "${FILE_GLOBS[@]}")" \
    --arg excls "$(printf '%s ' "${EXCLUDES[@]}")" \
    '.config.search_mode=$mode
     | .config.limits.max_per_domain=$mpd
     | .config.limits.common_sample_lines=$csl
     | .config.files.globs=$ftypes
     | .config.files.excludes=$excls' \
    "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
fi

echo "🔍 Scanning for magic number patterns..."
CONSTANTS_FILE="src/constants/index.ts"
DECLARED_VALUES=()
if [[ -f "$CONSTANTS_FILE" ]]; then
    # Extract numeric literals exported as constants (simple heuristic)
    while IFS= read -r val; do [[ -n "$val" ]] && DECLARED_VALUES+=("$val"); done < <(grep -Eo '[0-9]+' "$CONSTANTS_FILE" | sort -u)
fi

# Define patterns for different types of magic numbers
declare -A MAGIC_PATTERNS=(
    ["cache_control"]="max-age=[0-9]+"
    ["timeouts"]="setTimeout.*[0-9]{3,}|delay.*[0-9]{3,}"
    ["pricing"]="price.*[0-9]+\.[0-9]+|cost.*[0-9]+\.[0-9]+"
    ["dimensions"]="width.*[0-9]+|height.*[0-9]+|size.*[0-9]+"
    ["http_codes"]="[^a-zA-Z][45][0-9][0-9][^0-9]"
    ["percentages"]="[0-9]+%|[0-9]+\.[0-9]+%"
    ["array_indices"]="[a-zA-Z]\[[0-9]+\]"
    ["magic_constants"]="[^0-9][0-9]{2,}[^0-9]"
)

MAGIC_INSTANCES=()
TOTAL_MAGIC_COUNT=0
declare -A DOMAIN_COUNTS=()

# Scan for each pattern type
for domain in "${!MAGIC_PATTERNS[@]}"; do
    pattern=${MAGIC_PATTERNS[$domain]}
    domain_count=0
    
    echo "  🔍 Checking $domain patterns..."
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            content=$(echo "$line" | cut -d: -f3-)
            
            # Skip common non-magic numbers
            if [[ "$content" =~ (0|1|2|3|4|5|6|7|8|9|10|100)$ ]]; then
                continue
            fi
            
            # Skip imports and requires
            if [[ "$content" =~ (import|require|from) ]]; then
                continue
            fi
            
                        # Filter if number already declared in constants registry
                        skip_declared=0
                        for dv in "${DECLARED_VALUES[@]}"; do
                            if echo "$content" | grep -q "${dv}"; then skip_declared=1; break; fi
                        done
                        if (( skip_declared==1 )); then continue; fi
                        MAGIC_INSTANCES+=("$domain:$file:$line_num:$content")
            TOTAL_MAGIC_COUNT=$((TOTAL_MAGIC_COUNT + 1))
            domain_count=$((domain_count + 1))
            
            # Show preview (respecting cap for display)
            if [[ $domain_count -le 15 ]]; then
                echo "    ⚠️  $domain in $file:$line_num"
                echo "       → $(echo "$content" | xargs | cut -c1-80)"
            fi
        fi
    done < <(collect_hits "$pattern" "src" | cap "$MAX_PER_DOMAIN")
    
    if [[ $domain_count -gt 0 ]]; then
        DOMAIN_COUNTS[$domain]=$domain_count
        echo "    Found $domain_count $domain magic numbers"
    fi
done

# Show truncation message if applicable
if [[ $TOTAL_MAGIC_COUNT -gt 15 && $MAX_PER_DOMAIN -gt 0 ]]; then
    echo "    ... (showing first 15, limited by --max-per-domain=$MAX_PER_DOMAIN)"
elif [[ $TOTAL_MAGIC_COUNT -gt 15 ]]; then
    echo "    ... and $((TOTAL_MAGIC_COUNT - 15)) more magic numbers"
fi

echo ""
echo "🔍 Analyzing common hardcoded values..."

# Look for commonly repeated values that should be constants
COMMON_VALUES=()
declare -A VALUE_COUNTS=()

# Extract numeric values and count occurrences
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Extract numbers from the line
        numbers=$(echo "$line" | grep -oE '[0-9]+\.?[0-9]*' | head -5)
        while IFS= read -r number; do
            if [[ -n "$number" ]] && [[ ! "$number" =~ ^[0-9]$ ]]; then
                VALUE_COUNTS[$number]=$((${VALUE_COUNTS[$number]:-0} + 1))
            fi
        done <<< "$numbers"
    fi
done < <(collect_hits '[0-9]+' "src" | cap "$COMMON_SAMPLE_LINES")

# Find values that appear multiple times (likely constants)
for value in "${!VALUE_COUNTS[@]}"; do
    count=${VALUE_COUNTS[$value]}
    if [[ $count -gt 2 ]]; then
        COMMON_VALUES+=("$value:$count")
        echo "  🎯 Value '$value' appears $count times (constant candidate)"
    fi
done

echo ""
echo "🔍 Checking for domain-specific hardcoded patterns..."

# Look for business-specific magic numbers
BUSINESS_PATTERNS=(
    "bedroom.*[0-9]+\.?[0-9]*"
    "cleaning.*[0-9]+\.?[0-9]*"
    "hour.*[0-9]+\.?[0-9]*"
    "room.*[0-9]+\.?[0-9]*"
    "rate.*[0-9]+\.?[0-9]*"
)

for pattern in "${BUSINESS_PATTERNS[@]}"; do
    pattern_name=$(echo "$pattern" | cut -d'.' -f1)
    count=$(collect_hits "$pattern" "src" | wc -l)
    count=${count// /}  # Remove any whitespace
    if [[ $count -gt 0 ]]; then
        echo "  💼 Found $count business-specific $pattern_name values"
        DOMAIN_COUNTS["business_$pattern_name"]=$count
    fi
done

# Count unique files with magic numbers
FILES_WITH_MAGIC=0
if [[ ${#MAGIC_INSTANCES[@]} -gt 0 ]]; then
    FILES_WITH_MAGIC=$(printf '%s\n' "${MAGIC_INSTANCES[@]}" | cut -d: -f2 | sort -u | wc -l)
fi

echo ""
echo "📊 Magic Numbers Analysis:"
echo "  Total magic numbers found: $TOTAL_MAGIC_COUNT"
echo "  Files with magic numbers: $FILES_WITH_MAGIC"
echo "  Pattern domains detected: ${#DOMAIN_COUNTS[@]}"
echo "  Common repeated values: ${#COMMON_VALUES[@]}"

# Determine issue severity
if [[ $TOTAL_MAGIC_COUNT -gt $CRITICAL_THRESHOLD ]]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    echo "❌ CRITICAL: $TOTAL_MAGIC_COUNT magic numbers exceed critical threshold ($CRITICAL_THRESHOLD)"
elif [[ $TOTAL_MAGIC_COUNT -gt $MAX_MAGIC_NUMBERS ]]; then
    WARNING_ISSUES=$((WARNING_ISSUES + 1))
    echo "⚠️  WARNING: $TOTAL_MAGIC_COUNT magic numbers exceed recommended limit ($MAX_MAGIC_NUMBERS)"
fi

# Check if constants file exists
CONSTANTS_FILE_EXISTS=false
if [[ -f "src/constants/index.ts" ]] || [[ -f "src/lib/constants.ts" ]] || [[ -f "src/config/constants.ts" ]]; then
    CONSTANTS_FILE_EXISTS=true
    echo "✅ Constants file found"
else
    echo "⚠️  No centralized constants file found"
    WARNING_ISSUES=$((WARNING_ISSUES + 1))
fi

# Prepare data for JSON report
MAGIC_INSTANCES_JSON="[]"
if [[ ${#MAGIC_INSTANCES[@]} -gt 0 ]]; then
    # Limit instances for JSON report to prevent bloat
    max_instances=50
    if [[ $SEARCH_MODE == "deep" ]]; then
        max_instances=200
    fi
    MAGIC_INSTANCES_JSON=$(printf '%s\n' "${MAGIC_INSTANCES[@]}" | head -"$max_instances" | jq -R 'split(":") | {domain: .[0], file: .[1], line: (.[2] | tonumber), content: (.[3:] | join(":"))}' | jq -s .)
fi

DOMAIN_COUNTS_JSON="{}"
if [[ ${#DOMAIN_COUNTS[@]} -gt 0 ]]; then
    # Build JSON object properly
    DOMAIN_COUNTS_JSON="{"
    first_item=true
    for domain in "${!DOMAIN_COUNTS[@]}"; do
        if [[ "$first_item" == "true" ]]; then
            first_item=false
        else
            DOMAIN_COUNTS_JSON+=","
        fi
        DOMAIN_COUNTS_JSON+="\"$domain\": ${DOMAIN_COUNTS[$domain]}"
    done
    DOMAIN_COUNTS_JSON+="}"
fi

COMMON_VALUES_JSON="[]"
if [[ ${#COMMON_VALUES[@]} -gt 0 ]]; then
    COMMON_VALUES_JSON=$(printf '%s\n' "${COMMON_VALUES[@]}" | jq -R 'split(":") | {value: .[0], count: (.[1] | tonumber)}' | jq -s .)
fi

# Update report with findings
jq --argjson critical "$CRITICAL_ISSUES" \
   --argjson warning "$WARNING_ISSUES" \
   --argjson magic_instances "$MAGIC_INSTANCES_JSON" \
   --argjson patterns "$DOMAIN_COUNTS_JSON" \
   --argjson total_magic "$TOTAL_MAGIC_COUNT" \
   --argjson files_with_magic "$FILES_WITH_MAGIC" \
   --argjson domains_count "${#DOMAIN_COUNTS[@]}" \
   '.critical_issues = $critical | 
    .warning_issues = $warning | 
    .findings.magic_numbers = $magic_instances | 
    .findings.patterns_detected = $patterns | 
    .metrics.total_magic_count = $total_magic | 
    .metrics.files_with_magic = $files_with_magic | 
    .metrics.domains_count = $domains_count' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Determine status and upstream analysis
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    STATUS="critical"
    EXIT_CODE=2
    UPSTREAM_BOX="Severe magic number proliferation ($TOTAL_MAGIC_COUNT instances) creating maintenance nightmare"
    UPSTREAM_CLOSET="Missing centralized constants architecture with domain-specific organization"
    UPSTREAM_POLICY="Implement comprehensive constants system with domain grouping and strict validation"
elif [[ $WARNING_ISSUES -gt 0 ]] || [[ $TOTAL_MAGIC_COUNT -gt $MAX_MAGIC_NUMBERS ]]; then
    STATUS="warn"
    EXIT_CODE=1
    UPSTREAM_BOX="Moderate magic number usage ($TOTAL_MAGIC_COUNT instances) reducing code maintainability"
    UPSTREAM_CLOSET="Constants management needs improvement with better organization patterns"
    UPSTREAM_POLICY="Gradual magic number elimination with domain-specific constant groups"
else
    STATUS="pass"
    EXIT_CODE=0
    UPSTREAM_BOX="Good constants usage with minimal magic numbers"
    UPSTREAM_CLOSET="Proper separation of configuration from implementation"
    UPSTREAM_POLICY="Maintain constants discipline through continued monitoring"
fi

# Update upstream analysis
jq --arg status "$STATUS" \
   --arg box "$UPSTREAM_BOX" \
   --arg closet "$UPSTREAM_CLOSET" \
   --arg policy "$UPSTREAM_POLICY" \
   '.status = $status | 
    .upstream_analysis.box = $box | 
    .upstream_analysis.closet = $closet | 
    .upstream_analysis.policy = $policy' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Generate constants system recommendations
RECOMMENDATIONS=()

if [[ $TOTAL_MAGIC_COUNT -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Create src/constants/index.ts with domain-specific constant groups"
        "Group constants by business domain: PRICING, CACHE, UI, TIMEOUTS"
        "Use const assertions 'as const' for type safety and IntelliSense"
        "Replace repeated values with named constants (found ${#COMMON_VALUES[@]} candidates)"
    )
    
    # Domain-specific recommendations
    if [[ ${DOMAIN_COUNTS[cache_control]:-0} -gt 0 ]]; then
        RECOMMENDATIONS+=("Create CACHE_CONSTANTS group for max-age and cache control values")
    fi
    
    if [[ ${DOMAIN_COUNTS[pricing]:-0} -gt 0 ]]; then
        RECOMMENDATIONS+=("Create PRICING_CONSTANTS for business rates and costs")
    fi
    
    if [[ ${DOMAIN_COUNTS[timeouts]:-0} -gt 0 ]]; then
        RECOMMENDATIONS+=("Create TIMEOUT_CONSTANTS for delays and intervals")
    fi
    
    if [[ ${DOMAIN_COUNTS[dimensions]:-0} -gt 0 ]]; then
        RECOMMENDATIONS+=("Create UI_CONSTANTS for component dimensions and breakpoints")
    fi
fi

if [[ ! "$CONSTANTS_FILE_EXISTS" == "true" ]]; then
    RECOMMENDATIONS+=(
        "Set up centralized constants architecture with TypeScript support"
        "Use barrel exports for easy importing: export * from './constants'"
        "Document constants with JSDoc comments explaining their purpose"
    )
fi

# Universal constants recommendations
RECOMMENDATIONS+=(
    "Use environment variables for deployment-specific values"
    "Create typed constants with interfaces for complex configurations"
    "Implement constants validation for required values"
    "Use readonly modifiers to prevent accidental mutations"
    "Group related constants in namespaces or nested objects"
)

# Convert recommendations to JSON and update report
RECOMMENDATIONS_JSON=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
jq --argjson recs "$RECOMMENDATIONS_JSON" '.recommendations = $recs' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo ""
echo "Magic Numbers Analysis Summary:"
echo "=============================="
echo "Issues: $(($CRITICAL_ISSUES + $WARNING_ISSUES))"
echo "Critical: $CRITICAL_ISSUES"
echo "Warning: $WARNING_ISSUES"
echo "Total Magic Numbers: $TOTAL_MAGIC_COUNT"
echo "Status: $STATUS"
echo "Report: $REPORT_FILE"

if [[ $TOTAL_MAGIC_COUNT -gt 0 ]]; then
    echo ""
    echo "💡 UPSTREAM-CURIOUS CONSTANTS STRATEGY:"
    echo "Class Problem: Magic numbers fragment configuration and reduce maintainability"
    echo "Upstream Fix: Centralized constants system with domain organization"
    echo ""
    echo "Constants Architecture Example:"
    echo "// src/constants/index.ts"
    echo "export const PRICING_CONSTANTS = {"
    echo "  MIN_BEDROOM_PRICE: 250,"
    echo "  MAX_BEDROOM_PRICE: 500,"
    echo "  PRICE_PER_BEDROOM: 83.33"
    echo "} as const;"
    echo ""
    echo "export const CACHE_CONSTANTS = {"
    echo "  SITEMAP_MAX_AGE: 300,"
    echo "  STATIC_MAX_AGE: 3600"
    echo "} as const;"
    echo ""
    echo "Usage: import { PRICING_CONSTANTS } from '~/constants';"
    echo ""
fi

if [[ $EXIT_CODE -eq 2 ]]; then
    echo "❌ magic_numbers: critical issues"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠ magic_numbers: issues found"
else
    echo "✅ magic_numbers: passed"
fi

exit $EXIT_CODE
