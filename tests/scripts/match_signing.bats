#!/usr/bin/env bats
# Tests for src/scripts/match_signing.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/match_signing.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    unset MATCH_APP_IDENTIFIER
    export MATCH_READONLY="false"
}

@test "runs bundle exec fastlane match adhoc" {
    export MATCH_TYPES="adhoc"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match adhoc$" "${STUB_CALL_LOG}"
}

@test "adds --readonly when MATCH_READONLY=true" {
    export MATCH_TYPES="appstore"
    export MATCH_READONLY="true"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match appstore --readonly$" "${STUB_CALL_LOG}"
}

@test "does not add --readonly when MATCH_READONLY=false" {
    export MATCH_TYPES="development"
    export MATCH_READONLY="false"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^bundle exec fastlane match development" "${STUB_CALL_LOG}")
    [[ "${result}" != *"--readonly"* ]]
}

@test "adds --app_identifier when MATCH_APP_IDENTIFIER is set" {
    export MATCH_TYPES="adhoc"
    export MATCH_APP_IDENTIFIER="com.example.app"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match adhoc --app_identifier com.example.app$" "${STUB_CALL_LOG}"
}

@test "does not add --app_identifier when MATCH_APP_IDENTIFIER is unset" {
    export MATCH_TYPES="adhoc"
    unset MATCH_APP_IDENTIFIER
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(grep "^bundle exec fastlane match adhoc" "${STUB_CALL_LOG}")
    [[ "${result}" != *"--app_identifier"* ]]
}

@test "iterates multiple comma-separated types" {
    export MATCH_TYPES="adhoc,appstore"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match adhoc$" "${STUB_CALL_LOG}"
    grep -q "^bundle exec fastlane match appstore$" "${STUB_CALL_LOG}"
}

@test "trims whitespace from types" {
    export MATCH_TYPES="adhoc, appstore"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match adhoc$" "${STUB_CALL_LOG}"
    grep -q "^bundle exec fastlane match appstore$" "${STUB_CALL_LOG}"
}

@test "combines readonly + app_identifier + multiple types" {
    export MATCH_TYPES="adhoc,appstore"
    export MATCH_READONLY="true"
    export MATCH_APP_IDENTIFIER="com.example.app"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^bundle exec fastlane match adhoc --readonly --app_identifier com.example.app$" "${STUB_CALL_LOG}"
    grep -q "^bundle exec fastlane match appstore --readonly --app_identifier com.example.app$" "${STUB_CALL_LOG}"
}
