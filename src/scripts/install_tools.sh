#!/usr/bin/env bash
# Install Homebrew formulas if not already available.
# Env: TOOLS - space-separated list of formulas
#
# brew exits non-zero when a *dependency's* post-install step warns
# ("Warning: The post-install step did not complete successfully", e.g. aom)
# even though the requested formula installed. Tolerate that only when the
# formula is actually installed afterwards; otherwise fail loudly.
set -euo pipefail

TOOLS="${TOOLS:-}"

for tool in ${TOOLS}; do
    if command -v "$tool" &>/dev/null; then
        echo "✓ ${tool} already installed"
    else
        echo "→ Installing ${tool}..."
        if ! brew install "$tool"; then
            if brew list --formula "$tool" &>/dev/null; then
                echo "⚠ brew install ${tool} exited non-zero but the formula is installed (dependency post-install warning); continuing"
            else
                echo "✗ brew install ${tool} failed and the formula is not installed" >&2
                exit 1
            fi
        fi
    fi
done
