#!/usr/bin/env bats
# Tests for .claude/hooks/check-verified.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/check-verified.sh"

setup() {
    WORK="$(mktemp -d "${BATS_TMPDIR}/cv_work.XXXXXX")"
    ORIGIN="$(mktemp -d "${BATS_TMPDIR}/cv_origin.XXXXXX")"
    rmdir "${ORIGIN}"

    # Build WORK first (with an explicit -b main so this is deterministic
    # regardless of the runner's init.defaultBranch), commit, THEN create
    # ORIGIN as a bare clone of that non-empty repo. Cloning an empty bare
    # repo (init --bare, then commit, then push) triggers git's "You appear
    # to have cloned an empty repository" warning and was flaky on CI.
    git init -q -b main "${WORK}"
    git -C "${WORK}" config user.email "test@test.com"
    git -C "${WORK}" config user.name "test"

    mkdir -p "${WORK}/src/commands" "${WORK}/tests/scripts"
    echo "readme" > "${WORK}/README.md"
    git -C "${WORK}" add -A
    git -C "${WORK}" commit -q -m "init"

    git clone -q --bare "${WORK}" "${ORIGIN}"
    git -C "${WORK}" remote add origin "${ORIGIN}"
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
    git -C "${WORK}" remote remove origin

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}

@test "allows when origin exists but origin/main was never fetched" {
    # A remote configured but with no matching remote-tracking ref at all
    # (e.g. origin/main was pruned, or the remote's default branch differs).
    git -C "${WORK}" remote remove origin
    git -C "${WORK}" remote add origin "${ORIGIN}"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "allow"'* ]]
}
