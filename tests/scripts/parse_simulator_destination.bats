#!/usr/bin/env bats
# Tests for src/scripts/parse_simulator_destination.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/parse_simulator_destination.sh"

setup() {
    TEST_ROOT="$(mktemp -d "${BATS_TMPDIR}/parse_simulator_destination.XXXXXX")"
    export BASH_ENV="${TEST_ROOT}/bash_env"
    : > "${BASH_ENV}"
}

@test "extracts an iPhone device name" {
    export DESTINATION="platform=iOS Simulator,name=iPhone 17"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q '^export SIMULATOR_DEVICE="iPhone 17"$' "${BASH_ENV}"
    [[ "${output}" == *"Parsed simulator device"*"iPhone 17"* ]]
}

@test "extracts an iPad device name that has a trailing OS field" {
    export DESTINATION="platform=iOS Simulator,name=iPad (A16),OS=18.0"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q '^export SIMULATOR_DEVICE="iPad (A16)"$' "${BASH_ENV}"
}

@test "no-ops for a non-simulator destination" {
    export DESTINATION="platform=macOS"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q '^export SIMULATOR_DEVICE=""$' "${BASH_ENV}"
    [[ "${output}" == *"No simulator device found"* ]]
}

@test "no-ops when DESTINATION is missing" {
    unset DESTINATION
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q '^export SIMULATOR_DEVICE=""$' "${BASH_ENV}"
}

@test "the exported line is safe to source (quoting)" {
    export DESTINATION="platform=iOS Simulator,name=iPad (A16),OS=18.0"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    # shellcheck disable=SC1090
    source "${BASH_ENV}"
    [ "${SIMULATOR_DEVICE}" = "iPad (A16)" ]
}
