#!/usr/bin/env bats
# Tests for src/scripts/swiftlint_run.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/swiftlint_run.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    # Unset env vars so each test starts clean
    unset SWIFTLINT_STRICT SWIFTLINT_CONFIG SWIFTLINT_REPORTER
}

@test "runs swiftlint with no flags when all env vars unset" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    # log has "swiftlint " (with trailing space) or "swiftlint" when no args
    grep -qE "^swiftlint\s*$" "${STUB_CALL_LOG}"
}

@test "adds --strict when SWIFTLINT_STRICT=true" {
    export SWIFTLINT_STRICT=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --strict" "${STUB_CALL_LOG}"
}

@test "adds --strict when SWIFTLINT_STRICT=1" {
    export SWIFTLINT_STRICT=1
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --strict" "${STUB_CALL_LOG}"
}

@test "no --strict when SWIFTLINT_STRICT=false" {
    export SWIFTLINT_STRICT=false
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--strict"* ]]
}

@test "no --strict when SWIFTLINT_STRICT is empty string" {
    export SWIFTLINT_STRICT=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--strict"* ]]
}

@test "adds --config when SWIFTLINT_CONFIG is set" {
    export SWIFTLINT_CONFIG=".swiftlint.yml"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --config .swiftlint.yml" "${STUB_CALL_LOG}"
}

@test "adds --reporter when SWIFTLINT_REPORTER is set" {
    export SWIFTLINT_REPORTER="junit"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --reporter junit" "${STUB_CALL_LOG}"
}

@test "combines strict + config + reporter" {
    export SWIFTLINT_STRICT=true
    export SWIFTLINT_CONFIG=".swiftlint.yml"
    export SWIFTLINT_REPORTER="junit"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --strict --config .swiftlint.yml --reporter junit" "${STUB_CALL_LOG}"
}

@test "combines strict=1 + reporter only (no config)" {
    export SWIFTLINT_STRICT=1
    export SWIFTLINT_REPORTER="xcode"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swiftlint --strict --reporter xcode" "${STUB_CALL_LOG}"
}

@test "does not pass --config when SWIFTLINT_CONFIG is empty" {
    export SWIFTLINT_CONFIG=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--config"* ]]
}

@test "does not pass --reporter when SWIFTLINT_REPORTER is empty" {
    export SWIFTLINT_REPORTER=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"--reporter"* ]]
}

@test "output includes the running line" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Running: swiftlint"* ]]
}
