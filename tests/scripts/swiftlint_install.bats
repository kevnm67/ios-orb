#!/usr/bin/env bats
# Tests for src/scripts/swiftlint_install.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/swiftlint_install.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
# Minimal system PATH that has bash/test/etc but not Homebrew binaries
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
}

@test "skips brew when swiftlint already installed" {
    # swiftlint stub is present in STUBS — appears installed
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}

@test "calls brew install when swiftlint absent" {
    # TMPBIN has brew but NOT swiftlint; system path excluded to prevent real swiftlint
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cp "${STUBS}/brew" "${TMPBIN}/brew"
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install swiftlint" "${STUB_CALL_LOG}"
}

@test "outputs version when swiftlint found" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"SwiftLint"* ]]
}
