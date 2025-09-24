#!/usr/bin/env bash
# Simplified SEO Geo Hunter for testing
set -euo pipefail

DIST_DIR="${1:-dist}"
REPORT_DIR="__reports/hunt"
REPORT_JSON="$REPORT_DIR/seo_geo_crawl.json"

mkdir -p "$REPORT_DIR"

echo "🔍 Starting SEO Geo Crawl Hunter..."
echo "📁 Scanning: $DIST_DIR"

# Find HTML files
htmls=($(find "$DIST_DIR" -type f -name "index.html" | sort))
echo "📄 Found ${#htmls[@]} HTML files"

if [ ${#htmls[@]} -eq 0 ]; then
  echo "❌ No HTML files found"
  exit 1
fi

# Simple checks for each file
results='[]'
pass_count=0
fail_count=0

for f in "${htmls[@]}"; do
  echo "🔍 Checking: $f"
  
  # Extract basic info  
  slug=$(dirname "$f" | awk -F/ '{print $NF}')
  title=$(grep -oP '<title>\K[^<]+' "$f" 2>/dev/null | tr -d '\r\n' | sed 's/[[:space:]]\+/ /g' || echo "")
  desc=$(grep -oP 'name="description" content="\K[^"]*' "$f" 2>/dev/null | tr -d '\r\n' || echo "")
  has_h1=$(grep -q '<h1' "$f" && echo "yes" || echo "no")
  has_canonical=$(grep -q 'rel="canonical"' "$f" && echo "yes" || echo "no")
  gz_size=$(gzip -c "$f" | wc -c)
  
  # Determine pass/fail
  status="pass"
  if [ -z "$title" ] || [ "$has_h1" = "no" ] || [ "$has_canonical" = "no" ]; then
    status="fail"
    ((fail_count++))
  else
    ((pass_count++))
  fi
  
  # Create JSON entry
  entry=$(jq -n \
    --arg slug "$slug" \
    --arg title "$title" \
    --arg desc "$desc" \
    --arg has_h1 "$has_h1" \
    --arg has_canonical "$has_canonical" \
    --arg gz_size "$gz_size" \
    --arg status "$status" \
    '{
      slug: $slug,
      title: $title,
      description: $desc,
      has_h1: ($has_h1 == "yes"),
      has_canonical: ($has_canonical == "yes"),
      gz_size: ($gz_size | tonumber),
      status: $status
    }' 2>/dev/null || echo '{"error": "jq failed"}')
  
  if [[ "$entry" == *"error"* ]]; then
    echo "❌ JQ failed for $f"
    exit 1
  fi
  
  results=$(jq -c --argjson entry "$entry" '. + [$entry]' <<<"$results" 2>/dev/null || echo "[]")
done

# Write final report
final_report=$(jq -n \
  --argjson results "$results" \
  --arg pass_count "$pass_count" \
  --arg fail_count "$fail_count" \
  '{
    module: "seo_geo_crawl",
    timestamp: now | todateiso8601,
    summary: {
      total: ($pass_count | tonumber) + ($fail_count | tonumber),
      passed: ($pass_count | tonumber),
      failed: ($fail_count | tonumber)
    },
    pages: $results
  }')

echo "$final_report" > "$REPORT_JSON"

echo ""
echo "📊 SEO Geo Crawl Results:"
echo "✅ Passed: $pass_count"
echo "❌ Failed: $fail_count"
echo "📝 Report: $REPORT_JSON"

if [ "$fail_count" -gt 0 ]; then
  exit 2
else
  exit 0
fi