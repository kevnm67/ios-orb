#!/usr/bin/env bats
# Tests for src/scripts/verify_rbenv.sh
# Note: script has no set -euo pipefail; it uses || fallbacks.
# It runs ruby -v; if that fails tries rbenv local; then ruby -v + which ruby.

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/verify_rbenv.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
}

@test "succeeds when ruby is available" {
    export PATH="${STUBS}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "outputs ruby version info" {
    export PATH="${STUBS}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"ruby"* ]]
}

@test "falls back to rbenv local when ruby not in PATH" {
    # Use tmpbin with rbenv but not ruby initially
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cp "${STUBS}/rbenv" "${TMPBIN}/rbenv"
    chmod +x "${TMPBIN}/rbenv"
    # Create a ruby stub that fails on first call (simulating not found),
    # succeeds on subsequent calls after rbenv local sets it up
    CALL_COUNT_FILE="${BATS_TMPDIR}/ruby_calls_${BATS_TEST_NUMBER}"
    echo "0" > "${CALL_COUNT_FILE}"
    cat > "${TMPBIN}/ruby" << RUBYSTUB
#!/usr/bin/env bash
COUNT=\$(cat "${CALL_COUNT_FILE}")
COUNT=\$((COUNT+1))
echo "\$COUNT" > "${CALL_COUNT_FILE}"
if [ "\$COUNT" -eq 1 ]; then
    exit 1
fi
echo "ruby 3.2.0 (stub)"
RUBYSTUB
    chmod +x "${TMPBIN}/ruby"
    export PATH="${TMPBIN}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^rbenv" "${STUB_CALL_LOG}"
}
