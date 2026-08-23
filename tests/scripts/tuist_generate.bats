#!/usr/bin/env bats
# Tests for src/scripts/tuist_generate.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/tuist_generate.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export PATH="${STUBS}:${SYSTEM_PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    unset TUIST_PATH
}

@test "runs tuist generate --no-open with no path by default" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^tuist generate --no-open$" "${STUB_CALL_LOG}"
}

@test "adds --path when TUIST_PATH is set" {
    export TUIST_PATH="Sources/App"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^tuist generate --no-open --path Sources/App$" "${STUB_CALL_LOG}"
}

@test "output includes running line" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Running: tuist generate --no-open"* ]]
}

@test "fails when tuist fails" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${TMPBIN}/tuist"
    chmod +x "${TMPBIN}/tuist"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}
