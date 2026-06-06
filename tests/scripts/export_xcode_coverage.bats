#!/usr/bin/env bats
# Tests for src/scripts/export_xcode_coverage.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/export_xcode_coverage.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    unset RESULT_BUNDLE_PATH
    # Work in a temp dir so coverage.xml doesn't pollute repo
    WORK_DIR="${BATS_TMPDIR}/work_${BATS_TEST_NUMBER}"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
}

@test "exits 1 when result bundle not found" {
    export RESULT_BUNDLE_PATH="NonExistent.xcresult"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"not found"* ]]
}

@test "uses default bundle name TestResults.xcresult when env var unset" {
    # No bundle dir exists -> should fail with 'not found'
    unset RESULT_BUNDLE_PATH
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"TestResults.xcresult"* ]]
}

@test "calls xcresultparser when bundle exists and xcresultparser in PATH" {
    # Create a fake xcresult dir
    BUNDLE="${WORK_DIR}/TestResults.xcresult"
    mkdir -p "${BUNDLE}"
    export RESULT_BUNDLE_PATH="${BUNDLE}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^xcresultparser" "${STUB_CALL_LOG}"
}

@test "xcresultparser receives --output-format cobertura flag" {
    BUNDLE="${WORK_DIR}/TestResults.xcresult"
    mkdir -p "${BUNDLE}"
    export RESULT_BUNDLE_PATH="${BUNDLE}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "cobertura" "${STUB_CALL_LOG}"
}

@test "outputs coverage.xml message on success" {
    BUNDLE="${WORK_DIR}/TestResults.xcresult"
    mkdir -p "${BUNDLE}"
    export RESULT_BUNDLE_PATH="${BUNDLE}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"coverage.xml"* ]]
}

@test "installs xcresultparser via brew when absent" {
    # Use a brew stub that installs xcresultparser into TMPBIN so the subsequent
    # call to xcresultparser in the script succeeds. Isolate PATH so the real
    # Homebrew xcresultparser is invisible to `command -v`.
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    XCRESULTPARSER_STUB="${STUBS}/xcresultparser"
    STUB_CALL_LOG_REF="${STUB_CALL_LOG}"
    # brew stub: on `brew install ...`, copy xcresultparser stub into TMPBIN
    cat > "${TMPBIN}/brew" << BREWSTUB
#!/usr/bin/env bash
echo "brew \$*" >> "${STUB_CALL_LOG_REF}"
# Simulate brew installing xcresultparser by dropping stub into TMPBIN
cp "${XCRESULTPARSER_STUB}" "${TMPBIN}/xcresultparser"
chmod +x "${TMPBIN}/xcresultparser"
BREWSTUB
    chmod +x "${TMPBIN}/brew"
    BUNDLE="${WORK_DIR}/TestResults.xcresult"
    mkdir -p "${BUNDLE}"
    export RESULT_BUNDLE_PATH="${BUNDLE}"
    # Strict PATH: TMPBIN first, no Homebrew, so real xcresultparser absent initially
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^brew install" "${STUB_CALL_LOG}"
}
