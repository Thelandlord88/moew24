#!/bin/bash
# Shell-integration-safe NEXUS wrapper

# Clean environment setup
export BASH_COMPAT=4.4
set +H
unset HISTFILE
export PS1='$ '

cd "$(dirname "$0")" || exit 1
source .hunter-env.sh && setup_hunter_env

# Test NEXUS integration
echo "🧠 Testing NEXUS Integration (shell-safe mode)"

# Use timeout to prevent hanging
timeout 10s node -e "
console.log('Testing NEXUS bridge...');
import('./nexus/nexus-bridge.mjs')
  .then(() => console.log('✅ NEXUS bridge functional'))
  .catch(err => {
    console.log('❌ NEXUS bridge error:', err.message);
    process.exit(1);
  });
" 2>/dev/null || echo "⚠️  NEXUS bridge test timed out or failed"

# Test consciousness bridge
timeout 10s node -e "
console.log('Testing consciousness bridge...');
import('./hunters/consciousness-bridge.mjs')
  .then(() => console.log('✅ Consciousness bridge functional'))
  .catch(err => {
    console.log('❌ Consciousness bridge error:', err.message);
    process.exit(1);
  });
" 2>/dev/null || echo "⚠️  Consciousness bridge test timed out or failed"
