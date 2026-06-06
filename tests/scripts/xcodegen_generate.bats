#!/usr/bin/env bats
# Tests for src/scripts/xcodegen_generate.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/xcodegen_generate.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export XCODEGEN_SPEC="project.yml"
    export XCODEGEN_QUIET="false"
}

@test "runs xcodegen generate with spec" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodegen generate --spec project.yml$" "${STUB_CALL_LOG}"
}

@test "adds --quiet when XCODEGEN_QUIET=true" {
    export XCODEGEN_QUIET=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodegen generate --spec project.yml --quiet$" "${STUB_CALL_LOG}"
}

@test "does not add --quiet when XCODEGEN_QUIET=false" {
    export XCODEGEN_QUIET=false
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^xcodegen generate" "${STUB_CALL_LOG}")
    [[ "${result}" != *"--quiet"* ]]
}

@test "uses custom spec path" {
    export XCODEGEN_SPEC="custom/spec.yml"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodegen generate --spec custom/spec.yml$" "${STUB_CALL_LOG}"
}

@test "output includes running line" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Running: xcodegen generate"* ]]
}
