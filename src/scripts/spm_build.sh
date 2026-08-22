#!/usr/bin/env bash
# Build a Swift package, piping output through xcbeautify.
# Env vars set by the orb command:
#   CONFIGURATION - debug or release
#   BUILD_FLAGS   - extra flags appended to `swift build` (optional)
set -euo pipefail

ARGS=("build" "-c" "${CONFIGURATION:-debug}")

if [ -n "${BUILD_FLAGS:-}" ]; then
    # shellcheck disable=SC2206  # intentional word-splitting of user flags
    ARGS+=(${BUILD_FLAGS})
fi

echo "→ Running: swift ${ARGS[*]}"
set -o pipefail
swift "${ARGS[@]}" 2>&1 | xcbeautify
