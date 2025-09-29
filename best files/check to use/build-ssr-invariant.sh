#!/bin/bash
# test/build-ssr-invariant.sh
# PROOF INVARIANT: This test ensures NoAdapterInstalled class of errors cannot return
# Would have failed before the fix, now passes

set -e

cd "$(dirname "$0")/.."

echo "🧪 Testing SSR Build Invariant..."

# Test 1: Build should succeed without NoAdapterInstalled error
echo "1. Testing build succeeds..."
if npm run build:faqs >/dev/null 2>&1 && npx astro build >/dev/null 2>&1; then
    echo "✅ Build succeeds - no NoAdapterInstalled error"
else 
    echo "❌ Build failed - SSR adapter issue detected"
    exit 1
fi

# Test 2: Ensure Netlify adapter is properly configured
echo "2. Testing Netlify adapter configuration..."
if grep -q 'adapter: netlify' astro.config.mjs && grep -q 'output: .server.' astro.config.mjs; then
    echo "✅ Netlify adapter properly configured"
else
    echo "❌ Netlify adapter not properly configured"
    exit 1
fi

# Test 3: Ensure .env security
echo "3. Testing .env security..."
if grep -q '\.env' .gitignore; then
    echo "✅ .env files are gitignored"
else
    echo "❌ .env files are not properly gitignored"
    exit 1
fi

echo "🎉 All SSR invariants pass!"
