#!/usr/bin/env bash
# Install sentry-cli (if needed) and upload dSYM debug symbols to Sentry.
# Env vars set by the orb command:
#   DSYM_PATH      - directory searched for .dSYM files to upload
#   SENTRY_ORG     - Sentry organization slug
#   SENTRY_PROJECT - Sentry project slug
#   AUTH_TOKEN_VAR - name of the env var holding the Sentry auth token
#   SKIP_ERRORS    - "true"/"1" makes an upload failure non-fatal
set -euo pipefail

if command -v sentry-cli &>/dev/null; then
    echo "✓ sentry-cli $(sentry-cli --version) already installed"
else
    echo "→ Installing sentry-cli..."
    brew install getsentry/tools/sentry-cli
fi

# Indirect expansion: AUTH_TOKEN_VAR names the env var holding the secret
# (bash 3.2-compatible ${!var} form — macOS ships bash 3.2).
export SENTRY_AUTH_TOKEN="${!AUTH_TOKEN_VAR}"

echo "→ Uploading dSYMs from ${DSYM_PATH} to Sentry (org=${SENTRY_ORG}, project=${SENTRY_PROJECT})"

if sentry-cli debug-files upload --org "${SENTRY_ORG}" --project "${SENTRY_PROJECT}" "${DSYM_PATH}"; then
    echo "✓ dSYM upload complete"
else
    case "${SKIP_ERRORS:-false}" in
        true | 1)
            echo "⚠ dSYM upload failed but skip_errors is enabled — continuing"
            ;;
        *)
            echo "Error: dSYM upload failed"
            exit 1
            ;;
    esac
fi
