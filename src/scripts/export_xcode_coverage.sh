#!/usr/bin/env bash
# Export Xcode test coverage from xcresult bundle to cobertura XML.
# Requires: xcresultparser (installed via Homebrew)
set -euo pipefail

RESULT_BUNDLE="${RESULT_BUNDLE_PATH:-TestResults.xcresult}"

if [[ ! -d "${RESULT_BUNDLE}" ]]; then
    echo "Error: Result bundle not found at ${RESULT_BUNDLE}"
    exit 1
fi

# Install xcresultparser if not available
if ! command -v xcresultparser &>/dev/null; then
    echo "-> Installing xcresultparser..."
    brew install a7ex/homebrew-formulae/xcresultparser
fi

echo "-> Exporting coverage from ${RESULT_BUNDLE}"

xcresultparser \
    --output-format cobertura \
    "${RESULT_BUNDLE}" \
    > coverage.xml

echo "-> Coverage exported to coverage.xml"
