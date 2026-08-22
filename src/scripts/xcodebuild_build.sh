#!/usr/bin/env bash
# Build an Xcode project, piping output through xcbeautify.
# Env vars set by the orb command:
#   SCHEME        - Xcode scheme to build
#   PROJECT       - path to .xcodeproj (optional; empty = default project)
#   DESTINATION   - xcodebuild -destination value
#   CONFIGURATION - build configuration (Debug/Release)
set -euo pipefail

ARGS=("build" "-scheme" "${SCHEME}")

if [ -n "${PROJECT:-}" ]; then
    ARGS+=("-project" "${PROJECT}")
fi

ARGS+=("-destination" "${DESTINATION}" "-configuration" "${CONFIGURATION}")

echo "→ Running: xcodebuild ${ARGS[*]}"
set -o pipefail
xcodebuild "${ARGS[@]}" | xcbeautify
