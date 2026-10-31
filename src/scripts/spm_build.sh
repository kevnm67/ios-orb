#!/usr/bin/env bash
# Build a Swift package, piping output through xcbeautify.
# Env vars set by the orb command:
#   CONFIGURATION - debug or release
#   BUILD_FLAGS   - extra flags appended to `swift build` (optional)
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

ARGS=("build" "-c" "${CONFIGURATION:-debug}")

if [ -n "${BUILD_FLAGS:-}" ]; then
    # shellcheck disable=SC2206  # intentional word-splitting of user flags
    ARGS+=(${BUILD_FLAGS})
fi

echo "→ Running: swift ${ARGS[*]}"
set -o pipefail
swift "${ARGS[@]}" 2>&1 | xcbeautify
