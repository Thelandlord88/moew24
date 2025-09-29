#!/bin/bash
# SEO Crawlability Hunter - Makes every page crawlable and worth crawling
# Purpose-built for comprehensive SEO health with content-level gates

set -uo pipefail

# Configuration from environment
TARGET_LEVEL="${TARGET_LEVEL:-enhanced}"  # basic/enhanced/premium
MAX_DEPTH="${MAX_DEPTH:-3}"               # Maximum crawl depth
STRICT="${STRICT:-0}"                     # Exit on failures when 1
BUILD_FIRST="${BUILD_FIRST:-1}"           # Build before audit when 1

OUT_DIR="__reports/hunt"
OUT_FILE="$OUT_DIR/seo_crawl.json"
DEPTHS_JSON="$OUT_DIR/seo_depths.json"
DIST_DIR="dist"

mkdir -p "$OUT_DIR"

# Node.js helper to compute page depths via BFS (avoids Bash array subscript issues)
compute_depths() {
  node <<'NODE'
  const fs=require('fs'), path=require('path');
  const dist=process.env.DIST_DIR||'dist';

  function walk(dir){ const out=[]; for(const n of fs.readdirSync(dir)){
    const p=path.join(dir,n), s=fs.statSync(p);
    if(s.isDirectory()) out.push(...walk(p));
    else if(n.toLowerCase().endsWith('.html')) out.push(p);
  } return out; }

  function routeFromFile(f){
    let r=f.replace(/\\/g,'/').replace(new RegExp('^'+dist.replace(/[-/\\^$*+?.()|[\\]{}]/g,'\\$&')+'/'),'/');
    if (r.endsWith('/index.html')) r=r.slice(0,-'/index.html'.length);
    else if (r.endsWith('.html')) r=r.slice(0,-'.html'.length);
    if (!r.startsWith('/')) r='/'+r;
    if (r !== '/' && !r.endsWith('/')) r+='/';
    return r;
  }

  const files=walk(dist);
  const pages=new Map();                         // route -> html
  for (const f of files) pages.set(routeFromFile(f), fs.readFileSync(f,'utf8'));

  const edges=new Map();                         // route -> [child routes]
  for (const [route, html] of pages){
    const links=[...html.matchAll(/<a\b[^>]*href=(["'])(.*?)\1/gi)].map(m=>m[2]);
    const outs=new Set();
    for (let h of links){
      if (!h || /^mailto:/i.test(h) || /^#/i.test(h)) continue;
      
      // Handle same-domain absolute URLs by converting to relative
      if (/^https?:\/\//i.test(h)) {
        const siteBase = 'https://onendonebondclean.com.au';
        if (h.startsWith(siteBase)) {
          h = h.substring(siteBase.length) || '/';
        } else {
          continue; // Skip external URLs
        }
      }
      
      h=h.replace(/#.*$/,'').replace(/\?.*$/,'');                   // strip fragment/query
      if (!h.startsWith('/')) h=path.posix.normalize(path.posix.join(route, h));
      if (h !== '/' && !h.endsWith('/')) h+='/';
      outs.add(h);
    }
    edges.set(route, Array.from(outs));
  }

  // BFS depths from '/'
  const depth=new Map(); const q=['/']; depth.set('/',0);
  while(q.length){
    const cur=q.shift();
    for (const nxt of (edges.get(cur)||[])){
      if (!depth.has(nxt) && pages.has(nxt)){ depth.set(nxt,(depth.get(cur)||0)+1); q.push(nxt); }
    }
  }

  const obj={}; for (const [k,v] of depth) obj[k]=v;
  console.log(JSON.stringify(obj));
NODE
}

# Helper to get depth for a specific URL
depth_for() {
  local abs_path="$(pwd)/$DEPTHS_JSON"
  node -e "const d=require('$abs_path'); const k=process.argv[1]; process.stdout.write(String(d[k] ?? 999));" "$1"
}

# Advanced content validation functions
extract_jsonld() {
  # Extract first JSON-LD script from an HTML file
  awk 'BEGIN{p=0} /<script[^>]*type="application\/ld\+json"[^>]*>/{p=1;next} /<\/script>/{if(p){p=0;print "";exit}} p{printf "%s",$0}' "$1"
}

has_local_business_schema() {
  local file="$1"
  local jl="$(extract_jsonld "$file")"
  if [[ -n "$jl" ]]; then
    echo "$jl" | grep -q '"@type"' && \
    echo "$jl" | grep -q 'LocalBusiness' && \
    echo "$jl" | grep -q '"areaServed"' && \
    echo "$jl" | grep -q '"geo"' && echo "yes" || echo "no"
  else
    echo "no"
  fi
}

check_performance_budget() {
  local file="$1"
  local max_size=$((120*1024))  # 120KB
  local gz_size=$(gzip -c "$file" | wc -c)
  if [[ $gz_size -le $max_size ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

has_image_preload() {
  local file="$1"
  # Check for modern performance optimization patterns
  local preload_count=$(grep -c 'rel="preload".*as="image"' "$file" 2>/dev/null || echo "0")
  local fetchpriority_count=$(grep -c 'fetchpriority="high"' "$file" 2>/dev/null || echo "0")
  local eager_loading=$(grep -c 'loading="eager"' "$file" 2>/dev/null || echo "0")
  
  # Page has performance optimization if it has any of these patterns
  if [[ $preload_count -gt 0 || $fetchpriority_count -gt 0 || $eager_loading -gt 0 ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

check_sitemap_inclusion() {
  local url="$1"
  local sitemap="${DIST_DIR}/sitemap.xml"
  if [[ -f "$sitemap" ]] && grep -q "$url" "$sitemap"; then
    echo "yes"
  else
    echo "no"
  fi
}

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
verbose() { echo -e "${BLUE}[verbose]${NC} $*"; }

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
missing_local_schema=0
exceeds_performance_budget=0
missing_image_preload=0
not_in_sitemap=0

# Simple arrays for storing page data (no complex keys)
declare -a page_urls
declare -a page_archetypes  
declare -a content_levels
declare -a page_issues_list

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
        "/"|"/index.html") echo "home" ;;
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
    grep -q "<title>" "$file" 2>/dev/null && ((score++))
    grep -q 'name="description"' "$file" 2>/dev/null && ((score++))
    grep -q "<h1" "$file" 2>/dev/null && ((score++))
    
    # Enhanced checks (2 points each)  
    grep -q 'application/ld\+json' "$file" 2>/dev/null && ((score+=2))
    
    local h_count=0
    if grep -q "<h[2-6]>" "$file" 2>/dev/null; then
        h_count=$(grep -c "<h[2-6]>" "$file" 2>/dev/null)
        [[ $h_count -gt 2 ]] && ((score+=2))
    fi
    
    grep -q 'href.*#' "$file" 2>/dev/null && ((score+=2))
    
    # Premium checks (3 points each)
    local alt_count=0
    if grep -q 'alt=' "$file" 2>/dev/null; then
        alt_count=$(grep -c 'alt=' "$file" 2>/dev/null)
        [[ $alt_count -gt 3 ]] && ((score+=3))
    fi
    
    grep -q 'FAQ' "$file" 2>/dev/null && ((score+=3))
    
    local word_count=0
    word_count=$(wc -w < "$file" 2>/dev/null | tr -d ' \n' || echo "0")
    [[ $word_count -gt 500 ]] && ((score+=3))
    
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

# Compute page depths using Node.js helper
log "Computing page depths via link graph..."
compute_depths > "$DEPTHS_JSON"
log "Link graph analysis completed"

# Audit each page
log "Auditing individual pages..."
page_index=0
for page in "${pages[@]}"; do
    rel_path="${page#$DIST_DIR}"
    url_path="${rel_path%/index.html}"
    [[ "$url_path" == "/index" ]] && url_path="/"
    
    # Normalize URL for consistency with Node.js helper
    if [[ "$url_path" != "/" && ! "$url_path" =~ /$ ]]; then
        url_path="$url_path/"
    fi
    
    issues=()
    
    # Get page archetype and content level
    archetype=$(get_page_archetype "$url_path")
    content_level=$(assess_content_level "$page")
    
    # Store in simple arrays
    page_urls[$page_index]="$url_path"
    page_archetypes[$page_index]="$archetype"
    content_levels[$page_index]="$content_level"
    
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
    h1_count=0
    if grep -q "<h1" "$page" 2>/dev/null; then
        h1_count=$(grep -c "<h1" "$page" 2>/dev/null)
    fi
    
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
    img_count=0
    alt_count=0
    
    if grep -q "<img" "$page" 2>/dev/null; then
        img_count=$(grep -c "<img" "$page" 2>/dev/null)
    fi
    
    if grep -q 'alt=' "$page" 2>/dev/null; then
        alt_count=$(grep -c 'alt=' "$page" 2>/dev/null)
    fi
    
    if [[ $img_count -gt 0 && $alt_count -lt $img_count ]]; then
        issues+=("missing_alt_text")
        ((missing_alt_text++))
    fi
    
    # Check depth using Node.js helper
    depth=$(depth_for "$url_path")
    
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
            # Advanced geo/local business checks
            if [[ $(has_local_business_schema "$page") != "yes" ]]; then
                issues+=("missing_local_schema")
                ((missing_local_schema++))
            fi
            ;;
        "blog")
            if ! grep -q 'Article\|BlogPosting' "$page"; then
                issues+=("missing_article_schema")
            fi
            ;;
    esac
    
    # Performance budget check
    if [[ $(check_performance_budget "$page") != "yes" ]]; then
        issues+=("exceeds_performance_budget")
        ((exceeds_performance_budget++))
    fi
    
    # Image optimization check
    if [[ $(has_image_preload "$page") != "yes" ]] && grep -q '<img' "$page"; then
        issues+=("missing_image_preload")
        ((missing_image_preload++))
    fi
    
    # Sitemap inclusion check
    if [[ $(check_sitemap_inclusion "$url_path") != "yes" ]]; then
        issues+=("not_in_sitemap")
        ((not_in_sitemap++))
    fi
    
    page_issues_list[$page_index]=$(IFS=,; echo "${issues[*]}")
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        ((passed_pages++))
    else
        ((failed_pages++))
    fi
    
    ((page_index++))
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
    echo "      \"below_content_level\": $below_content_level,"
    echo "      \"missing_local_schema\": $missing_local_schema,"
    echo "      \"exceeds_performance_budget\": $exceeds_performance_budget,"
    echo "      \"missing_image_preload\": $missing_image_preload,"
    echo "      \"not_in_sitemap\": $not_in_sitemap"
    echo "    }"
    echo "  },"
    echo "  \"pages\": ["
    
    first=true
    for (( i=0; i<${#page_urls[@]}; i++ )); do
        [[ "$first" == true ]] && first=false || echo ","
        url="${page_urls[$i]}"
        depth=$(depth_for "$url")
        echo -n "    {"
        echo -n "\"url\": \"$url\", "
        echo -n "\"archetype\": \"${page_archetypes[$i]}\", "
        echo -n "\"content_level\": \"${content_levels[$i]}\", "
        echo -n "\"depth\": $depth, "
        echo -n "\"issues\": [$(echo "${page_issues_list[$i]}" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/' | sed 's/""//g')]"
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
    [[ $missing_local_schema -gt 0 ]] && echo "🌍 Missing local business schema: $missing_local_schema"
    [[ $exceeds_performance_budget -gt 0 ]] && echo "⚡ Exceeds performance budget: $exceeds_performance_budget"
    [[ $missing_image_preload -gt 0 ]] && echo "🖼️  Missing image preload: $missing_image_preload"
    [[ $not_in_sitemap -gt 0 ]] && echo "🗺️  Not in sitemap: $not_in_sitemap"
    echo ""
fi

# Content level distribution
echo -e "${BOLD}Content Level Distribution:${NC}"
basic_count=0
enhanced_count=0
premium_count=0
for (( i=0; i<${#content_levels[@]}; i++ )); do
    level="${content_levels[$i]}"
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