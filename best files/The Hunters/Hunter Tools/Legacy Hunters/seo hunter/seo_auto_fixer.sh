#!/bin/bash
# SEO Auto-Fixer - Automatically fixes issues found by seo_crawlability.sh
# Injects canonicals, scaffolds FAQ JSON-LD, generates internal links

set -euo pipefail

# Configuration
DIST_DIR="dist"
SRC_DIR="src"
AUDIT_FILE="__reports/hunt/seo_crawl.json"
DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[seo-fixer]${NC} $*"; }
warn() { echo -e "${YELLOW}[seo-fixer]${NC} $*"; }
error() { echo -e "${RED}[seo-fixer]${NC} $*"; }
success() { echo -e "${GREEN}[seo-fixer]${NC} $*"; }
verbose() { [[ $VERBOSE == "1" ]] && echo -e "${BLUE}[verbose]${NC} $*" || true; }

# Check if audit report exists
if [[ ! -f "$AUDIT_FILE" ]]; then
    error "SEO audit report not found at $AUDIT_FILE"
    error "Run the SEO crawlability hunter first: bash hunters/seo_crawlability.sh"
    exit 1
fi

log "Starting SEO auto-fixer..."
[[ $DRY_RUN == "1" ]] && warn "DRY RUN MODE - No files will be modified"

# Parse the audit report to get pages with issues
pages_with_issues=$(jq -r '.pages[] | select(.issues | length > 0) | .url' "$AUDIT_FILE" 2>/dev/null || echo "")

if [[ -z "$pages_with_issues" ]]; then
    success "No pages with issues found in audit report"
    exit 0
fi

# Helper: Get source file path from URL
get_source_file() {
    local url="$1"
    local src_file=""
    
    case "$url" in
        "/") src_file="$SRC_DIR/pages/index.astro" ;;
        "/quote/") src_file="$SRC_DIR/pages/quote.astro" ;;
        "/blog/") src_file="$SRC_DIR/pages/blog/index.astro" ;;
        "/blog/"*) 
            slug="${url#/blog/}"
            slug="${slug%/}"
            if [[ "$slug" == */* ]]; then
                # Category/tag/region pages
                src_file="$SRC_DIR/pages/blog/${slug}.astro"
            else
                # Individual blog posts
                src_file="$SRC_DIR/pages/blog/[slug].astro"
            fi
            ;;
        "/services/"*)
            service="${url#/services/}"
            service="${service%/}"
            if [[ "$service" == */* ]]; then
                # Service with suburb
                src_file="$SRC_DIR/pages/services/[service]/[suburb].astro"
            else
                # Service index
                src_file="$SRC_DIR/pages/services/[service]/index.astro"
            fi
            ;;
        "/areas/"*) src_file="$SRC_DIR/pages/areas/[cluster]/[suburb]/index.astro" ;;
        *) 
            # Generic pages
            clean_url="${url#/}"
            clean_url="${clean_url%/}"
            src_file="$SRC_DIR/pages/${clean_url}.astro"
            ;;
    esac
    
    echo "$src_file"
}

# Helper: Check if file has canonical tag
has_canonical() {
    local file="$1"
    grep -q 'rel="canonical"' "$file" 2>/dev/null
}

# Helper: Inject canonical tag into Astro file
inject_canonical() {
    local file="$1"
    local url="$2"
    
    if [[ ! -f "$file" ]]; then
        verbose "Source file not found: $file"
        return 1
    fi
    
    if has_canonical "$file"; then
        verbose "Canonical already exists in $file"
        return 0
    fi
    
    verbose "Injecting canonical tag into $file for URL $url"
    
    if [[ $DRY_RUN == "1" ]]; then
        log "Would inject canonical: $url into $file"
        return 0
    fi
    
    # Find the head section and inject canonical
    if grep -q '</head>' "$file"; then
        sed -i "s|</head>|<link rel=\"canonical\" href=\"{Astro.url}\" />\n</head>|" "$file"
        success "✅ Injected canonical tag into $file"
    else
        warn "Could not find </head> tag in $file"
        return 1
    fi
}

# Helper: Generate FAQ schema for service/suburb pages
generate_faq_schema() {
    local file="$1"
    local archetype="$2"
    local url="$3"
    
    if [[ ! -f "$file" ]]; then
        verbose "Source file not found: $file"
        return 1
    fi
    
    if grep -q 'FAQPage\|QAPage' "$file"; then
        verbose "FAQ schema already exists in $file"
        return 0
    fi
    
    verbose "Generating FAQ schema for $archetype page: $file"
    
    local faq_schema=""
    case "$archetype" in
        "service")
            faq_schema='<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How much does this service cost?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Pricing varies based on property size and specific requirements. Contact us for a detailed quote."
      }
    },
    {
      "@type": "Question", 
      "name": "How long does the service take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Service duration depends on property size and condition. Most jobs are completed within 2-4 hours."
      }
    },
    {
      "@type": "Question",
      "name": "Do you provide a guarantee?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, we provide a 7-day reclean guarantee on all our services for your peace of mind."
      }
    }
  ]
}
</script>'
            ;;
        "suburb")
            faq_schema='<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Do you service this area?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, we provide professional cleaning services throughout this area with local expertise."
      }
    },
    {
      "@type": "Question",
      "name": "What areas do you cover nearby?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "We service all surrounding suburbs and can provide quotes for properties within our coverage area."
      }
    },
    {
      "@type": "Question",
      "name": "How do I book a service?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "You can book online through our quote form or call us directly for immediate assistance."
      }
    }
  ]
}
</script>'
            ;;
    esac
    
    if [[ $DRY_RUN == "1" ]]; then
        log "Would inject FAQ schema into $file"
        return 0
    fi
    
    # Inject before closing </head> tag
    if grep -q '</head>' "$file"; then
        # Create temp file with schema
        echo "$faq_schema" > /tmp/faq_schema.tmp
        sed -i "s|</head>|$(cat /tmp/faq_schema.tmp)\n</head>|" "$file"
        rm /tmp/faq_schema.tmp
        success "✅ Injected FAQ schema into $file"
    else
        warn "Could not find </head> tag in $file"
        return 1
    fi
}

# Helper: Generate internal link suggestions for orphaned pages
generate_internal_links() {
    local orphan_url="$1"
    local archetype="$2"
    
    verbose "Generating internal link suggestions for orphaned page: $orphan_url"
    
    local link_suggestions=()
    
    case "$archetype" in
        "service")
            link_suggestions+=(
                "Add link from homepage services section"
                "Add link from related service pages"
                "Add link from relevant blog posts"
                "Add to services navigation menu"
            )
            ;;
        "suburb")
            link_suggestions+=(
                "Add link from areas index page"
                "Add link from related suburb pages"
                "Add link from service pages covering this area"
                "Add to geographic navigation"
            )
            ;;
        "blog")
            link_suggestions+=(
                "Add link from blog index page"
                "Add link from related category/tag pages"
                "Add link from other blog posts"
                "Add to recent posts section"
            )
            ;;
        *)
            link_suggestions+=(
                "Add link from homepage"
                "Add link from sitemap"
                "Add to main navigation"
                "Add link from footer"
            )
            ;;
    esac
    
    log "📋 Link suggestions for $orphan_url:"
    for suggestion in "${link_suggestions[@]}"; do
        echo "   • $suggestion"
    done
}

# Helper: Add H1 heading to pages that need it
inject_h1_heading() {
    local file="$1"
    local url="$2"
    local archetype="$3"
    
    if [[ ! -f "$file" ]]; then
        verbose "Source file not found: $file"
        return 1
    fi
    
    if grep -q '<h1>' "$file"; then
        verbose "H1 already exists in $file"
        return 0
    fi
    
    verbose "Adding H1 heading to $file"
    
    # Generate appropriate H1 based on archetype
    local h1_text=""
    case "$archetype" in
        "service") h1_text="Professional Cleaning Services" ;;
        "suburb") h1_text="Cleaning Services in This Area" ;;
        "blog") h1_text="Blog Post Title" ;;
        *) h1_text="Page Title" ;;
    esac
    
    if [[ $DRY_RUN == "1" ]]; then
        log "Would add H1 heading '$h1_text' to $file"
        return 0
    fi
    
    # Find first content section and add H1
    if grep -q '<main\|<section\|<article' "$file"; then
        sed -i "s|<main\|<section\|<article|&>\n<h1>$h1_text</h1|" "$file"
        success "✅ Added H1 heading to $file"
    else
        warn "Could not find suitable location for H1 in $file"
        return 1
    fi
}

# Main fixing logic
fixed_canonicals=0
fixed_faq_schemas=0
fixed_h1_headings=0
orphan_suggestions=0

while IFS= read -r url; do
    verbose "Processing page: $url"
    
    # Get page details from audit
    page_data=$(jq -r ".pages[] | select(.url == \"$url\")" "$AUDIT_FILE")
    issues=$(echo "$page_data" | jq -r '.issues[]' 2>/dev/null || echo "")
    archetype=$(echo "$page_data" | jq -r '.archetype' 2>/dev/null || echo "generic")
    
    # Get source file
    src_file=$(get_source_file "$url")
    
    # Process each issue
    while IFS= read -r issue; do
        case "$issue" in
            "missing_canonical")
                if inject_canonical "$src_file" "$url"; then
                    ((fixed_canonicals++))
                fi
                ;;
            "missing_faq_schema")
                if [[ "$archetype" == "service" || "$archetype" == "suburb" ]]; then
                    if generate_faq_schema "$src_file" "$archetype" "$url"; then
                        ((fixed_faq_schemas++))
                    fi
                fi
                ;;
            "missing_h1")
                if inject_h1_heading "$src_file" "$url" "$archetype"; then
                    ((fixed_h1_headings++))
                fi
                ;;
            "orphaned")
                generate_internal_links "$url" "$archetype"
                ((orphan_suggestions++))
                ;;
            *)
                verbose "Issue not auto-fixable: $issue"
                ;;
        esac
    done <<< "$issues"
    
done <<< "$pages_with_issues"

# Summary
echo ""
echo -e "${BOLD}SEO Auto-Fixer Results${NC}"
echo "======================"
echo "🔗 Canonical tags injected: $fixed_canonicals"
echo "❓ FAQ schemas generated: $fixed_faq_schemas" 
echo "📰 H1 headings added: $fixed_h1_headings"
echo "🏝️  Orphan link suggestions: $orphan_suggestions"

if [[ $DRY_RUN == "1" ]]; then
    warn "DRY RUN MODE - No files were actually modified"
    log "Run without DRY_RUN=1 to apply fixes"
else
    success "Auto-fixes complete!"
    log "Run the SEO hunter again to verify improvements"
fi

# Recommend running hunter again
echo ""
log "💡 Next steps:"
echo "  1. Review the changes made to source files"
echo "  2. Rebuild the site: npm run build"
echo "  3. Re-run SEO audit: bash hunters/seo_crawlability.sh"
echo "  4. Address any remaining manual fixes needed"

exit 0