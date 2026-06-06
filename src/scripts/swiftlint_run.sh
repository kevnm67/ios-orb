#!/usr/bin/env bash
# Run SwiftLint with configurable options.
# Env vars set by the orb command:
#   SWIFTLINT_STRICT  - "true" or "false"
#   SWIFTLINT_CONFIG  - path to config file (optional)
#   SWIFTLINT_REPORTER - reporter type (optional)
set -euo pipefail

ARGS=()

# Boolean parameters can render as "true" or "1" depending on how the
# command was invoked — accept both.
case "${SWIFTLINT_STRICT:-false}" in
    true | 1)
        ARGS+=("--strict")
        ;;
    *) ;;
esac

if [ -n "${SWIFTLINT_CONFIG:-}" ]; then
    ARGS+=("--config" "${SWIFTLINT_CONFIG}")
fi

if [ -n "${SWIFTLINT_REPORTER:-}" ]; then
    ARGS+=("--reporter" "${SWIFTLINT_REPORTER}")
fi

# macOS ships bash 3.2, where expanding an EMPTY array under `set -u`
# raises "ARGS[*]: unbound variable". Use the ${arr[@]+...} guard.
echo "→ Running: swiftlint ${ARGS[*]:-}"
swiftlint ${ARGS[@]+"${ARGS[@]}"}
