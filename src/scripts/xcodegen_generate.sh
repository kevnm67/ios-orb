#!/usr/bin/env bash
# Generate Xcode project via XcodeGen.
# Env vars set by the orb command:
#   XCODEGEN_SPEC  - path to spec file
#   XCODEGEN_QUIET - "true" or "false"
set -euo pipefail

ARGS="--spec ${XCODEGEN_SPEC}"

if [ "${XCODEGEN_QUIET}" = "true" ]; then
    ARGS="${ARGS} --quiet"
fi

echo "→ Running: xcodegen generate ${ARGS}"
xcodegen generate ${ARGS}
