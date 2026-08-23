#!/usr/bin/env bats
# Tests for src/scripts/swiftformat_run.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/swiftformat_run.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    # Unset env vars so each test starts clean
    unset SWIFTFORMAT_LINT SWIFTFORMAT_CONFIG SWIFTFORMAT_PATHS
}

@test "defaults to path '.' with --lint when env vars unset" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat \. --lint$" "${STUB_CALL_LOG}"
}

@test "adds --lint when SWIFTFORMAT_LINT=true" {
    export SWIFTFORMAT_LINT=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat \. --lint$" "${STUB_CALL_LOG}"
}

@test "adds --lint when SWIFTFORMAT_LINT=1" {
    export SWIFTFORMAT_LINT=1
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat \. --lint$" "${STUB_CALL_LOG}"
}

@test "formats in place (no --lint) when SWIFTFORMAT_LINT=false" {
    export SWIFTFORMAT_LINT=false
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--lint"* ]]
}

@test "adds --config when SWIFTFORMAT_CONFIG is set" {
    export SWIFTFORMAT_CONFIG=".swiftformat"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat \. --lint --config .swiftformat$" "${STUB_CALL_LOG}"
}

@test "does not pass --config when SWIFTFORMAT_CONFIG is empty" {
    export SWIFTFORMAT_CONFIG=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--config"* ]]
}

@test "splits multiple space-separated paths into separate args" {
    export SWIFTFORMAT_PATHS="Sources Tests"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat Sources Tests --lint$" "${STUB_CALL_LOG}"
}

@test "combines lint=false + config + multiple paths" {
    export SWIFTFORMAT_LINT=false
    export SWIFTFORMAT_CONFIG=".swiftformat"
    export SWIFTFORMAT_PATHS="Sources Tests"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftformat Sources Tests --config .swiftformat$" "${STUB_CALL_LOG}"
}

@test "output includes the running line" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Running: swiftformat"* ]]
}
