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
set -euo pipefail

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
