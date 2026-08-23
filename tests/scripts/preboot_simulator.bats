#!/usr/bin/env bats
# Tests for src/scripts/preboot_simulator.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/preboot_simulator.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "no-ops when SIMULATOR_DEVICE is unset" {
    unset SIMULATOR_DEVICE
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No simulator device to preboot"* ]]
    [ ! -f "${STUB_CALL_LOG}" ]
}

@test "no-ops when SIMULATOR_DEVICE is empty" {
    export SIMULATOR_DEVICE=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No simulator device to preboot"* ]]
    [ ! -f "${STUB_CALL_LOG}" ]
}

@test "boots the simulator when SIMULATOR_DEVICE is set" {
    export SIMULATOR_DEVICE="iPhone 17"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcrun simctl boot iPhone 17$" "${STUB_CALL_LOG}"
    [[ "${output}" == *"Prebooting simulator: iPhone 17"* ]]
}

@test "tolerates an already-booted simulator" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\necho "xcrun $*" >> "%s"\nexit 149\n' "${STUB_CALL_LOG}" > "${TMPBIN}/xcrun"
    chmod +x "${TMPBIN}/xcrun"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    export SIMULATOR_DEVICE="iPhone 17"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}
