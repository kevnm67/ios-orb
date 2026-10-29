#!/usr/bin/env bash
# Run Xcode tests with code coverage, piping output through xcbeautify and
# emitting a JUnit report for CircleCI test insights.
# Env vars set by the orb command:
#   SCHEME             - Xcode scheme to test
#   PROJECT            - path to .xcodeproj (optional; empty = default project)
#   DESTINATION        - xcodebuild -destination value
#   RESULT_BUNDLE_PATH - where to write the .xcresult bundle
#   JUNIT_REPORT       - JUnit XML output path (default test-results.xml)
#   RETRY_ON_FAILURE   - "true"/"1" to retry only the tests that failed
#   TEST_ITERATIONS    - max iterations per test when retrying (default 3)
#   TEST_TARGET        - test target name used to scope -only-testing when
#                        TEST_SPLITS_FILE is set (default: SCHEME)
#   TEST_SPLITS_FILE   - optional path to a newline-delimited file of test
#                        class names (written by resolve_test_splits.sh);
#                        each line adds "-only-testing:TEST_TARGET/<class>"
#   XCARGS             - extra xcodebuild arguments / build settings, word-split
#                        and appended last (e.g. "CODE_SIGNING_ALLOWED=NO")
#   JUNIT_SOURCE       - "xcbeautify" (default) writes the JUnit report via
#                        xcbeautify's own reporter. "xcresultparser" pipes
#                        xcodebuild through plain xcbeautify (no report) and
#                        separately runs xcresultparser against the xcresult
#                        bundle to produce the JUnit XML. Verified
#                        2026-08-23 against Xcode 26 (xcresulttool tool
#                        version 24757): `xcresulttool get test-results`
#                        only exposes summary/tests/test-details/
#                        activities/insights/metrics, and `xcresulttool
#                        export` only exposes object/diagnostics/coverage/
#                        attachments/metrics — neither has a JUnit output,
#                        so the "xcresulttool" alternative documented in the
#                        roadmap is implemented via xcresultparser (already
#                        bundled by this orb for cobertura export in
#                        export_xcode_coverage.sh), which wraps xcresulttool
#                        and does support --output-format junit.
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

JUNIT_REPORT="${JUNIT_REPORT:-test-results.xml}"
JUNIT_SOURCE="${JUNIT_SOURCE:-xcbeautify}"
TEST_TARGET="${TEST_TARGET:-${SCHEME}}"

# Remove a stale result bundle — xcodebuild refuses to overwrite one.
rm -rf "${RESULT_BUNDLE_PATH}"

ARGS=("test" "-scheme" "${SCHEME}")

if [ -n "${PROJECT:-}" ]; then
    ARGS+=("-project" "${PROJECT}")
fi

ARGS+=(
    "-destination" "${DESTINATION}"
    "-enableCodeCoverage" "YES"
    "-resultBundlePath" "${RESULT_BUNDLE_PATH}"
)

case "${RETRY_ON_FAILURE:-false}" in
    true | 1) ARGS+=("-retry-tests-on-failure" "-test-iterations" "${TEST_ITERATIONS:-3}") ;;
    *) ;;
esac

if [ -n "${TEST_SPLITS_FILE:-}" ] && [ -s "${TEST_SPLITS_FILE}" ]; then
    while IFS= read -r CLASS; do
        [ -z "${CLASS}" ] && continue
        ARGS+=("-only-testing:${TEST_TARGET}/${CLASS}")
    done < "${TEST_SPLITS_FILE}"
fi

if [ -n "${XCARGS:-}" ]; then
    # shellcheck disable=SC2206  # intentional word-splitting of user args
    ARGS+=(${XCARGS})
fi

echo "→ Running: xcodebuild ${ARGS[*]}"
set -o pipefail
if [ "${JUNIT_SOURCE}" = "xcresultparser" ]; then
    xcodebuild "${ARGS[@]}" | xcbeautify

    if ! command -v xcresultparser &> /dev/null; then
        echo "→ Installing xcresultparser..."
        brew install a7ex/homebrew-formulae/xcresultparser
    fi

    xcresultparser --output-format junit "${RESULT_BUNDLE_PATH}" > "${JUNIT_REPORT}"
else
    xcodebuild "${ARGS[@]}" \
        | xcbeautify --report junit --junit-report-filename "${JUNIT_REPORT}"
fi
