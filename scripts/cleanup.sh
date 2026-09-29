#!/bin/bash

# Cleanup script to prevent ENOSPC (disk full) errors
# Usage: ./scripts/cleanup.sh

set -e

echo "Cleaning up cache and temporary files..."

# Clear ~/.cache
if [ -d "$HOME/.cache" ]; then
    echo "  Removing ~/.cache..."
    rm -rf "$HOME/.cache"
fi

# Clear NPM cache
if [ -d "$HOME/.npm" ]; then
    echo "  Removing ~/.npm..."
    rm -rf "$HOME/.npm"
fi

# Clear unused temp files in /tmp (except ollama_models)
if [ -d "/tmp" ]; then
    echo "  Cleaning /tmp (preserving ollama_models)..."
    find /tmp -mindepth 1 -maxdepth 1 ! -name "ollama_models" -exec rm -rf {} + 2>/dev/null || true
fi

# Clear system temp files
if [ -d "/var/tmp" ]; then
    echo "  Cleaning /var/tmp..."
    rm -rf /var/tmp/*
fi

echo "Cleanup complete."
