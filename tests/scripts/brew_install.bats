#!/usr/bin/env bats
# Tests for src/scripts/brew_install.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/brew_install.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export BREW_FORMULA="swiftlint"
    unset BREW_REINSTALL
}

@test "installs the formula when not already installed" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cat > "${TMPBIN}/brew" << 'BREWSTUB'
#!/usr/bin/env bash
echo "brew $*" >> "${STUB_CALL_LOG:-/tmp/stub_calls.log}"
case "$*" in
    "list "*)
        exit 1
        ;;
    "install "*)
        echo "stub:brew install ok"
        ;;
    *)
        echo "stub:brew $*"
        ;;
esac
BREWSTUB
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install swiftlint$" "${STUB_CALL_LOG}"
    [[ "${output}" == *"Running: brew install swiftlint"* ]]
}

@test "skips install when the formula is already present" {
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cat > "${TMPBIN}/brew" << 'BREWSTUB'
#!/usr/bin/env bash
echo "brew $*" >> "${STUB_CALL_LOG:-/tmp/stub_calls.log}"
case "$*" in
    "list "*)
        exit 0
        ;;
    *)
        echo "stub:brew $*"
        ;;
esac
BREWSTUB
    chmod +x "${TMPBIN}/brew"
    export PATH="${TMPBIN}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already installed"* ]]
    ! grep -q "^brew install" "${STUB_CALL_LOG}"
}

@test "reinstalls when BREW_REINSTALL=true" {
    export PATH="${STUBS}:${PATH}"
    export BREW_REINSTALL="true"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew reinstall swiftlint$" "${STUB_CALL_LOG}"
    ! grep -q "^brew list" "${STUB_CALL_LOG}"
}

@test "reinstalls when BREW_REINSTALL=1" {
    export PATH="${STUBS}:${PATH}"
    export BREW_REINSTALL="1"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew reinstall swiftlint$" "${STUB_CALL_LOG}"
}

@test "does not reinstall when BREW_REINSTALL=false" {
    export PATH="${STUBS}:${PATH}"
    export BREW_REINSTALL="false"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    ! grep -q "^brew reinstall" "${STUB_CALL_LOG}"
}
