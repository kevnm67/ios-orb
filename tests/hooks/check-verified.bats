#!/usr/bin/env bats
# Tests for .claude/hooks/check-verified.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/check-verified.sh"

setup() {
    ORIGIN="$(mktemp -d "${BATS_TMPDIR}/cv_origin.XXXXXX")"
    WORK="$(mktemp -d "${BATS_TMPDIR}/cv_work.XXXXXX")"
    rmdir "${WORK}"

    git init -q --bare "${ORIGIN}"
    git clone -q "${ORIGIN}" "${WORK}"
    git -C "${WORK}" config user.email "test@test.com"
    git -C "${WORK}" config user.name "test"

    mkdir -p "${WORK}/src/commands" "${WORK}/tests/scripts"
    echo "readme" > "${WORK}/README.md"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -q -m "init"
    git -C "${WORK}" branch -M main
    git -C "${WORK}" push -q -u origin main

    export CLAUDE_PROJECT_DIR="${WORK}"
}

teardown() {
    rm -rf "${ORIGIN}" "${WORK}"
}

@test "allows when no src/ or tests/ changes vs origin/main" {
    echo "more" >> "${WORK}/README.md"
    git -C "${WORK}" commit -qam "docs only"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}

@test "denies when src/ changed and no marker exists" {
    echo "params: {}" >> "${WORK}/src/commands/swiftlint.yml"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -qam "change src"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "deny"'* ]]
    [[ "${output}" == *"no verification marker"* ]]
}

@test "denies when marker is older than the latest src/ commit" {
    touch "${WORK}/.git/.claude-verified"
    sleep 1
    echo "params: {}" >> "${WORK}/src/commands/swiftlint.yml"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -qam "change src after marker"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "deny"'* ]]
    [[ "${output}" == *"newer than the last verified"* ]]
}

@test "allows when marker is newer than the latest src/ commit" {
    echo "params: {}" >> "${WORK}/src/commands/swiftlint.yml"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -qam "change src"
    sleep 1
    touch "${WORK}/.git/.claude-verified"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}

@test "allows when tests/ changed and marker is fresh" {
    echo "@test \"x\" { true; }" >> "${WORK}/tests/scripts/foo.bats"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -qam "change tests"
    sleep 1
    touch "${WORK}/.git/.claude-verified"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}

@test "allows when there is no origin/main baseline" {
    rm -rf "${WORK}/.git/refs/remotes"
    git -C "${WORK}" remote remove origin

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}
