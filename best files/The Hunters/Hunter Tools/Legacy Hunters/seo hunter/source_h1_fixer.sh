#!/bin/bash
# Source H1 Fixer - Adds missing H1s to Astro source files (the right way)
# Class-eliminating approach: fix at source, not in built files

set -euo pipefail

AUDIT_FILE="__reports/hunt/seo_crawl.json"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "🔧 [source-h1-fixer] $*"; }
success() { echo "✅ [source-h1-fixer] $*"; }
warn() { echo "⚠️ [source-h1-fixer] $*"; }

# Check if audit exists
if [[ ! -f "$AUDIT_FILE" ]]; then
    echo "❌ SEO audit not found. Run: bash hunters/seo_crawlability.sh"
    exit 1
fi

log "Finding pages with missing H1 headings..."

# Get simple pages missing H1s (focus on easily fixable ones)
missing_h1_pages=$(jq -r '.pages[] | select(.issues[] == "missing_h1") | .url' "$AUDIT_FILE" | grep -E '^/(quote|gallery|)/?$')

if [[ -z "$missing_h1_pages" ]]; then
    success "No pages missing H1 headings!"
    exit 0
fi

count=$(echo "$missing_h1_pages" | wc -l)
log "Fixing $count sample pages (testing approach)"

# Map URLs to source files (simple cases first)
fix_h1_in_source() {
    local url="$1"
    local src_file=""
    
    case "$url" in
        "/") src_file="src/pages/index.astro" ;;
        "/quote/") src_file="src/pages/quote.astro" ;;
        "/gallery/") src_file="src/pages/gallery.astro" ;;
        "/blog/") src_file="src/pages/blog/index.astro" ;;
        *) 
            warn "Skipping complex URL: $url (would need template mapping)"
            return 1
            ;;
    esac
    
    if [[ ! -f "$src_file" ]]; then
        warn "Source file not found: $src_file for $url"
        return 1
    fi
    
    # Check if H1 already exists
    if grep -q '<h1' "$src_file"; then
        log "H1 already exists in $src_file"
        return 0
    fi
    
    # Generate appropriate H1 based on page type
    local h1_text=""
    case "$url" in
        "/") h1_text="Professional Bond Cleaning Services" ;;
        "/quote/") h1_text="Get Your Cleaning Quote" ;;
        "/gallery/") h1_text="Our Work Gallery" ;;
        "/blog/") h1_text="Cleaning Tips & Guides" ;;
        *) h1_text="Page Content" ;;
    esac
    
    if [[ $DRY_RUN == "1" ]]; then
        log "Would add H1 '$h1_text' to $src_file"
        return 0
    fi
    
    # Find main content area and inject H1
    if grep -q '<main\|class.*main\|<section' "$src_file"; then
        # Create backup
        cp "$src_file" "${src_file}.backup"
        
        # Inject H1 at start of main content
        if sed -i "0,/<main[^>]*>\|<section[^>]*class.*main/{s|<main[^>]*>\|<section[^>]*class.*main[^>]*>|&\n\t<h1>$h1_text</h1>|}" "$src_file"; then
            success "Added H1 to source: $src_file"
            return 0
        else
            warn "Failed to inject H1 in $src_file"
            mv "${src_file}.backup" "$src_file"
            return 1
        fi
    else
        warn "No main content area found in $src_file"
        return 1
    fi
}

# Process each page
fixed=0
for url in $missing_h1_pages; do
    if fix_h1_in_source "$url"; then
        ((fixed++))
    fi
done

log "Fixed $fixed source files"

if [[ $fixed -gt 0 && $DRY_RUN != "1" ]]; then
    log "Rebuild site to see changes: npm run build"
    log "Re-run SEO audit to verify: bash hunters/seo_crawlability.sh"
fi