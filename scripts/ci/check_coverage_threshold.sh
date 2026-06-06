#!/usr/bin/env bash
# check_coverage_threshold.sh — verify cobertura line-rate meets minimum threshold.
#
# Usage: check_coverage_threshold.sh <cobertura.xml> [min_percent]
#   cobertura.xml  Path to the cobertura-format XML coverage report.
#   min_percent    Minimum acceptable coverage percentage (default: 80).
#
# Exits 0 on success, 1 on failure or invalid input.
set -euo pipefail

COVERAGE_FILE="${1:-coverage.xml}"
MIN_PERCENT="${2:-80}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "ERROR: Coverage file not found: ${COVERAGE_FILE}"
    exit 1
fi

# Extract line-rate attribute from the root <coverage> element.
# Cobertura spec: <coverage line-rate="0.923" ...>
LINE_RATE=$(python3 - <<PYEOF
import sys
import xml.etree.ElementTree as ET

tree = ET.parse("${COVERAGE_FILE}")
root = tree.getroot()
rate = root.get("line-rate")
if rate is None:
    print("ERROR: line-rate attribute not found in coverage XML", file=sys.stderr)
    sys.exit(1)
print(rate)
PYEOF
)

ACHIEVED=$(python3 -c "print(round(float('${LINE_RATE}') * 100, 2))")

echo "Coverage achieved: ${ACHIEVED}%  (minimum required: ${MIN_PERCENT}%)"

PASSED=$(python3 -c "print('yes' if float('${LINE_RATE}') * 100 >= float('${MIN_PERCENT}') else 'no')")

if [[ "${PASSED}" == "yes" ]]; then
    echo "PASS: Coverage ${ACHIEVED}% meets the ${MIN_PERCENT}% threshold."
    exit 0
else
    echo "FAIL: Coverage ${ACHIEVED}% is below the required ${MIN_PERCENT}% threshold."
    exit 1
fi
