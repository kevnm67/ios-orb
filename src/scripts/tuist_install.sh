#!/usr/bin/env bash
# Install Tuist if not already available. Tuist ships as a Homebrew cask,
# not a core formula (verified 2026-08-23: `brew info tuist` -> Cask,
# Homebrew/homebrew-cask, current stable 4.205.0).
set -euo pipefail

if command -v tuist &> /dev/null; then
    echo "✓ Tuist $(tuist version 2>/dev/null || echo '?') already installed"
else
    echo "→ Installing Tuist..."
    brew install --cask tuist
fi
