#!/usr/bin/env bats
# Tests for src/scripts/check_lcov_threshold.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/check_lcov_threshold.sh"

setup() {
    export COVERAGE_FILE="${BATS_TMPDIR}/cov_${BATS_TEST_NUMBER}.lcov"
    unset COVERAGE_THRESHOLD
}

write_lcov() {
    # $1 = LF, $2 = LH
    printf 'SF:a.swift\nDA:1,1\nLF:%s\nLH:%s\nend_of_record\n' "$1" "$2" > "${COVERAGE_FILE}"
}

@test "disabled when threshold is unset (even if file is missing)" {
    rm -f "${COVERAGE_FILE}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"disabled"* ]]
}

@test "disabled when threshold is 0" {
    export COVERAGE_THRESHOLD=0
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "passes when coverage meets the threshold exactly" {
    write_lcov 100 85
    export COVERAGE_THRESHOLD=85
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Line coverage: 85.00% (required: 85%)"* ]]
}

@test "fails when coverage is below the threshold" {
    write_lcov 100 84
    export COVERAGE_THRESHOLD=85
    run bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"below the required 85%"* ]]
}

@test "sums LF/LH across multiple records" {
    printf 'SF:a\nLF:10\nLH:10\nend_of_record\nSF:b\nLF:10\nLH:0\nend_of_record\n' > "${COVERAGE_FILE}"
    export COVERAGE_THRESHOLD=50
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"50.00%"* ]]
}

@test "falls back to DA records when LF/LH are absent" {
    printf 'SF:a\nDA:1,1\nDA:2,0\nDA:3,4\nDA:4,0\nend_of_record\n' > "${COVERAGE_FILE}"
    export COVERAGE_THRESHOLD=50
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"50.00%"* ]]
}

@test "fails with a clear error when the file is missing and a threshold is set" {
    rm -f "${COVERAGE_FILE}"
    export COVERAGE_THRESHOLD=85
    run bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"missing or empty"* ]]
}
