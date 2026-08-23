#!/usr/bin/env bash
# Generate Xcode project via XcodeGen.
# Env vars set by the orb command:
#   XCODEGEN_SPEC  - path to spec file
#   XCODEGEN_QUIET - "true"/"1" for quiet, anything else is falsy
set -euo pipefail

ARGS=("--spec" "${XCODEGEN_SPEC}")

case "${XCODEGEN_QUIET:-false}" in
    true | 1)
        ARGS+=("--quiet")
        ;;
esac

echo "→ Running: xcodegen generate ${ARGS[*]}"
xcodegen generate "${ARGS[@]}"
