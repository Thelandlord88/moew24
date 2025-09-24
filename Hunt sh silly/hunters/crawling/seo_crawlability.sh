#!/bin/bash
# SEO Crawlability Hunter - Makes every page crawlable and worth crawling
# Purpose-built for comprehensive SEO health with content-level gates

set -euo pipefail

# Configuration from environment
TARGET_LEVEL="${TARGET_LEVEL:-enhanced}"  # basic/enhanced/premium
MAX_DEPTH="${MAX_DEPTH:-3}"               # Maximum crawl depth
STRICT="${STRICT:-0}"                     # Exit on failures when 1
BUILD_FIRST="${BUILD_FIRST:-1}"           # Build before audit when 1

OUT_DIR="__reports/hunt"
OUT_FILE="$OUT_DIR/seo_crawl.json"
DIST_DIR="dist"

mkdir -p "$OUT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[seo-crawl]${NC} $*"; }
warn() { echo -e "${YELLOW}[seo-crawl]${NC} $*"; }
error() { echo -e "${RED}[seo-crawl]${NC} $*"; }
success() { echo -e "${GREEN}[seo-crawl]${NC} $*"; }

# Initialize counters
total_pages=0
passed_pages=0
failed_pages=0
orphan_pages=0
deep_pages=0
noindex_pages=0
missing_canonical=0
missing_title=0
missing_description=0
missing_h1=0
bad_heading_order=0
missing_alt_text=0
below_content_level=0

declare -A page_depths
declare -A page_links
declare -A page_issues
declare -A page_archetypes
declare -A content_levels

# Build if requested
if [[ "$BUILD_FIRST" == "1" ]]; then
    log "Building site first..."
    if ! npm run build > /dev/null 2>&1; then
        error "Build failed. Cannot audit non-existent pages."
        exit 1
    fi
    success "Build completed"
fi

# Check if dist exists
if [[ ! -d "$DIST_DIR" ]]; then
    error "Distribution directory '$DIST_DIR' not found. Run build first or set BUILD_FIRST=1"
    exit 1
fi

log "Starting SEO crawlability audit..."
log "Target content level: $TARGET_LEVEL"
log "Maximum crawl depth: $MAX_DEPTH"
log "Strict mode: $([[ $STRICT == "1" ]] && echo "ON" || echo "OFF")"

# Find all HTML pages
pages=($(find "$DIST_DIR" -name "*.html" -type f | sort))
total_pages=${#pages[@]}

if [[ $total_pages -eq 0 ]]; then
    error "No HTML pages found in $DIST_DIR"
    exit 1
fi

log "Found $total_pages HTML pages to audit"

# Function to extract page archetype based on URL pattern
get_page_archetype() {
    local url="$1"
    case "$url" in
        "/index.html"|"/") echo "home" ;;
        "/services/"*) echo "service" ;;
        "/blog/"*) echo "blog" ;;
        "/areas/"*|"/bond-cleaning/"*) echo "suburb" ;;
        "/quote/"*) echo "conversion" ;;
        "/gallery/"*|"/privacy/"*|"/terms/"*) echo "generic" ;;
        *) echo "generic" ;;
    esac
}

# Function to assess content level
assess_content_level() {
    local file="$1"
    local score=0
    
    # Basic checks (1 point each)
    grep -q "<title>" "$file" && ((score++))
    grep -q 'name="description"' "$file" && ((score++))
    grep -q "<h1>" "$file" && ((score++))
    
    # Enhanced checks (2 points each)  
    grep -q 'application/ld\+json' "$file" && ((score+=2))
    [[ $(grep -c "<h[2-6]>" "$file") -gt 2 ]] && ((score+=2))
    [[ $(grep -c 'href.*#' "$file") -gt 0 ]] && ((score+=2))
    
    # Premium checks (3 points each)
    [[ $(grep -c 'alt=' "$file") -gt 3 ]] && ((score+=3))
    grep -q 'FAQ' "$file" && ((score+=3))
    [[ $(wc -w < "$file") -gt 500 ]] && ((score+=3))
    
    # Determine level
    if [[ $score -ge 15 ]]; then
        echo "premium"
    elif [[ $score -ge 8 ]]; then
        echo "enhanced" 
    else
        echo "basic"
    fi
}

# Function to check heading order
check_heading_order() {
    local file="$1"
    
    # Count h1 tags - should be exactly 1
    local h1_count=$(grep -c '<h1' "$file" 2>/dev/null || echo "0")
    
    # Simple check: if we have one h1, order is probably fine
    if [[ $h1_count -eq 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to extract internal links
extract_internal_links() {
    local file="$1"
    grep -oP 'href="\K[^"]*(?=")' "$file" 2>/dev/null | \
    grep -E '^(/|\./)' | \
    sed 's|^\./||' | \
    sed 's|/index\.html$|/|' | \
    sed 's|\.html$||' | \
    sort -u
}

# Build link graph first pass
log "Building internal link graph..."
for page in "${pages[@]}"; do
    rel_path="${page#$DIST_DIR}"
    url_path="${rel_path%/index.html}"
    [[ "$url_path" == "/index" ]] && url_path="/"
    
    page_links["$url_path"]=$(extract_internal_links "$page" | tr '\n' '|')
    page_depths["$url_path"]=999  # Initialize to high value
done

# Calculate page depths via BFS
page_depths["/"]=0
changed=true
while [[ "$changed" == true ]]; do
    changed=false
    for url in "${!page_depths[@]}"; do
        current_depth=${page_depths["$url"]}
        if [[ $current_depth -ne 999 ]]; then
            IFS='|' read -ra links <<< "${page_links["$url"]}"
            for link in "${links[@]}"; do
                [[ -z "$link" ]] && continue
                new_depth=$((current_depth + 1))
                if [[ ${page_depths["$link"]:-999} -gt $new_depth ]]; then
                    page_depths["$link"]=$new_depth
                    changed=true
                fi
            done
        fi
    done
done

# Audit each page
log "Auditing individual pages..."
for page in "${pages[@]}"; do
    rel_path="${page#$DIST_DIR}"
    url_path="${rel_path%/index.html}"
    [[ "$url_path" == "/index" ]] && url_path="/"
    
    issues=()
    
    # Get page archetype and content level
    archetype=$(get_page_archetype "$url_path")
    content_level=$(assess_content_level "$page")
    page_archetypes["$url_path"]="$archetype"
    content_levels["$url_path"]="$content_level"
    
    # Check robots
    if grep -q 'name="robots".*noindex' "$page"; then
        issues+=("noindex")
        ((noindex_pages++))
    fi
    
    # Check canonical
    if ! grep -q 'rel="canonical"' "$page"; then
        issues+=("missing_canonical")
        ((missing_canonical++))
    fi
    
    # Check title
    if ! grep -q "<title>" "$page" || grep -q "<title></title>" "$page"; then
        issues+=("missing_title") 
        ((missing_title++))
    fi
    
    # Check meta description
    if ! grep -q 'name="description"' "$page"; then
        issues+=("missing_description")
        ((missing_description++))
    fi
    
    # Check H1
    h1_count=$(grep -c "<h1>" "$page" || echo "0")
    if [[ $h1_count -eq 0 ]]; then
        issues+=("missing_h1")
        ((missing_h1++))
    elif [[ $h1_count -gt 1 ]]; then
        issues+=("multiple_h1")
    fi
    
    # Check heading order
    if [[ $(check_heading_order "$page") == "false" ]]; then
        issues+=("bad_heading_order")
        ((bad_heading_order++))
    fi
    
    # Check alt text (for images)
    img_count=$(grep -c "<img" "$page" || echo "0")
    alt_count=$(grep -c 'alt=' "$page" || echo "0")
    if [[ $img_count -gt 0 && $alt_count -lt $img_count ]]; then
        issues+=("missing_alt_text")
        ((missing_alt_text++))
    fi
    
    # Check depth
    depth=${page_depths["$url_path"]:-999}
    if [[ $depth -eq 999 ]]; then
        issues+=("orphaned")
        ((orphan_pages++))
    elif [[ $depth -gt $MAX_DEPTH ]]; then
        issues+=("too_deep")
        ((deep_pages++))
    fi
    
    # Check content level
    case "$TARGET_LEVEL" in
        "premium")
            if [[ "$content_level" != "premium" ]]; then
                issues+=("below_content_level")
                ((below_content_level++))
            fi
            ;;
        "enhanced")
            if [[ "$content_level" == "basic" ]]; then
                issues+=("below_content_level") 
                ((below_content_level++))
            fi
            ;;
    esac
    
    # Archetype-specific checks
    case "$archetype" in
        "service"|"suburb")
            if ! grep -q 'FAQPage\|QAPage' "$page"; then
                issues+=("missing_faq_schema")
            fi
            ;;
        "blog")
            if ! grep -q 'Article\|BlogPosting' "$page"; then
                issues+=("missing_article_schema")
            fi
            ;;
    esac
    
    page_issues["$url_path"]=$(IFS=,; echo "${issues[*]}")
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        ((passed_pages++))
    else
        ((failed_pages++))
    fi
done

# Generate JSON report
log "Generating detailed report..."
{
    echo "{"
    echo "  \"module\": \"seo_crawlability\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"config\": {"
    echo "    \"target_level\": \"$TARGET_LEVEL\","
    echo "    \"max_depth\": $MAX_DEPTH,"
    echo "    \"strict\": $STRICT"
    echo "  },"
    echo "  \"summary\": {"
    echo "    \"total_pages\": $total_pages,"
    echo "    \"passed_pages\": $passed_pages,"
    echo "    \"failed_pages\": $failed_pages,"
    echo "    \"issues\": {"
    echo "      \"orphan_pages\": $orphan_pages,"
    echo "      \"deep_pages\": $deep_pages,"
    echo "      \"noindex_pages\": $noindex_pages,"
    echo "      \"missing_canonical\": $missing_canonical,"
    echo "      \"missing_title\": $missing_title,"
    echo "      \"missing_description\": $missing_description,"
    echo "      \"missing_h1\": $missing_h1,"
    echo "      \"bad_heading_order\": $bad_heading_order,"
    echo "      \"missing_alt_text\": $missing_alt_text,"
    echo "      \"below_content_level\": $below_content_level"
    echo "    }"
    echo "  },"
    echo "  \"pages\": ["
    
    first=true
    for url in "${!page_issues[@]}"; do
        [[ "$first" == true ]] && first=false || echo ","
        echo -n "    {"
        echo -n "\"url\": \"$url\", "
        echo -n "\"archetype\": \"${page_archetypes["$url"]}\", "
        echo -n "\"content_level\": \"${content_levels["$url"]}\", "
        echo -n "\"depth\": ${page_depths["$url"]:-999}, "
        echo -n "\"issues\": [$(echo "${page_issues["$url"]}" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/' | sed 's/""//g')]"
        echo -n "}"
    done
    echo ""
    echo "  ],"
    
    # Status determination
    status="pass"
    if [[ $STRICT == "1" ]]; then
        if [[ $noindex_pages -gt 0 || $orphan_pages -gt 0 || $deep_pages -gt 0 || $missing_canonical -gt 0 || $below_content_level -gt 0 ]]; then
            status="fail"
        fi
    fi
    
    echo "  \"status\": \"$status\","
    echo "  \"actions\": ["
    [[ $missing_canonical -gt 0 ]] && echo "    \"Inject canonical tags for $missing_canonical pages\","
    [[ $orphan_pages -gt 0 ]] && echo "    \"Generate internal links to de-orphan $orphan_pages pages\","
    [[ $below_content_level -gt 0 ]] && echo "    \"Enhance content level for $below_content_level pages\","
    [[ $missing_h1 -gt 0 ]] && echo "    \"Add H1 headings to $missing_h1 pages\","
    [[ $bad_heading_order -gt 0 ]] && echo "    \"Fix heading hierarchy on $bad_heading_order pages\","
    [[ $missing_alt_text -gt 0 ]] && echo "    \"Add alt text to images on $missing_alt_text pages\""
    echo "  ]"
    echo "}"
} > "$OUT_FILE"

# Console summary
echo ""
echo -e "${BOLD}SEO Crawlability Audit Results${NC}"
echo "=================================="
echo "📊 Pages audited: $total_pages"
echo "✅ Passed: $passed_pages"
echo "❌ Failed: $failed_pages"
echo ""

if [[ $failed_pages -gt 0 ]]; then
    echo -e "${BOLD}Issues Found:${NC}"
    [[ $orphan_pages -gt 0 ]] && echo "🏝️  Orphaned pages: $orphan_pages"
    [[ $deep_pages -gt 0 ]] && echo "🕳️  Too deep (>$MAX_DEPTH): $deep_pages"
    [[ $noindex_pages -gt 0 ]] && echo "🚫 Noindex pages: $noindex_pages"
    [[ $missing_canonical -gt 0 ]] && echo "🔗 Missing canonical: $missing_canonical"
    [[ $missing_title -gt 0 ]] && echo "📄 Missing title: $missing_title"
    [[ $missing_description -gt 0 ]] && echo "📝 Missing description: $missing_description"
    [[ $missing_h1 -gt 0 ]] && echo "📰 Missing H1: $missing_h1"
    [[ $bad_heading_order -gt 0 ]] && echo "📚 Bad heading order: $bad_heading_order"
    [[ $missing_alt_text -gt 0 ]] && echo "🖼️  Missing alt text: $missing_alt_text"
    [[ $below_content_level -gt 0 ]] && echo "📈 Below $TARGET_LEVEL level: $below_content_level"
    echo ""
fi

# Content level distribution
echo -e "${BOLD}Content Level Distribution:${NC}"
basic_count=0
enhanced_count=0
premium_count=0
for level in "${content_levels[@]}"; do
    case "$level" in
        "basic") ((basic_count++)) ;;
        "enhanced") ((enhanced_count++)) ;;
        "premium") ((premium_count++)) ;;
    esac
done
echo "📋 Basic: $basic_count"
echo "📊 Enhanced: $enhanced_count" 
echo "💎 Premium: $premium_count"

success "Report written to $OUT_FILE"

# Exit with error in strict mode if issues found
if [[ $STRICT == "1" && $failed_pages -gt 0 ]]; then
    error "STRICT mode: Failing due to $failed_pages pages with issues"
    exit 1
fi

exit 0