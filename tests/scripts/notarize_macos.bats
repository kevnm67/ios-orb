#!/usr/bin/env bats
# Tests for src/scripts/notarize_macos.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/notarize_macos.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"

    APP_DIR="$(mktemp -d "${BATS_TMPDIR}/notarize_macos.XXXXXX")"
    export APP_PATH="${APP_DIR}/MyApp.app"
    mkdir -p "${APP_PATH}"

    export ASC_KEY_PATH="/keys/AuthKey.p8"
    export ASC_KEY_ID="ABC123"
    export ASC_ISSUER_ID="issuer-uuid"
    export API_KEY_PATH_VAR="ASC_KEY_PATH"
    export API_KEY_ID_VAR="ASC_KEY_ID"
    export API_ISSUER_ID_VAR="ASC_ISSUER_ID"
    unset STAPLE STUB_XCRUN_FAIL
}

@test "exits 1 when app bundle not found" {
    export APP_PATH="/nonexistent/MyApp.app"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"not found"* ]]
}

@test "zips the app bundle via ditto" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^ditto -c -k --keepParent ${APP_PATH} " "${STUB_CALL_LOG}"
}

@test "submits to notarytool with resolved credentials" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcrun notarytool submit .*--key /keys/AuthKey.p8 --key-id ABC123 --issuer issuer-uuid --wait$" "${STUB_CALL_LOG}"
}

@test "staples by default when STAPLE is unset" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcrun stapler staple ${APP_PATH}$" "${STUB_CALL_LOG}"
}

@test "staples when STAPLE=true" {
    export STAPLE=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcrun stapler staple ${APP_PATH}$" "${STUB_CALL_LOG}"
}

@test "does not staple when STAPLE=false" {
    export STAPLE=false
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"stapler"* ]]
}

@test "fails when notarytool submission fails" {
    export STUB_XCRUN_FAIL=1
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    result=$(cat "${STUB_CALL_LOG}")
    [[ "${result}" != *"stapler"* ]]
}

@test "outputs completion message on success" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Notarization complete"* ]]
}
