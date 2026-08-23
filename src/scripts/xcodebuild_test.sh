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
set -euo pipefail

JUNIT_REPORT="${JUNIT_REPORT:-test-results.xml}"

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

echo "→ Running: xcodebuild ${ARGS[*]}"
set -o pipefail
xcodebuild "${ARGS[@]}" \
    | xcbeautify --report junit --junit-report-filename "${JUNIT_REPORT}"
