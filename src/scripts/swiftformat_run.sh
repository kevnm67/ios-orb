#!/usr/bin/env bash
# Run SwiftFormat with configurable options.
# Env vars set by the orb command:
#   SWIFTFORMAT_LINT   - "true"/"1" for check-only mode (--lint); "false" formats in place
#   SWIFTFORMAT_CONFIG - path to a .swiftformat config file (optional)
#   SWIFTFORMAT_PATHS  - space-separated paths to format/lint (default ".")
set -euo pipefail

# Intentional word-splitting: SWIFTFORMAT_PATHS may contain multiple
# space-separated paths (e.g. "Sources Tests"), each passed as its own arg.
# shellcheck disable=SC2206
PATHS_ARR=(${SWIFTFORMAT_PATHS:-.})

ARGS=()

# Boolean parameters can render as "true" or "1" depending on how the
# command was invoked — accept both.
case "${SWIFTFORMAT_LINT:-true}" in
    true | 1)
        ARGS+=("--lint")
        ;;
    *) ;;
esac

if [ -n "${SWIFTFORMAT_CONFIG:-}" ]; then
    ARGS+=("--config" "${SWIFTFORMAT_CONFIG}")
fi

# macOS ships bash 3.2, where expanding an EMPTY array under `set -u`
# raises "ARGS[*]: unbound variable". Use the ${arr[@]+...} guard.
echo "→ Running: swiftformat ${PATHS_ARR[*]} ${ARGS[*]:-}"
swiftformat "${PATHS_ARR[@]}" ${ARGS[@]+"${ARGS[@]}"}
