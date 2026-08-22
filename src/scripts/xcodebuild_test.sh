#!/usr/bin/env bash
# Run Xcode tests with code coverage, piping output through xcbeautify and
# emitting a JUnit report for CircleCI test insights.
# Env vars set by the orb command:
#   SCHEME             - Xcode scheme to test
#   PROJECT            - path to .xcodeproj (optional; empty = default project)
#   DESTINATION        - xcodebuild -destination value
#   RESULT_BUNDLE_PATH - where to write the .xcresult bundle
#   JUNIT_REPORT       - JUnit XML output path (default test-results.xml)
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

echo "→ Running: xcodebuild ${ARGS[*]}"
set -o pipefail
xcodebuild "${ARGS[@]}" \
    | xcbeautify --report junit --junit-report-filename "${JUNIT_REPORT}"
