#!/usr/bin/env bash
# Run a Periphery unused-code scan.
# Env vars set by the orb command:
#   PERIPHERY_CONFIG     - path to a periphery.yml config file (optional)
#   PERIPHERY_STRICT     - "true"/"1" fails the scan on any result (--strict)
#   PERIPHERY_EXTRA_ARGS - additional periphery scan flags (optional, space-separated)
set -euo pipefail

ARGS=("scan")

if [ -n "${PERIPHERY_CONFIG:-}" ]; then
    ARGS+=("--config" "${PERIPHERY_CONFIG}")
fi

# Boolean parameters can render as "true" or "1" depending on how the
# command was invoked — accept both.
case "${PERIPHERY_STRICT:-false}" in
    true | 1)
        ARGS+=("--strict")
        ;;
    *) ;;
esac

if [ -n "${PERIPHERY_EXTRA_ARGS:-}" ]; then
    # Intentional word-splitting: extra_args may contain multiple flags.
    # shellcheck disable=SC2206
    EXTRA_ARR=(${PERIPHERY_EXTRA_ARGS})
    ARGS+=("${EXTRA_ARR[@]}")
fi

echo "→ Running: periphery ${ARGS[*]}"
periphery "${ARGS[@]}"
