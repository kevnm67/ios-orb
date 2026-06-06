#!/usr/bin/env bash
# Run bats tests for orb scripts with kcov coverage.
# Designed for Linux CI (kcov + bats-core available via apt / package manager).
# Locally: just run `bats tests/scripts` — kcov is not required on macOS.
#
# Usage: ./scripts/ci/run-script-tests.sh
# Output: coverage/cobertura.xml  (merged cobertura from all bats files)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_DIR="${REPO_ROOT}/coverage"
KCOV_OUT="${COVERAGE_DIR}/kcov"
TESTS_DIR="${REPO_ROOT}/tests/scripts"
SRC_DIR="${REPO_ROOT}/src/scripts"

mkdir -p "${COVERAGE_DIR}" "${KCOV_OUT}"

if ! command -v kcov &>/dev/null; then
    echo "ERROR: kcov not found. Install via apt-get install kcov (Ubuntu) or brew install kcov (macOS)." >&2
    exit 1
fi

if ! command -v bats &>/dev/null; then
    echo "ERROR: bats not found. Install via apt-get install bats or brew install bats-core." >&2
    exit 1
fi

echo "-> Running bats tests with kcov instrumentation..."
echo "   Source dir: ${SRC_DIR}"
echo "   Tests dir:  ${TESTS_DIR}"
echo "   Output dir: ${KCOV_OUT}"

# Run kcov per bats file for finer-grained per-file coverage reports
MERGE_DIRS=()
for bats_file in "${TESTS_DIR}"/*.bats; do
    base="$(basename "${bats_file}" .bats)"
    out_dir="${KCOV_OUT}/${base}"
    mkdir -p "${out_dir}"
    echo "   -> kcov ${base}..."
    kcov \
        --include-path="${SRC_DIR}" \
        --exclude-pattern=".bats" \
        "${out_dir}" \
        bats "${bats_file}"
    MERGE_DIRS+=("${out_dir}")
done

# Merge all individual reports into a single directory
MERGED_DIR="${KCOV_OUT}/merged"
echo "-> Merging coverage reports..."
kcov --merge "${MERGED_DIR}" "${MERGE_DIRS[@]}"

# Locate cobertura.xml from the merged output
COBERTURA_SRC="$(find "${MERGED_DIR}" -name "cobertura.xml" | head -1)"
if [[ -z "${COBERTURA_SRC}" ]]; then
    echo "ERROR: cobertura.xml not found in ${MERGED_DIR}" >&2
    exit 1
fi

cp "${COBERTURA_SRC}" "${COVERAGE_DIR}/cobertura.xml"
echo "-> Coverage report: ${COVERAGE_DIR}/cobertura.xml"

# Print a quick summary line from the merged HTML if available
SUMMARY="$(find "${MERGED_DIR}" -name "*.json" | head -1)"
if [[ -n "${SUMMARY}" ]]; then
    echo "-> Merge summary available at: ${SUMMARY}"
fi

echo "-> Done."
