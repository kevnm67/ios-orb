#!/usr/bin/env bash
# Install SwiftFormat if not already available.
set -euo pipefail

if command -v swiftformat &>/dev/null; then
    echo "✓ SwiftFormat $(swiftformat --version) already installed"
else
    echo "→ Installing SwiftFormat..."
    brew install swiftformat
fi
