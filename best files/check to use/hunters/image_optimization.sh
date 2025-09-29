#!/bin/bash
# Image Optimization Hunter
# Detects large images and enforces optimization standards
# Part of Hunter Thinker 2.0 System - Upstream-Curious Performance Enforcement

set -euo pipefail

HUNTER_NAME="image_optimization"
REPORT_FILE="__reports/hunt/${HUNTER_NAME}.json"
MAX_SIZE_KB=500
CRITICAL_SIZE_KB=2000
WARNING_ISSUES=0
CRITICAL_ISSUES=0

echo "🖼️ IMAGE OPTIMIZATION HUNTER"
echo "============================"
echo "Upstream Focus: Eliminate large image performance bottlenecks"
echo "Max Size: ${MAX_SIZE_KB}KB (Critical: >${CRITICAL_SIZE_KB}KB)"
echo ""

# Ensure reports directory exists
mkdir -p "__reports/hunt"

# Initialize report structure
cat > "$REPORT_FILE" << 'EOF'
{
  "hunter": "image_optimization",
  "version": "2.0",
  "methodology": "upstream_curious",
  "timestamp": "",
  "critical_issues": 0,
  "warning_issues": 0,
  "status": "unknown",
  "findings": {
    "large_images": [],
    "critical_images": [],
    "format_analysis": {},
    "total_size_impact": 0,
    "optimization_opportunities": []
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

echo "🔍 Scanning for large images..."

LARGE_IMAGES=()
CRITICAL_IMAGES=()
TOTAL_SIZE_KB=0
FORMAT_COUNTS=("png:0" "jpg:0" "jpeg:0" "webp:0" "svg:0")

# Function to get file extension
get_extension() {
    echo "${1##*.}" | tr '[:upper:]' '[:lower:]'
}

# Function to convert bytes to KB
bytes_to_kb() {
    echo "scale=0; $1 / 1024" | bc 2>/dev/null || echo "0"
}

# Function to convert KB to MB
kb_to_mb() {
    echo "scale=1; $1 / 1024" | bc 2>/dev/null || echo "0"
}

# Scan image directories
IMAGE_DIRS=("src/assets" "src/public" "public" "src/images")
FOUND_IMAGES=0

for dir in "${IMAGE_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]]; then
                FOUND_IMAGES=$((FOUND_IMAGES + 1))
                
                # Get file size in bytes, then convert to KB
                size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                size_kb=$(bytes_to_kb "$size_bytes")
                size_mb=$(kb_to_mb "$size_kb")
                
                TOTAL_SIZE_KB=$((TOTAL_SIZE_KB + size_kb))
                
                relative_file=${file#./}
                extension=$(get_extension "$file")
                
                # Update format counts
                for i in "${!FORMAT_COUNTS[@]}"; do
                    format=$(echo "${FORMAT_COUNTS[$i]}" | cut -d: -f1)
                    count=$(echo "${FORMAT_COUNTS[$i]}" | cut -d: -f2)
                    if [[ "$extension" == "$format" ]]; then
                        FORMAT_COUNTS[$i]="$format:$((count + 1))"
                        break
                    fi
                done
                
                # Check size thresholds
                if [[ $size_kb -gt $CRITICAL_SIZE_KB ]]; then
                    echo "🚨 CRITICAL: $relative_file (${size_mb}MB) - Severely impacts performance"
                    CRITICAL_IMAGES+=("$relative_file:$size_kb:$extension")
                    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
                elif [[ $size_kb -gt $MAX_SIZE_KB ]]; then
                    echo "⚠️  WARNING: $relative_file (${size_mb}MB) - Consider optimization"
                    LARGE_IMAGES+=("$relative_file:$size_kb:$extension")
                    WARNING_ISSUES=$((WARNING_ISSUES + 1))
                fi
            fi
        done < <(find "$dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.svg" \) -print0 2>/dev/null || true)
    fi
done

echo ""
echo "📊 Image Analysis Summary:"
echo "   Total Images Found: $FOUND_IMAGES"
echo "   Total Size: $(kb_to_mb $TOTAL_SIZE_KB)MB"
echo "   Large Images (>$MAX_SIZE_KB KB): $(($WARNING_ISSUES + $CRITICAL_ISSUES))"
echo "   Critical Images (>$CRITICAL_SIZE_KB KB): $CRITICAL_ISSUES"

echo ""
echo "📈 Format Distribution:"
for format_count in "${FORMAT_COUNTS[@]}"; do
    format=$(echo "$format_count" | cut -d: -f1)
    count=$(echo "$format_count" | cut -d: -f2)
    if [[ $count -gt 0 ]]; then
        echo "   $format: $count files"
    fi
done

echo ""
echo "🎯 Optimization Opportunities:"

# Generate optimization strategies
OPTIMIZATION_STRATEGIES=()
for image in "${CRITICAL_IMAGES[@]}"; do
    file=$(echo "$image" | cut -d: -f1)
    size_kb=$(echo "$image" | cut -d: -f2)
    extension=$(echo "$image" | cut -d: -f3)
    size_mb=$(kb_to_mb "$size_kb")
    
    case "$extension" in
        "png")
            echo "   • $file (${size_mb}MB PNG) → Convert to WebP + responsive images"
            OPTIMIZATION_STRATEGIES+=("$file:Convert PNG to WebP format with responsive sizing")
            ;;
        "jpg"|"jpeg")
            echo "   • $file (${size_mb}MB JPEG) → Compress + WebP format + lazy loading"
            OPTIMIZATION_STRATEGIES+=("$file:Compress JPEG and provide WebP alternative")
            ;;
        *)
            echo "   • $file (${size_mb}MB) → Resize + optimize + modern format"
            OPTIMIZATION_STRATEGIES+=("$file:Resize and optimize for web delivery")
            ;;
    esac
done

for image in "${LARGE_IMAGES[@]}"; do
    file=$(echo "$image" | cut -d: -f1)
    size_kb=$(echo "$image" | cut -d: -f2)
    extension=$(echo "$image" | cut -d: -f3)
    size_mb=$(kb_to_mb "$size_kb")
    
    echo "   • $file (${size_mb}MB) → Compress and consider WebP format"
    OPTIMIZATION_STRATEGIES+=("$file:Compress image and consider modern format conversion")
done

# Update report with findings
LARGE_JSON=$(printf '%s\n' "${LARGE_IMAGES[@]}" 2>/dev/null | jq -R 'split(":") | {file: .[0], size_kb: (.[1] | tonumber), format: .[2]}' | jq -s . || echo "[]")
CRITICAL_JSON=$(printf '%s\n' "${CRITICAL_IMAGES[@]}" 2>/dev/null | jq -R 'split(":") | {file: .[0], size_kb: (.[1] | tonumber), format: .[2]}' | jq -s . || echo "[]")

# Create format analysis object
FORMAT_ANALYSIS=$(printf '%s\n' "${FORMAT_COUNTS[@]}" | jq -R 'split(":") | {key: .[0], value: (.[1] | tonumber)}' | jq -s 'from_entries')

jq --argjson critical "$CRITICAL_ISSUES" \
   --argjson warning "$WARNING_ISSUES" \
   --argjson large "$LARGE_JSON" \
   --argjson critical_imgs "$CRITICAL_JSON" \
   --argjson formats "$FORMAT_ANALYSIS" \
   --argjson total_size "$TOTAL_SIZE_KB" \
   '.critical_issues = $critical | 
    .warning_issues = $warning | 
    .findings.large_images = $large |
    .findings.critical_images = $critical_imgs |
    .findings.format_analysis = $formats |
    .findings.total_size_impact = $total_size' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

# Determine status and upstream analysis
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    STATUS="critical"
    EXIT_CODE=2
    UPSTREAM_BOX="Critical image sizes (>$CRITICAL_SIZE_KB KB) severely impact performance"
    UPSTREAM_CLOSET="Missing image optimization pipeline and modern format strategy"
    UPSTREAM_POLICY="Implement automated image optimization with size gates"
elif [[ $WARNING_ISSUES -gt 0 ]]; then
    STATUS="warn"
    EXIT_CODE=1
    UPSTREAM_BOX="Large image sizes (>$MAX_SIZE_KB KB) impact page load performance"
    UPSTREAM_CLOSET="Suboptimal image delivery strategy lacking modern formats"
    UPSTREAM_POLICY="Implement image optimization guidelines with format modernization"
else
    STATUS="pass"
    EXIT_CODE=0
    UPSTREAM_BOX="Image sizes within performance budgets"
    UPSTREAM_CLOSET="Optimized image delivery strategy"
    UPSTREAM_POLICY="Maintain image optimization discipline"
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

# Generate recommendations
RECOMMENDATIONS=()
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Immediately optimize critical images (>$CRITICAL_SIZE_KB KB)"
        "Convert PNG to WebP format for better compression"
        "Implement responsive images with multiple sizes"
        "Add image optimization to build pipeline"
        "Use lazy loading for below-fold images"
    )
fi

if [[ $WARNING_ISSUES -gt 0 ]]; then
    RECOMMENDATIONS+=(
        "Optimize large images (>$MAX_SIZE_KB KB) for better performance"
        "Provide WebP alternatives for PNG/JPEG images"
        "Implement image CDN with automatic optimization"
        "Use appropriate image formats (WebP, AVIF for photos)"
    )
fi

RECOMMENDATIONS+=(
    "Set image size budgets in development guidelines"
    "Implement automated image optimization in CI/CD"
    "Use modern image formats (WebP, AVIF) with fallbacks"
    "Add image performance monitoring"
    "Document image optimization best practices"
)

# Convert recommendations to JSON and update report
RECOMMENDATIONS_JSON=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
jq --argjson recs "$RECOMMENDATIONS_JSON" '.recommendations = $recs' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo ""
echo "Image Optimization Analysis Summary:"
echo "=================================="
echo "Issues: $(($CRITICAL_ISSUES + $WARNING_ISSUES))"
echo "Critical: $CRITICAL_ISSUES"
echo "Warning: $WARNING_ISSUES"
echo "Status: $STATUS"
echo "Report: $REPORT_FILE"

if [[ $CRITICAL_ISSUES -gt 0 ]] || [[ $WARNING_ISSUES -gt 0 ]]; then
    echo ""
    echo "💡 UPSTREAM-CURIOUS OPTIMIZATION STRATEGY:"
    echo "Class Problem: Large images impacting page load performance"
    echo "Upstream Fix: Automated image optimization pipeline with modern formats"
    echo ""
    echo "Optimization Commands:"
    echo "# Convert to WebP (80% quality)"
    echo "cwebp -q 80 input.png -o output.webp"
    echo ""
    echo "# Responsive images in Astro:"
    echo "<picture>"
    echo "  <source srcset=\"image.webp\" type=\"image/webp\">"
    echo "  <img src=\"image.jpg\" alt=\"Description\" loading=\"lazy\">"
    echo "</picture>"
    echo ""
fi

if [[ $EXIT_CODE -eq 2 ]]; then
    echo "❌ image_optimization: critical issues"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠ image_optimization: issues found"
else
    echo "✅ image_optimization: passed"
fi

exit $EXIT_CODE
