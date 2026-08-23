#!/usr/bin/env bats
# Tests for src/scripts/periphery_run.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/periphery_run.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    # Unset env vars so each test starts clean
    unset PERIPHERY_CONFIG PERIPHERY_STRICT PERIPHERY_EXTRA_ARGS
}

@test "runs periphery scan with no flags when all env vars unset" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan$" "${STUB_CALL_LOG}"
}

@test "adds --config when PERIPHERY_CONFIG is set" {
    export PERIPHERY_CONFIG=".periphery.yml"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan --config .periphery.yml$" "${STUB_CALL_LOG}"
}

@test "does not pass --config when PERIPHERY_CONFIG is empty" {
    export PERIPHERY_CONFIG=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--config"* ]]
}

@test "adds --strict when PERIPHERY_STRICT=true" {
    export PERIPHERY_STRICT=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan --strict$" "${STUB_CALL_LOG}"
}

@test "adds --strict when PERIPHERY_STRICT=1" {
    export PERIPHERY_STRICT=1
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan --strict$" "${STUB_CALL_LOG}"
}

@test "no --strict when PERIPHERY_STRICT=false" {
    export PERIPHERY_STRICT=false
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--strict"* ]]
}

@test "appends extra_args as separate flags" {
    export PERIPHERY_EXTRA_ARGS="--format json --retain-public"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan --format json --retain-public$" "${STUB_CALL_LOG}"
}

@test "combines config + strict + extra_args" {
    export PERIPHERY_CONFIG=".periphery.yml"
    export PERIPHERY_STRICT=true
    export PERIPHERY_EXTRA_ARGS="--format json"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^periphery scan --config .periphery.yml --strict --format json$" "${STUB_CALL_LOG}"
}

@test "output includes the running line" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Running: periphery scan"* ]]
}
