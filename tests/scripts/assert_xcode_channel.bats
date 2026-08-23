#!/usr/bin/env bats
# Tests for src/scripts/assert_xcode_channel.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/assert_xcode_channel.sh"

@test "'26.6' passes" {
    export XCODE_VERSION="26.6"
    unset ALLOW_BETA_XCODE
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"looks like a stable release"* ]]
}

@test "'26.4.1' passes" {
    export XCODE_VERSION="26.4.1"
    unset ALLOW_BETA_XCODE
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "'27A5228h' fails" {
    export XCODE_VERSION="27A5228h"
    unset ALLOW_BETA_XCODE
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}

@test "failure message mentions ALLOW_BETA_XCODE" {
    export XCODE_VERSION="27A5228h"
    unset ALLOW_BETA_XCODE
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"allow_beta_xcode"* ]]
}

@test "allow_beta_xcode=true passes a beta version" {
    export XCODE_VERSION="27A5228h"
    export ALLOW_BETA_XCODE="true"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "allow_beta_xcode=1 passes a beta version" {
    export XCODE_VERSION="27A5228h"
    export ALLOW_BETA_XCODE="1"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}
