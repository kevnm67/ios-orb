#!/usr/bin/env bats
# Tests for src/scripts/spm_ssh_setup.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/spm_ssh_setup.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
}

@test "scans github and bitbucket hosts into known_hosts and removes id_rsa" {
    export HOME="${BATS_TMPDIR}/home_${BATS_TEST_NUMBER}"
    mkdir -p "${HOME}/.ssh"
    : > "${HOME}/.ssh/id_rsa"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ ! -f "${HOME}/.ssh/id_rsa" ]
    grep -q "^dig @8.8.8.8 github.com +short" "${STUB_CALL_LOG}"
    grep -q "^dig @8.8.8.8 bitbucket.org +short" "${STUB_CALL_LOG}"
    grep -q "^ssh-keyscan github.com,140.82.112.3" "${STUB_CALL_LOG}"
    grep -q "^ssh-keyscan bitbucket.org,140.82.112.3" "${STUB_CALL_LOG}"
    grep -q "^ssh-keyscan 140.82.112.3" "${STUB_CALL_LOG}"
}

@test "succeeds even when id_rsa is absent and keyscan fails" {
    export HOME="${BATS_TMPDIR}/home_${BATS_TEST_NUMBER}"
    mkdir -p "${HOME}/.ssh"
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    printf '#!/usr/bin/env bash\nexit 1\n' > "${TMPBIN}/ssh-keyscan"
    chmod +x "${TMPBIN}/ssh-keyscan"
    export PATH="${TMPBIN}:${STUBS}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}
