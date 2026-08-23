#!/usr/bin/env bash
# Run Fastlane match for one or more signing types.
# Env vars set by the orb command:
#   MATCH_TYPES         - comma-separated list (e.g. "adhoc,appstore")
#   MATCH_READONLY      - "true"/"1" for readonly, anything else is falsy
#   MATCH_APP_IDENTIFIER - bundle ID (optional, falls back to Matchfile)

set -euo pipefail

IFS=',' read -ra TYPES <<< "${MATCH_TYPES}"

for t in "${TYPES[@]}"; do
    t=$(echo "$t" | xargs)  # trim whitespace
    ARGS=("match" "${t}")

    case "${MATCH_READONLY:-false}" in
        true | 1)
            ARGS+=("--readonly")
            ;;
    esac

    if [ -n "${MATCH_APP_IDENTIFIER:-}" ]; then
        ARGS+=("--app_identifier" "${MATCH_APP_IDENTIFIER}")
    fi

    echo "→ Running: bundle exec fastlane ${ARGS[*]}"
    bundle exec fastlane "${ARGS[@]}"
done
