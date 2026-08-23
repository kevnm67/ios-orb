#!/usr/bin/env bats
# Tests for src/scripts/xcodebuild_test.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/xcodebuild_test.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "tests with coverage and result bundle" {
    export SCHEME=MyApp DESTINATION="platform=iOS Simulator,name=iPhone 17" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/R.xcresult" PROJECT=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodebuild test -scheme MyApp -destination platform=iOS Simulator,name=iPhone 17 -enableCodeCoverage YES -resultBundlePath ${RESULT_BUNDLE_PATH}$" "${STUB_CALL_LOG}"
    grep -q "^xcbeautify --report junit --junit-report-filename test-results.xml" "${STUB_CALL_LOG}"
}

@test "removes stale result bundle before running" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/stale_${BATS_TEST_NUMBER}.xcresult"
    mkdir -p "${RESULT_BUNDLE_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ ! -d "${RESULT_BUNDLE_PATH}" ]
}

@test "adds -project and honours JUNIT_REPORT" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH=R.xcresult PROJECT=App.xcodeproj JUNIT_REPORT=out/j.xml
    run bash "${SCRIPT}"
    grep -q -- "-project App.xcodeproj" "${STUB_CALL_LOG}"
    grep -q -- "--junit-report-filename out/j.xml" "${STUB_CALL_LOG}"
}

@test "does not add retry flags by default" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/r2_${BATS_TEST_NUMBER}.xcresult"
    unset RETRY_ON_FAILURE TEST_ITERATIONS
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^xcodebuild" "${STUB_CALL_LOG}")
    [[ "${result}" != *"-retry-tests-on-failure"* ]]
}

@test "adds retry flags when RETRY_ON_FAILURE is true" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/r3_${BATS_TEST_NUMBER}.xcresult"
    export RETRY_ON_FAILURE=true TEST_ITERATIONS=5
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-retry-tests-on-failure -test-iterations 5" "${STUB_CALL_LOG}"
}

@test "adds retry flags with default iterations when RETRY_ON_FAILURE=1" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/r4_${BATS_TEST_NUMBER}.xcresult"
    export RETRY_ON_FAILURE=1
    unset TEST_ITERATIONS
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-retry-tests-on-failure -test-iterations 3" "${STUB_CALL_LOG}"
}

@test "fails when xcodebuild fails (pipefail)" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 65\n' > "${TMPBIN}/xcodebuild"
    chmod +x "${TMPBIN}/xcodebuild"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH=R.xcresult
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}

@test "TEST_SPLITS_FILE adds one -only-testing flag per line, scoped to TEST_TARGET" {
    SPLITS_FILE="${BATS_TMPDIR}/splits_${BATS_TEST_NUMBER}.txt"
    printf 'FooTests\nBarTests\n' > "${SPLITS_FILE}"
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/split_${BATS_TEST_NUMBER}.xcresult"
    export TEST_SPLITS_FILE="${SPLITS_FILE}" TEST_TARGET=MyAppTests
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-only-testing:MyAppTests/FooTests -only-testing:MyAppTests/BarTests" "${STUB_CALL_LOG}"
}

@test "TEST_SPLITS_FILE defaults TEST_TARGET to SCHEME when unset" {
    SPLITS_FILE="${BATS_TMPDIR}/splits_${BATS_TEST_NUMBER}.txt"
    printf 'FooTests\n' > "${SPLITS_FILE}"
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/split2_${BATS_TEST_NUMBER}.xcresult"
    export TEST_SPLITS_FILE="${SPLITS_FILE}"
    unset TEST_TARGET
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-only-testing:MyApp/FooTests" "${STUB_CALL_LOG}"
}

@test "empty TEST_SPLITS_FILE adds no -only-testing flags" {
    SPLITS_FILE="${BATS_TMPDIR}/empty_${BATS_TEST_NUMBER}.txt"
    : > "${SPLITS_FILE}"
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/split3_${BATS_TEST_NUMBER}.xcresult"
    export TEST_SPLITS_FILE="${SPLITS_FILE}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^xcodebuild" "${STUB_CALL_LOG}")
    [[ "${result}" != *"-only-testing"* ]]
}

@test "unset TEST_SPLITS_FILE adds no -only-testing flags" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/split4_${BATS_TEST_NUMBER}.xcresult"
    unset TEST_SPLITS_FILE
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^xcodebuild" "${STUB_CALL_LOG}")
    [[ "${result}" != *"-only-testing"* ]]
}

@test "JUNIT_SOURCE=xcresultparser pipes through plain xcbeautify and runs xcresultparser" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/xrp_${BATS_TEST_NUMBER}.xcresult"
    export JUNIT_SOURCE=xcresultparser JUNIT_REPORT="${BATS_TMPDIR}/xrp_${BATS_TEST_NUMBER}.xml"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcbeautify $" "${STUB_CALL_LOG}"
    grep -q -- "^xcresultparser --output-format junit ${RESULT_BUNDLE_PATH}$" "${STUB_CALL_LOG}"
    ! grep -q -- "--report junit" "${STUB_CALL_LOG}"
    [ -f "${JUNIT_REPORT}" ]
}

@test "JUNIT_SOURCE=xcresultparser installs xcresultparser via brew when missing" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    for bin in xcodebuild xcbeautify brew; do
        cp "${STUBS}/${bin}" "${TMPBIN}/${bin}"
    done
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/xrp2_${BATS_TEST_NUMBER}.xcresult"
    export JUNIT_SOURCE=xcresultparser JUNIT_REPORT="${BATS_TMPDIR}/xrp2_${BATS_TEST_NUMBER}.xml"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    grep -q "^brew install a7ex/homebrew-formulae/xcresultparser$" "${STUB_CALL_LOG}"
}

@test "default JUNIT_SOURCE=xcbeautify does not call xcresultparser" {
    export SCHEME=MyApp DESTINATION="platform=macOS" RESULT_BUNDLE_PATH="${BATS_TMPDIR}/xrp3_${BATS_TEST_NUMBER}.xcresult"
    unset JUNIT_SOURCE
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    ! grep -q "^xcresultparser" "${STUB_CALL_LOG}"
}
