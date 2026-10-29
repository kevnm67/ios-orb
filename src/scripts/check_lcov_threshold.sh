#!/usr/bin/env bash
# Fail when the line coverage of an lcov file is below a threshold.
# Env vars set by the orb command:
#   COVERAGE_FILE      - path to the lcov file (default coverage.lcov)
#   COVERAGE_THRESHOLD - minimum line coverage percent, e.g. 85 (0/empty = off)
# Line coverage = sum(LH) / sum(LF) over the file, falling back to counting
# DA records when LF/LH summaries are absent.
set -euo pipefail

COVERAGE_FILE="${COVERAGE_FILE:-coverage.lcov}"
THRESHOLD="${COVERAGE_THRESHOLD:-0}"

if ! awk -v t="${THRESHOLD}" 'BEGIN { exit (t + 0 > 0) ? 0 : 1 }'; then
    echo "Coverage gate disabled (threshold ${THRESHOLD})."
    exit 0
fi

if [ ! -s "${COVERAGE_FILE}" ]; then
    echo "Error: coverage file ${COVERAGE_FILE} is missing or empty; cannot enforce ${THRESHOLD}% threshold." >&2
    exit 1
fi

PERCENT="$(awk -F'[:,]' '
    /^LF:/ { lf += $2; have_summary = 1 }
    /^LH:/ { lh += $2 }
    /^DA:/ { da_total += 1; if ($3 > 0) da_hit += 1 }
    END {
        if (!have_summary) { lf = da_total; lh = da_hit }
        if (lf == 0) { print "0.00" } else { printf "%.2f", lh * 100 / lf }
    }
' "${COVERAGE_FILE}")"

echo "Line coverage: ${PERCENT}% (required: ${THRESHOLD}%)"

if awk -v p="${PERCENT}" -v t="${THRESHOLD}" 'BEGIN { exit (p + 0 >= t + 0) ? 0 : 1 }'; then
    echo "✓ Coverage gate passed."
else
    echo "Error: line coverage ${PERCENT}% is below the required ${THRESHOLD}%." >&2
    exit 1
fi
