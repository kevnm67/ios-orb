#!/usr/bin/env bash
# Install SwiftLint if not already available.
set -euo pipefail

if command -v swiftlint &>/dev/null; then
    echo "✓ SwiftLint $(swiftlint version) already installed"
else
    echo "→ Installing SwiftLint..."
    brew install swiftlint
fi
