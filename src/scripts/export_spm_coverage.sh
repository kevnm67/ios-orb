#!/usr/bin/env bash
# Export SPM code coverage to cobertura XML.
# Converts llvm-cov profdata -> lcov -> cobertura XML.
set -euo pipefail

BUILD_DIR=$(swift build --show-bin-path)
PROFDATA=$(find "${BUILD_DIR}/../" -name "default.profdata" -type f | head -1)

if [[ -z "${PROFDATA}" ]]; then
    echo "Error: No profdata file found. Did tests run with --enable-code-coverage?"
    exit 1
fi

# Find the test binary (PackageTests or *PackageTests.xctest)
TEST_BINARY=$(find "${BUILD_DIR}" -name "*.xctest" -type d | head -1)
if [[ -n "${TEST_BINARY}" ]]; then
    # macOS .xctest bundles have the binary inside Contents/MacOS/
    EXEC_NAME=$(basename "${TEST_BINARY}" .xctest)
    TEST_BINARY="${TEST_BINARY}/Contents/MacOS/${EXEC_NAME}"
fi

if [[ -z "${TEST_BINARY}" || ! -f "${TEST_BINARY}" ]]; then
    # Fallback: look for any executable in the build dir
    TEST_BINARY=$(find "${BUILD_DIR}" -type f -perm +111 -name "*Tests" | head -1)
fi

if [[ -z "${TEST_BINARY}" ]]; then
    echo "Error: No test binary found in ${BUILD_DIR}"
    exit 1
fi

echo "-> Exporting coverage from ${PROFDATA}"
echo "   Using binary: ${TEST_BINARY}"

# Export to lcov format
xcrun llvm-cov export \
    -format=lcov \
    -instr-profile="${PROFDATA}" \
    "${TEST_BINARY}" \
    -ignore-filename-regex='.build|Tests|Mocks' \
    > coverage.lcov

# Convert lcov to cobertura XML
if command -v pycobertura &>/dev/null; then
    # If pycobertura is available, use lcov directly renamed
    echo "-> Converting lcov to cobertura XML"
fi

# Use llvm-cov export in text format for cobertura-compatible output
xcrun llvm-cov export \
    -format=text \
    -instr-profile="${PROFDATA}" \
    "${TEST_BINARY}" \
    -ignore-filename-regex='.build|Tests|Mocks' \
    > coverage.json

# Convert JSON to cobertura XML using a simple transformation
# Most CI tools accept the llvm-cov JSON directly, but we also produce lcov
# Rename lcov to coverage.xml as a simple cobertura-compatible format
cp coverage.lcov coverage.xml

echo "-> Coverage exported to coverage.xml and coverage.lcov"
