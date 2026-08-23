#!/usr/bin/env bats
# Tests for src/scripts/periphery_install.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/periphery_install.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
# Minimal system PATH that has bash/test/etc but not Homebrew binaries
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
}

@test "skips brew when periphery already installed" {
    # periphery stub is present in STUBS — appears installed
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}

@test "calls brew install periphery (core formula, no tap) when absent" {
    # TMPBIN has brew but NOT periphery; system path excluded to prevent real periphery
    TMPBIN="$(mktemp -d "${BATS_TMPDIR}/bin.XXXXXX")"
    cp "${STUBS}/brew" "${TMPBIN}/brew"
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install periphery$" "${STUB_CALL_LOG}"
}

@test "outputs version when periphery found" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Periphery"* ]]
}
