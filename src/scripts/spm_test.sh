#!/usr/bin/env bash
# Run Swift package tests, piping output through xcbeautify with a JUnit report.
# Env vars set by the orb command:
#   COVERAGE       - "true" to pass --enable-code-coverage
#   PARALLEL       - "true" to pass --parallel
#   FILTER         - test filter pattern (optional)
#   REPORT_PATH    - directory for the JUnit report (default build/reports)
#   TEST_FRAMEWORK - "auto" (default), "xctest", or "swift-testing".
#                    "auto" greps Tests/ for "import Testing"; a hit resolves
#                    to swift-testing, otherwise xctest. swift-testing forces
#                    --parallel (required for --xunit-output) and writes
#                    "${REPORT_PATH}/junit.xml" via `swift test --xunit-output`
#                    instead of xcbeautify's own `--report junit`, to avoid
#                    emitting two JUnit reports.
#   TEST_SPLITS_FILE - optional path to a newline-delimited file of test
#                    target names (written by resolve_test_splits.sh); each
#                    line adds a "--filter <name>" flag.
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

REPORT_PATH="${REPORT_PATH:-build/reports}"
TEST_FRAMEWORK="${TEST_FRAMEWORK:-auto}"

resolve_framework() {
    case "${TEST_FRAMEWORK}" in
        xctest | swift-testing) echo "${TEST_FRAMEWORK}" ;;
        *)
            if [ -d "Tests" ] && grep -rl "import Testing" Tests > /dev/null 2>&1; then
                echo "swift-testing"
            else
                echo "xctest"
            fi
            ;;
    esac
}

FRAMEWORK="$(resolve_framework)"

ARGS=("test")

case "${COVERAGE:-true}" in
    true | 1) ARGS+=("--enable-code-coverage") ;;
    *) ;;
esac

if [ "${FRAMEWORK}" = "swift-testing" ]; then
    case "${PARALLEL:-true}" in
        true | 1) ;;
        *) echo "warning: test_framework=swift-testing requires --parallel for --xunit-output; ignoring parallel=false." >&2 ;;
    esac
    ARGS+=("--parallel")
    mkdir -p "${REPORT_PATH}"
    ARGS+=("--xunit-output" "${REPORT_PATH}/junit.xml")
else
    case "${PARALLEL:-true}" in
        true | 1) ARGS+=("--parallel") ;;
        *) ;;
    esac
fi

if [ -n "${FILTER:-}" ]; then
    ARGS+=("--filter" "${FILTER}")
fi

if [ -n "${TEST_SPLITS_FILE:-}" ] && [ -s "${TEST_SPLITS_FILE}" ]; then
    while IFS= read -r UNIT; do
        [ -z "${UNIT}" ] && continue
        ARGS+=("--filter" "${UNIT}")
    done < "${TEST_SPLITS_FILE}"
fi

echo "→ Running: swift ${ARGS[*]} (framework: ${FRAMEWORK})"
set -o pipefail
if [ "${FRAMEWORK}" = "swift-testing" ]; then
    swift "${ARGS[@]}" 2>&1 | xcbeautify
else
    swift "${ARGS[@]}" 2>&1 | xcbeautify --report junit --report-path "${REPORT_PATH}"
fi
