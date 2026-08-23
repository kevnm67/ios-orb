#!/usr/bin/env bats
# Tests for src/scripts/check_cache_path.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/check_cache_path.sh"

setup() {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/check_cache_path.XXXXXX")"
}

@test "warns and exits 0 when CACHE_PATH is unset" {
    unset CACHE_PATH
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"no path configured"* ]]
}

@test "warns and exits 0 when the path does not exist" {
    export CACHE_PATH="${TEST_ROOT}/does-not-exist"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"does not exist yet"* ]]
    [[ "${output}" == *"path: .build"* ]]
}

@test "succeeds silently (aside from the caching line) when the path exists" {
    mkdir -p "${TEST_ROOT}/.build"
    export CACHE_PATH="${TEST_ROOT}/.build"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"caching ${TEST_ROOT}/.build"* ]]
    [[ "${output}" != *"does not exist"* ]]
}
