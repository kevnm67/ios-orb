#!/usr/bin/env bats
# Tests for scripts/ci/verify-spm-lcov.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/ci/verify-spm-lcov.sh"

setup() {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/verify-spm-lcov.XXXXXX")"
    cd "${TEST_ROOT}"
}

valid_lcov() {
    cat > "$1" << 'EOF'
SF:Sources/Foo.swift
DA:1,1
DA:2,0
end_of_record
EOF
}

@test "fails when the lcov file is missing" {
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"missing or empty"* ]]
}

@test "fails when the lcov file is empty" {
    touch coverage.lcov
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"missing or empty"* ]]
}

@test "fails when there are no SF: records" {
    printf 'DA:1,1\nend_of_record\n' > coverage.lcov
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"no SF: records"* ]]
}

@test "fails when there is no end_of_record marker" {
    printf 'SF:Sources/Foo.swift\nDA:1,1\n' > coverage.lcov
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"no end_of_record marker"* ]]
}

@test "fails when coverage.xml also exists (mislabeled cobertura)" {
    valid_lcov coverage.lcov
    touch coverage.xml
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"coverage.xml exists"* ]]
}

@test "passes for a valid lcov file with no coverage.xml" {
    valid_lcov coverage.lcov
    run bash "${SCRIPT}" coverage.lcov
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"is valid lcov"* ]]
}

@test "defaults to coverage.lcov when no argument is given" {
    valid_lcov coverage.lcov
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"is valid lcov"* ]]
}
