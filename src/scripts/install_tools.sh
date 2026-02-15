#!/usr/bin/env bash
# Install Homebrew formulas if not already available.
# Env: TOOLS - space-separated list of formulas
set -euo pipefail

for tool in ${TOOLS}; do
    if command -v "$tool" &>/dev/null; then
        echo "✓ ${tool} already installed"
    else
        echo "→ Installing ${tool}..."
        brew install "$tool"
    fi
done
