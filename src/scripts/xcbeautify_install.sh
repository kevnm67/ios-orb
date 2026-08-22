#!/usr/bin/env bash
# Install xcbeautify if not already available.
set -euo pipefail

if command -v xcbeautify &>/dev/null; then
    echo "✓ xcbeautify already installed"
else
    echo "→ Installing xcbeautify..."
    brew install xcbeautify
fi
