#!/bin/bash

# Enhanced script wrapper for ui-grep.mjs
# Adds VS Code shell integration features and better error handling

# Enable error tracking
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print with timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handler
handle_error() {
    log "${RED}Error on line $1${NC}"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start script
log "${GREEN}Starting UI grep analysis...${NC}"

# Run the JavaScript script
node scripts/ui-grep.mjs

# Check exit status
if [ $? -eq 0 ]; then
    log "${GREEN}✓ UI grep completed successfully${NC}"
    log "${YELLOW}Results saved to __ai/ui-grep.txt${NC}"
    
    # Print summary of findings
    if [ -f "__ai/ui-grep.txt" ]; then
        echo -e "\n${YELLOW}Summary of findings:${NC}"
        cat "__ai/ui-grep.txt"
    fi
else
    log "${RED}✗ UI grep failed${NC}"
    exit 1
fi
