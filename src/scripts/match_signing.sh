#!/usr/bin/env bash
# Run Fastlane match for one or more signing types.
# Env vars set by the orb command:
#   MATCH_TYPES         - comma-separated list (e.g. "adhoc,appstore")
#   MATCH_READONLY      - "true" or "false"
#   MATCH_APP_IDENTIFIER - bundle ID (optional, falls back to Matchfile)

set -euo pipefail

IFS=',' read -ra TYPES <<< "${MATCH_TYPES}"

for t in "${TYPES[@]}"; do
    t=$(echo "$t" | xargs)  # trim whitespace
    ARGS="match ${t}"

    if [ "${MATCH_READONLY}" = "true" ]; then
        ARGS="${ARGS} --readonly"
    fi

    if [ -n "${MATCH_APP_IDENTIFIER:-}" ]; then
        ARGS="${ARGS} --app_identifier ${MATCH_APP_IDENTIFIER}"
    fi

    echo "→ Running: bundle exec fastlane ${ARGS}"
    bundle exec fastlane ${ARGS}
done
