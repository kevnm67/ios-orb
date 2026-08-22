#!/usr/bin/env bash
# Run Swift package tests, piping output through xcbeautify with a JUnit report.
# Env vars set by the orb command:
#   COVERAGE    - "true" to pass --enable-code-coverage
#   PARALLEL    - "true" to pass --parallel
#   FILTER      - test filter pattern (optional)
#   REPORT_PATH - directory for the JUnit report (default build/reports)
set -euo pipefail

REPORT_PATH="${REPORT_PATH:-build/reports}"
ARGS=("test")

case "${COVERAGE:-true}" in
    true | 1) ARGS+=("--enable-code-coverage") ;;
    *) ;;
esac

case "${PARALLEL:-true}" in
    true | 1) ARGS+=("--parallel") ;;
    *) ;;
esac

if [ -n "${FILTER:-}" ]; then
    ARGS+=("--filter" "${FILTER}")
fi

echo "→ Running: swift ${ARGS[*]}"
set -o pipefail
swift "${ARGS[@]}" 2>&1 | xcbeautify --report junit --report-path "${REPORT_PATH}"
