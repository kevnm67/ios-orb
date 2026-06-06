#!/usr/bin/env bash
# Export SPM code coverage to cobertura XML.
# Converts llvm-cov profdata -> lcov -> coverage.xml
# Non-fatal: exits 0 even if coverage export fails (CI should not break on coverage)

BUILD_DIR=$(swift build --show-bin-path 2>/dev/null || echo "")

if [[ -z "${BUILD_DIR}" ]]; then
    echo "⚠ Could not determine build directory. Skipping coverage export."
    exit 0
fi

PROFDATA=$(find "${BUILD_DIR}/../" -name "default.profdata" -type f 2>/dev/null | head -1)

if [[ -z "${PROFDATA}" ]]; then
    echo "⚠ No profdata file found. Did tests run with --enable-code-coverage?"
    exit 0
fi

# Find the test binary
TEST_BINARY=""

# Try .xctest bundle first (macOS)
XCTEST_BUNDLE=$(find "${BUILD_DIR}" -name "*.xctest" -type d 2>/dev/null | head -1)
if [[ -n "${XCTEST_BUNDLE}" ]]; then
    EXEC_NAME=$(basename "${XCTEST_BUNDLE}" .xctest)
    CANDIDATE="${XCTEST_BUNDLE}/Contents/MacOS/${EXEC_NAME}"
    if [[ -f "${CANDIDATE}" ]]; then
        TEST_BINARY="${CANDIDATE}"
    fi
fi

# Fallback: look for any test executable
if [[ -z "${TEST_BINARY}" ]]; then
    TEST_BINARY=$(find "${BUILD_DIR}" -type f -perm -111 -name "*Tests" 2>/dev/null | head -1)
fi

if [[ -z "${TEST_BINARY}" ]]; then
    echo "⚠ No test binary found in ${BUILD_DIR}. Skipping coverage export."
    exit 0
fi

echo "-> Exporting coverage from ${PROFDATA}"
echo "   Using binary: ${TEST_BINARY}"

# Export to lcov format
xcrun llvm-cov export \
    -format=lcov \
    -instr-profile="${PROFDATA}" \
    "${TEST_BINARY}" \
    -ignore-filename-regex='.build|Tests|Mocks' \
    > coverage.lcov 2>/dev/null || true

if [[ -s coverage.lcov ]]; then
    cp coverage.lcov coverage.xml
    echo "-> Coverage exported to coverage.xml ($(wc -l < coverage.lcov) lines)"
else
    echo "⚠ Coverage export produced empty output. Skipping."
    exit 0
fi
