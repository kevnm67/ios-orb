#!/usr/bin/env bats
# Tests for src/scripts/spm_build.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/spm_build.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "builds debug by default" {
    unset CONFIGURATION BUILD_FLAGS
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swift build -c debug$" "${STUB_CALL_LOG}"
}

@test "passes configuration and splits extra build flags" {
    export CONFIGURATION=release BUILD_FLAGS="-Xswiftc -warnings-as-errors"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swift build -c release -Xswiftc -warnings-as-errors$" "${STUB_CALL_LOG}"
}

@test "fails when swift build fails (pipefail)" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${TMPBIN}/swift"
    chmod +x "${TMPBIN}/swift"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}
