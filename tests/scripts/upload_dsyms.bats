#!/usr/bin/env bats
# Tests for src/scripts/upload_dsyms.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/upload_dsyms.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${PATH}"
    export DSYM_PATH="."
    export SENTRY_ORG="my-org"
    export SENTRY_PROJECT="my-project"
    export MY_SENTRY_TOKEN="secret-token-123"
    export AUTH_TOKEN_VAR="MY_SENTRY_TOKEN"
    unset SKIP_ERRORS STUB_SENTRY_CLI_FAIL
}

@test "skips brew when sentry-cli already installed" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
}

@test "calls brew install getsentry/tools/sentry-cli when absent, then runs it" {
    # A test-local brew stub that "installs" the shared sentry-cli stub onto
    # PATH, modeling real Homebrew making the binary available post-install.
    TMPBIN="$(mktemp -d "${BATS_TMPDIR}/bin.XXXXXX")"
    cat > "${TMPBIN}/brew" <<BREW_STUB
#!/usr/bin/env bash
echo "brew \$*" >> "${STUB_CALL_LOG}"
if [[ "\$*" == "install getsentry/tools/sentry-cli" ]]; then
    cp "${STUBS}/sentry-cli" "${TMPBIN}/sentry-cli"
    chmod +x "${TMPBIN}/sentry-cli"
fi
BREW_STUB
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install getsentry/tools/sentry-cli$" "${STUB_CALL_LOG}"
}

@test "uploads with org, project, and dsym_path" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^sentry-cli debug-files upload --org my-org --project my-project \.$" "${STUB_CALL_LOG}"
}

@test "resolves the auth token via indirect expansion of AUTH_TOKEN_VAR" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^sentry-cli saw SENTRY_AUTH_TOKEN=secret-token-123$" "${STUB_CALL_LOG}"
}

@test "uses a custom dsym_path when set" {
    export DSYM_PATH="build/dSYMs"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^sentry-cli debug-files upload --org my-org --project my-project build/dSYMs$" "${STUB_CALL_LOG}"
}

@test "fails the step when upload fails and skip_errors is false" {
    export STUB_SENTRY_CLI_FAIL=1
    export SKIP_ERRORS=false
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Error: dSYM upload failed"* ]]
}

@test "does not fail the step when upload fails and skip_errors=true" {
    export STUB_SENTRY_CLI_FAIL=1
    export SKIP_ERRORS=true
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"skip_errors is enabled"* ]]
}

@test "does not fail the step when upload fails and skip_errors=1" {
    export STUB_SENTRY_CLI_FAIL=1
    export SKIP_ERRORS=1
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"skip_errors is enabled"* ]]
}
