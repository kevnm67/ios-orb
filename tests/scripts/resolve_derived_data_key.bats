#!/usr/bin/env bats
# Tests for src/scripts/resolve_derived_data_key.sh
# The script must always produce DerivedData.cache-key so that
# {{ checksum }} never fails, preferring project.yml, then
# <XCODE_PROJECT>.xcodeproj/project.pbxproj, then an empty file.

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/resolve_derived_data_key.sh"

setup() {
    WORK_DIR="${BATS_TMPDIR}/ddkey_${BATS_TEST_NUMBER}"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
}

@test "uses project.yml when present" {
    echo "xcodegen-spec" > project.yml
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"project.yml"* ]]
    [ "$(cat DerivedData.cache-key)" = "xcodegen-spec" ]
}

@test "falls back to xcodeproj/project.pbxproj when project.yml is absent" {
    mkdir -p "MyApp.xcodeproj"
    echo "pbxproj-content" > "MyApp.xcodeproj/project.pbxproj"
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"MyApp.xcodeproj/project.pbxproj"* ]]
    [ "$(cat DerivedData.cache-key)" = "pbxproj-content" ]
}

@test "prefers project.yml over project.pbxproj when both exist" {
    echo "xcodegen-spec" > project.yml
    mkdir -p "MyApp.xcodeproj"
    echo "pbxproj-content" > "MyApp.xcodeproj/project.pbxproj"
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"project.yml"* ]]
    [ "$(cat DerivedData.cache-key)" = "xcodegen-spec" ]
}

@test "falls back to empty key when XCODE_PROJECT is unset and project.yml is absent" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No project.yml or project.pbxproj found"* ]]
    [ -f DerivedData.cache-key ]
    [ ! -s DerivedData.cache-key ]
}

@test "falls back to empty key when XCODE_PROJECT set but pbxproj missing" {
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No project.yml or project.pbxproj found"* ]]
    [ -f DerivedData.cache-key ]
    [ ! -s DerivedData.cache-key ]
}

@test "key file content matches source so existing cache checksums stay valid" {
    mkdir -p "MyApp.xcodeproj"
    printf 'pin-content\nline2\n' > "MyApp.xcodeproj/project.pbxproj"
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    cmp -s "MyApp.xcodeproj/project.pbxproj" DerivedData.cache-key
}
