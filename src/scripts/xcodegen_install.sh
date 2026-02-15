#!/usr/bin/env bash
# Install XcodeGen if not already available.
set -euo pipefail

if command -v xcodegen &>/dev/null; then
    echo "✓ XcodeGen $(xcodegen --version 2>/dev/null || echo '?') already installed"
else
    echo "→ Installing XcodeGen..."
    brew install xcodegen
fi
