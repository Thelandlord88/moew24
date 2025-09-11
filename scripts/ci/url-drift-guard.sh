#!/usr/bin/env bash
# CI Guard: Prevent hardcoded URL drift
# Usage: ./scripts/ci/url-drift-guard.sh
set -euo pipefail

echo "🔍 Checking for hardcoded URLs outside route helpers..."

# Check for /blog/ literals outside the routes module
BLOG_DRIFT=$(grep -r '/blog/' src --include='*.astro' --include='*.ts' --include='*.tsx' | grep -v 'lib/routes.ts' || true)
if [ -n "$BLOG_DRIFT" ]; then
  echo "❌ Found hardcoded /blog/ URLs. Use routes.blog.* helpers instead:"
  echo "$BLOG_DRIFT"
  exit 1
fi

# Check for /services/ literals outside routes
SERVICES_DRIFT=$(grep -r '/services/' src --include='*.astro' --include='*.ts' --include='*.tsx' | grep -v 'lib/routes.ts' || true)
if [ -n "$SERVICES_DRIFT" ]; then
  echo "❌ Found hardcoded /services/ URLs. Use routes.services.* helpers instead:"
  echo "$SERVICES_DRIFT"
  exit 1
fi

# Check for /suburbs/ literals outside routes  
SUBURBS_DRIFT=$(grep -r '/suburbs/' src --include='*.astro' --include='*.ts' --include='*.tsx' | grep -v 'lib/routes.ts' || true)
if [ -n "$SUBURBS_DRIFT" ]; then
  echo "❌ Found hardcoded /suburbs/ URLs. Use routes.suburbs.* helpers instead:"
  echo "$SUBURBS_DRIFT"
  exit 1
fi

echo "✅ No hardcoded URL drift detected"
