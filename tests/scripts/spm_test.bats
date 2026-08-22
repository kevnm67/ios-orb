#!/usr/bin/env bats
# Tests for src/scripts/spm_test.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/spm_test.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "defaults to coverage + parallel with junit report" {
    unset COVERAGE PARALLEL FILTER REPORT_PATH
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swift test --enable-code-coverage --parallel$" "${STUB_CALL_LOG}"
    grep -q "^xcbeautify --report junit --report-path build/reports$" "${STUB_CALL_LOG}"
}

@test "disables coverage and parallel when false" {
    export COVERAGE=false PARALLEL=false
    run bash "${SCRIPT}"
    grep -q "^swift test$" "${STUB_CALL_LOG}"
}

@test "accepts 1 as true and adds filter" {
    export COVERAGE=1 PARALLEL=0 FILTER="MyTests/testFoo" REPORT_PATH=out
    run bash "${SCRIPT}"
    grep -q "^swift test --enable-code-coverage --filter MyTests/testFoo$" "${STUB_CALL_LOG}"
    grep -q -- "--report-path out$" "${STUB_CALL_LOG}"
}

@test "fails when swift test fails (pipefail)" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${TMPBIN}/swift"
    chmod +x "${TMPBIN}/swift"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}
