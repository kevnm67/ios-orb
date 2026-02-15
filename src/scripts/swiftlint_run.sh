#!/usr/bin/env bash
# Run SwiftLint with configurable options.
# Env vars set by the orb command:
#   SWIFTLINT_STRICT  - "true" or "false"
#   SWIFTLINT_CONFIG  - path to config file (optional)
#   SWIFTLINT_REPORTER - reporter type (optional)
set -euo pipefail

ARGS=""

if [ "${SWIFTLINT_STRICT}" = "true" ]; then
    ARGS="${ARGS} --strict"
fi

if [ -n "${SWIFTLINT_CONFIG:-}" ]; then
    ARGS="${ARGS} --config ${SWIFTLINT_CONFIG}"
fi

if [ -n "${SWIFTLINT_REPORTER:-}" ]; then
    ARGS="${ARGS} --reporter ${SWIFTLINT_REPORTER}"
fi

echo "→ Running: swiftlint ${ARGS}"
swiftlint ${ARGS}
