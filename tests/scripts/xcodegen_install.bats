#!/usr/bin/env bats
# Tests for src/scripts/xcodegen_install.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/xcodegen_install.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
}

@test "skips brew when xcodegen already installed" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}

@test "calls brew install when xcodegen absent" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cp "${STUBS}/brew" "${TMPBIN}/brew"
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install xcodegen" "${STUB_CALL_LOG}"
}

@test "reports XcodeGen version when found" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"XcodeGen"* ]]
}
