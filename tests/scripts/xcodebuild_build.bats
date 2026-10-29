#!/usr/bin/env bats
# Tests for src/scripts/xcodebuild_build.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/xcodebuild_build.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "builds with scheme, destination and configuration" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodebuild build -scheme MyApp -destination platform=macOS -configuration Debug$" "${STUB_CALL_LOG}"
}

@test "adds -project when PROJECT is set" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Release PROJECT="Foo/MyApp.xcodeproj"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-project Foo/MyApp.xcodeproj" "${STUB_CALL_LOG}"
    grep -q -- "-configuration Release" "${STUB_CALL_LOG}"
}

@test "pipes through xcbeautify" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug
    run bash "${SCRIPT}"
    grep -q "^xcbeautify" "${STUB_CALL_LOG}"
}

@test "fails when xcodebuild fails (pipefail)" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 65\n' > "${TMPBIN}/xcodebuild"
    chmod +x "${TMPBIN}/xcodebuild"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}

@test "STEP_TIMEOUT terminates a hung step with exit 124 and a clear message" {
    TMPBIN="${BATS_TMPDIR}/slow_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nsleep 30\n' > "${TMPBIN}/xcodebuild"
    chmod +x "${TMPBIN}/xcodebuild"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT=""
    export STEP_TIMEOUT=1
    start=$SECONDS
    run bash "${SCRIPT}"
    [ "${status}" -eq 124 ]
    [[ "${output}" == *"exceeded its 1s timeout"* ]]
    [ $((SECONDS - start)) -lt 15 ]
}

@test "STEP_TIMEOUT above the runtime does not change a successful run" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT=""
    export STEP_TIMEOUT=60
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"timeout"* ]]
}

@test "STEP_TIMEOUT preserves the failing exit status of the step" {
    TMPBIN="${BATS_TMPDIR}/fail_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 65\n' > "${TMPBIN}/xcodebuild"
    chmod +x "${TMPBIN}/xcodebuild"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT=""
    export STEP_TIMEOUT=60
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [ "${status}" -ne 124 ]
}

@test "appends XCARGS (word-split) after the configuration" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT=""
    export XCARGS="CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodebuild build -scheme MyApp -destination platform=macOS -configuration Debug CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO$" "${STUB_CALL_LOG}"
}

@test "empty XCARGS leaves the invocation unchanged" {
    export SCHEME=MyApp DESTINATION="platform=macOS" CONFIGURATION=Debug PROJECT="" XCARGS=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcodebuild build -scheme MyApp -destination platform=macOS -configuration Debug$" "${STUB_CALL_LOG}"
}
