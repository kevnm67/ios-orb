#!/usr/bin/env bash
# Install (or reinstall) a Homebrew formula if not already present.
# Env vars set by the orb command:
#   BREW_FORMULA   - formula name to install
#   BREW_REINSTALL - "true"/"1" to force reinstall, anything else is falsy
set -euo pipefail

case "${BREW_REINSTALL:-false}" in
    true | 1)
        echo "→ Running: brew reinstall ${BREW_FORMULA}"
        brew reinstall "${BREW_FORMULA}"
        ;;
    *)
        if brew list "${BREW_FORMULA}" &>/dev/null; then
            echo "✓ ${BREW_FORMULA} already installed"
        else
            echo "→ Running: brew install ${BREW_FORMULA}"
            brew install "${BREW_FORMULA}"
        fi
        ;;
esac
