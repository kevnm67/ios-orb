#!/usr/bin/env bash
# Install Periphery if not already available.
# Verified 2026-08-23: peripheryapp/homebrew-periphery is unmaintained —
# Periphery now ships as a core Homebrew formula (formulae.brew.sh/formula/periphery).
set -euo pipefail

if command -v periphery &>/dev/null; then
    echo "✓ Periphery $(periphery version) already installed"
else
    echo "→ Installing Periphery..."
    brew install periphery
fi
