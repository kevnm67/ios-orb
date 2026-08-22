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
