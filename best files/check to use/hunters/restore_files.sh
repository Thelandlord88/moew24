#!/bin/bash
# Repository Cleanup Restore Script
# Restores files from CLEANUP folder if needed

set -euo pipefail

CLEANUP_DIR="CLEANUP"
DRY_RUN=${DRY_RUN:-false}

echo "🔄 Repository Cleanup Restore Script"
echo "================================="
echo ""

if [ ! -d "$CLEANUP_DIR" ]; then
  echo "❌ No CLEANUP directory found"
  exit 1
fi

echo "Available categories to restore:"
ls -la "$CLEANUP_DIR/"
echo ""
echo "Enter category to restore (or all for everything): "
read CATEGORY

if [ "$CATEGORY" = "all" ]; then
  echo "🔄 Restoring all files..."
  find "$CLEANUP_DIR" -type f -exec bash -c '
    rel_path="${1#CLEANUP/*/}"
    mkdir -p "$(dirname "$rel_path")"
    mv "$1" "$rel_path"
    echo "Restored: $rel_path"
  ' _ {} \;
else
  if [ ! -d "$CLEANUP_DIR/$CATEGORY" ]; then
    echo "❌ Category not found: $CATEGORY"
    exit 1
  fi
  echo "🔄 Restoring category: $CATEGORY"
  find "$CLEANUP_DIR/$CATEGORY" -type f -exec bash -c '
    rel_path="${1#CLEANUP/*/}"
    mkdir -p "$(dirname "$rel_path")"
    mv "$1" "$rel_path"
    echo "Restored: $rel_path"
  ' _ {} \;
fi

echo "✅ Restore complete"