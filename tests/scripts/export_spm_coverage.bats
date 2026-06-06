#!/usr/bin/env bats
# Tests for src/scripts/export_spm_coverage.sh
# Note: this script is non-fatal (exits 0 on missing data) so all error paths
# should still return 0 with a warning message.

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/export_spm_coverage.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    # Each test gets its own isolated root so profdata from one test
    # doesn't leak into another test's `find BUILD_DIR/../` search.
    TEST_ROOT="${BATS_TMPDIR}/t${BATS_TEST_NUMBER}"
    WORK_DIR="${TEST_ROOT}/work"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
}

@test "exits 0 with warning when swift --show-bin-path returns empty" {
    TMPBIN="${TEST_ROOT}/bin"
    mkdir -p "${TMPBIN}"
    cat > "${TMPBIN}/swift" << 'SWIFTSTUB'
#!/usr/bin/env bash
echo ""
SWIFTSTUB
    chmod +x "${TMPBIN}/swift"
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Could not determine build directory"* ]]
}

@test "exits 0 with warning when build dir given but no profdata" {
    TMPBIN="${TEST_ROOT}/bin"
    BUILD_DIR="${TEST_ROOT}/build"
    mkdir -p "${TMPBIN}" "${BUILD_DIR}"
    # No profdata anywhere under TEST_ROOT
    cat > "${TMPBIN}/swift" << SWIFTSTUB
#!/usr/bin/env bash
echo "${BUILD_DIR}"
SWIFTSTUB
    chmod +x "${TMPBIN}/swift"
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No profdata file found"* ]]
}

@test "exits 0 with warning when profdata found but no test binary" {
    TMPBIN="${TEST_ROOT}/bin"
    BUILD_DIR="${TEST_ROOT}/build"
    mkdir -p "${TMPBIN}" "${BUILD_DIR}"
    # Place profdata one level up from BUILD_DIR (i.e. in TEST_ROOT)
    touch "${BUILD_DIR}/../default.profdata"
    cat > "${TMPBIN}/swift" << SWIFTSTUB
#!/usr/bin/env bash
echo "${BUILD_DIR}"
SWIFTSTUB
    chmod +x "${TMPBIN}/swift"
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No test binary found"* ]]
}

@test "exports coverage when profdata and test binary present" {
    TMPBIN="${TEST_ROOT}/bin"
    BUILD_DIR="${TEST_ROOT}/build"
    mkdir -p "${TMPBIN}" "${BUILD_DIR}"
    # Create profdata
    touch "${BUILD_DIR}/../default.profdata"
    # Create a fake test executable
    FAKE_BIN="${BUILD_DIR}/MyTests"
    touch "${FAKE_BIN}"
    chmod +x "${FAKE_BIN}"
    cat > "${TMPBIN}/swift" << SWIFTSTUB
#!/usr/bin/env bash
echo "${BUILD_DIR}"
SWIFTSTUB
    chmod +x "${TMPBIN}/swift"
    # xcrun must output DA lines to stdout so the script can redirect to coverage.lcov
    cat > "${TMPBIN}/xcrun" << 'XSTUB'
#!/usr/bin/env bash
echo "xcrun $*" >> "${STUB_CALL_LOG:-/tmp/xcrun_stub.log}"
echo "DA:1,1"
echo "DA:2,0"
XSTUB
    chmod +x "${TMPBIN}/xcrun"
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Coverage exported"* ]]
}
