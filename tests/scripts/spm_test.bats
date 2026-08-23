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
    export TEST_FRAMEWORK=xctest
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^swift test --enable-code-coverage --parallel$" "${STUB_CALL_LOG}"
    grep -q "^xcbeautify --report junit --report-path build/reports$" "${STUB_CALL_LOG}"
}

@test "disables coverage and parallel when false" {
    export COVERAGE=false PARALLEL=false TEST_FRAMEWORK=xctest
    run bash "${SCRIPT}"
    grep -q "^swift test$" "${STUB_CALL_LOG}"
}

@test "accepts 1 as true and adds filter" {
    export COVERAGE=1 PARALLEL=0 FILTER="MyTests/testFoo" REPORT_PATH=out TEST_FRAMEWORK=xctest
    run bash "${SCRIPT}"
    grep -q "^swift test --enable-code-coverage --filter MyTests/testFoo$" "${STUB_CALL_LOG}"
    grep -q -- "--report-path out$" "${STUB_CALL_LOG}"
}

@test "forced framework=swift-testing adds --parallel and --xunit-output, no xcbeautify junit report" {
    export TEST_FRAMEWORK=swift-testing REPORT_PATH="${BATS_TMPDIR}/reports_${BATS_TEST_NUMBER}"
    unset COVERAGE PARALLEL FILTER
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "--parallel" "${STUB_CALL_LOG}"
    grep -q -- "--xunit-output ${REPORT_PATH}/junit.xml" "${STUB_CALL_LOG}"
    ! grep -q -- "--report junit" "${STUB_CALL_LOG}"
    grep -q "^xcbeautify $" "${STUB_CALL_LOG}"
}

@test "framework=swift-testing warns and still forces --parallel when parallel=false was requested" {
    export TEST_FRAMEWORK=swift-testing PARALLEL=false REPORT_PATH="${BATS_TMPDIR}/reports_${BATS_TEST_NUMBER}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"requires --parallel"* ]]
    grep -q -- "--parallel" "${STUB_CALL_LOG}"
}

@test "framework=xctest keeps the existing xcbeautify junit report path" {
    export TEST_FRAMEWORK=xctest REPORT_PATH=out
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcbeautify --report junit --report-path out$" "${STUB_CALL_LOG}"
    result=$(grep "^swift test" "${STUB_CALL_LOG}")
    [[ "${result}" != *"--xunit-output"* ]]
}

@test "auto-detects swift-testing when Tests/ imports Testing" {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/spm_auto_pos.XXXXXX")"
    mkdir -p "${TEST_ROOT}/Tests/FooTests"
    printf 'import Testing\n@Test func foo() {}\n' > "${TEST_ROOT}/Tests/FooTests/FooTests.swift"
    unset TEST_FRAMEWORK COVERAGE PARALLEL FILTER
    export REPORT_PATH="${BATS_TMPDIR}/reports_${BATS_TEST_NUMBER}"
    run bash -c "cd '${TEST_ROOT}' && bash '${SCRIPT}'"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"framework: swift-testing"* ]]
}

@test "auto-detects xctest when Tests/ does not import Testing" {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/spm_auto_neg.XXXXXX")"
    mkdir -p "${TEST_ROOT}/Tests/FooTests"
    printf 'import XCTest\nclass FooTests: XCTestCase {}\n' > "${TEST_ROOT}/Tests/FooTests/FooTests.swift"
    unset TEST_FRAMEWORK COVERAGE PARALLEL FILTER
    export REPORT_PATH="${BATS_TMPDIR}/reports_${BATS_TEST_NUMBER}"
    run bash -c "cd '${TEST_ROOT}' && bash '${SCRIPT}'"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"framework: xctest"* ]]
}

@test "auto-detects xctest when Tests/ is missing" {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/spm_auto_missing.XXXXXX")"
    unset TEST_FRAMEWORK COVERAGE PARALLEL FILTER
    export REPORT_PATH="${BATS_TMPDIR}/reports_${BATS_TEST_NUMBER}"
    run bash -c "cd '${TEST_ROOT}' && bash '${SCRIPT}'"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"framework: xctest"* ]]
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
