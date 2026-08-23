#!/usr/bin/env bats
# Tests for src/scripts/deploy_testflight.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/deploy_testflight.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"

    unset LANE IPA_PATH APP_IDENTIFIER API_KEY_PATH_VAR TESTFLIGHT_GROUPS CHANGELOG
    unset ASC_API_KEY_PATH
    export SKIP_WAITING="true"
}

@test "runs the given lane and ignores every other parameter" {
    export LANE="beta"
    export IPA_PATH="build/MyApp.ipa"
    export TESTFLIGHT_GROUPS="Internal Testers"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane beta$" "${STUB_CALL_LOG}"
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"upload_to_testflight"* ]]
}

@test "default invocation runs upload_to_testflight with skip_waiting_for_build_processing:true" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane run upload_to_testflight skip_waiting_for_build_processing:true$" "${STUB_CALL_LOG}"
}

@test "adds ipa: when ipa_path is set" {
    export IPA_PATH="build/MyApp.ipa"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "ipa:build/MyApp.ipa" "${STUB_CALL_LOG}"
}

@test "omits ipa: when ipa_path is empty" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"ipa:"* ]]
}

@test "adds app_identifier: when set" {
    export APP_IDENTIFIER="com.example.app"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "app_identifier:com.example.app" "${STUB_CALL_LOG}"
}

@test "omits app_identifier: when empty" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"app_identifier:"* ]]
}

@test "resolves api_key_path via indirect env var" {
    export API_KEY_PATH_VAR="ASC_API_KEY_PATH"
    export ASC_API_KEY_PATH="/keys/asc_key.json"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "api_key_path:/keys/asc_key.json" "${STUB_CALL_LOG}"
}

@test "omits api_key_path: when the named env var is unset" {
    export API_KEY_PATH_VAR="ASC_API_KEY_PATH"
    unset ASC_API_KEY_PATH
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"api_key_path:"* ]]
}

@test "adds skip_waiting_for_build_processing:false when skip_waiting is false" {
    export SKIP_WAITING="false"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "skip_waiting_for_build_processing:false" "${STUB_CALL_LOG}"
}

@test "adds groups: when set" {
    export TESTFLIGHT_GROUPS="Internal Testers,QA"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "groups:Internal Testers,QA" "${STUB_CALL_LOG}"
}

@test "omits groups: when empty" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"groups:"* ]]
}

@test "adds changelog: when set" {
    export CHANGELOG="Bug fixes and performance improvements"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "changelog:Bug fixes and performance improvements" "${STUB_CALL_LOG}"
}

@test "omits changelog: when empty" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"changelog:"* ]]
}

@test "combines every parameter into one invocation" {
    export IPA_PATH="build/MyApp.ipa"
    export APP_IDENTIFIER="com.example.app"
    export API_KEY_PATH_VAR="ASC_API_KEY_PATH"
    export ASC_API_KEY_PATH="/keys/asc_key.json"
    export SKIP_WAITING="true"
    export TESTFLIGHT_GROUPS="Internal Testers,QA"
    export CHANGELOG="Bug fixes"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane run upload_to_testflight ipa:build/MyApp.ipa app_identifier:com.example.app api_key_path:/keys/asc_key.json skip_waiting_for_build_processing:true groups:Internal Testers,QA changelog:Bug fixes$" "${STUB_CALL_LOG}"
}
