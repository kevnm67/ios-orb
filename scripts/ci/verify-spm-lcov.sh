#!/usr/bin/env bash
# Verify the SPM coverage export produced valid lcov output.
# Regression guard for the export_coverage spm branch: the export must write
# coverage.lcov (real lcov records) and must NOT write coverage.xml — an
# lcov file renamed .xml makes qlty infer cobertura and fail to parse it.
#
# Usage: ./scripts/ci/verify-spm-lcov.sh [lcov_file]
set -euo pipefail

LCOV_FILE="${1:-coverage.lcov}"

if [[ ! -s "${LCOV_FILE}" ]]; then
    echo "ERROR: ${LCOV_FILE} is missing or empty." >&2
    exit 1
fi

if ! grep -q '^SF:' "${LCOV_FILE}"; then
    echo "ERROR: ${LCOV_FILE} has no SF: records — not valid lcov." >&2
    exit 1
fi

if ! grep -q '^end_of_record' "${LCOV_FILE}"; then
    echo "ERROR: ${LCOV_FILE} has no end_of_record marker — not valid lcov." >&2
    exit 1
fi

if [[ -f coverage.xml ]]; then
    echo "ERROR: coverage.xml exists — SPM export must not mislabel lcov as cobertura XML." >&2
    exit 1
fi

echo "✓ ${LCOV_FILE} is valid lcov ($(grep -c '^SF:' "${LCOV_FILE}") source files) and no coverage.xml was produced."
