#!/usr/bin/env bats
# Tests for scripts/ci/check-coverage-threshold.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/ci/check-coverage-threshold.sh"

setup() {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/check-coverage-threshold.XXXXXX")"
    cd "${TEST_ROOT}"
}

write_cobertura() {
    local line_rate="$1"
    cat > coverage.xml << EOF
<?xml version="1.0" ?>
<coverage line-rate="${line_rate}" branch-rate="0" version="1.9">
    <packages/>
</coverage>
EOF
}

@test "fails when the coverage file does not exist" {
    run bash "${SCRIPT}" missing.xml
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Coverage file not found"* ]]
}

@test "passes when coverage meets the default 80% threshold" {
    write_cobertura "0.85"
    run bash "${SCRIPT}" coverage.xml
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"PASS"* ]]
    [[ "${output}" == *"85.0%"* ]]
}

@test "fails when coverage is below the default 80% threshold" {
    write_cobertura "0.5"
    run bash "${SCRIPT}" coverage.xml
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL"* ]]
    [[ "${output}" == *"50.0%"* ]]
}

@test "honours a custom minimum percentage argument" {
    write_cobertura "0.85"
    run bash "${SCRIPT}" coverage.xml 90
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL"* ]]
    [[ "${output}" == *"minimum required: 90%"* ]]
}

@test "passes at exactly the threshold" {
    write_cobertura "0.80"
    run bash "${SCRIPT}" coverage.xml 80
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"PASS"* ]]
}

@test "fails clearly when line-rate attribute is missing" {
    cat > coverage.xml << 'EOF'
<?xml version="1.0" ?>
<coverage branch-rate="0" version="1.9">
    <packages/>
</coverage>
EOF
    run bash "${SCRIPT}" coverage.xml
    [ "${status}" -ne 0 ]
}
