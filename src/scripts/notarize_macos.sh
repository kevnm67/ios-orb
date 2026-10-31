#!/usr/bin/env bash
# Zip, submit for notarization, and (optionally) staple a macOS .app bundle.
# Env vars set by the orb command:
#   APP_PATH          - path to the .app bundle to notarize
#   API_KEY_PATH_VAR  - name of the env var holding the ASC API key (.p8) path
#   API_KEY_ID_VAR    - name of the env var holding the ASC API key ID
#   API_ISSUER_ID_VAR - name of the env var holding the ASC API issuer ID
#   STAPLE            - "true"/"1" staples the ticket after a successful submission
#   STEP_TIMEOUT  - optional wall-clock limit in seconds (0/empty = off)
set -euo pipefail

# Optional wall-clock limit: STEP_TIMEOUT seconds (0/empty = off). Re-runs
# this script under a watchdog and TERMs its whole process group on expiry,
# failing with exit 124 and a clear message (bash 3.2-compatible; macOS has
# no `timeout`). Independent of CircleCI's no_output_timeout.
if [ "${STEP_TIMEOUT:-0}" -gt 0 ] 2> /dev/null && [ -z "${STEP_TIMEOUT_ACTIVE:-}" ]; then
    TIMED_OUT_MARKER="$(mktemp "${TMPDIR:-/tmp}/step-timeout.XXXXXX")"
    rm -f "${TIMED_OUT_MARKER}"
    set -m
    STEP_TIMEOUT_ACTIVE=1 bash "$0" &
    STEP_PID=$!
    (sleep "${STEP_TIMEOUT}" && touch "${TIMED_OUT_MARKER}" && kill -TERM -- "-${STEP_PID}") 2> /dev/null &
    WATCHDOG_PID=$!
    STEP_STATUS=0
    wait "${STEP_PID}" || STEP_STATUS=$?
    kill -- "-${WATCHDOG_PID}" 2> /dev/null || true
    if [ -e "${TIMED_OUT_MARKER}" ]; then
        rm -f "${TIMED_OUT_MARKER}"
        echo "Error: step exceeded its ${STEP_TIMEOUT}s timeout and was terminated." >&2
        exit 124
    fi
    exit "${STEP_STATUS}"
fi

# shellcheck disable=SC2153 # APP_PATH is set by the orb command, not a typo of ZIP_PATH
if [[ ! -d "${APP_PATH}" ]]; then
    echo "Error: app bundle not found at ${APP_PATH}"
    exit 1
fi

# Indirect expansion: the *_VAR variables name the env vars holding the ASC
# credentials (bash 3.2-compatible ${!var} form — macOS ships bash 3.2).
KEY_PATH="${!API_KEY_PATH_VAR}"
KEY_ID="${!API_KEY_ID_VAR}"
ISSUER_ID="${!API_ISSUER_ID_VAR}"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/notarize.XXXXXX")"
trap 'rm -rf "${WORKDIR}"' EXIT

ZIP_PATH="${WORKDIR}/$(basename "${APP_PATH}").zip"

echo "→ Zipping ${APP_PATH} for notarization"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "→ Submitting ${ZIP_PATH} to notarytool"
xcrun notarytool submit "${ZIP_PATH}" --key "${KEY_PATH}" --key-id "${KEY_ID}" --issuer "${ISSUER_ID}" --wait

case "${STAPLE:-true}" in
    true | 1)
        echo "→ Stapling notarization ticket to ${APP_PATH}"
        xcrun stapler staple "${APP_PATH}"
        ;;
    *) ;;
esac

echo "✓ Notarization complete for ${APP_PATH}"
