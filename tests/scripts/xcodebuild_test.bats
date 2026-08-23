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
