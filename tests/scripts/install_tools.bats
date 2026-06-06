#!/usr/bin/env bats
# Tests for src/scripts/install_tools.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/install_tools.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
}

@test "reports already installed for tools present in PATH" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    # swiftlint and xcodegen are both in stubs/
    export TOOLS="swiftlint xcodegen"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}

@test "calls brew install for missing tool" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cp "${STUBS}/brew" "${TMPBIN}/brew"
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    export TOOLS="nonexistent_tool_xyz"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install nonexistent_tool_xyz" "${STUB_CALL_LOG}"
}

@test "handles multiple tools: present ones skip, absent ones install" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cp "${STUBS}/brew" "${TMPBIN}/brew"
    cp "${STUBS}/swiftlint" "${TMPBIN}/swiftlint"
    chmod +x "${TMPBIN}/brew" "${TMPBIN}/swiftlint"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    export TOOLS="swiftlint missing_tool_abc"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
    grep -q "^brew install missing_tool_abc" "${STUB_CALL_LOG}"
}

@test "TOOLS with a single tool that is present" {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    export TOOLS="brew"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}
