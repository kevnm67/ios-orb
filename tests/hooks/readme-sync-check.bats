#!/usr/bin/env bats
# Tests for .claude/hooks/readme-sync-check.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/readme-sync-check.sh"

setup() {
    WORK="$(mktemp -d "${BATS_TMPDIR}/rsc_work.XXXXXX")"
    ORIGIN="$(mktemp -d "${BATS_TMPDIR}/rsc_origin.XXXXXX")"
    rmdir "${ORIGIN}"

    # Build WORK (with an explicit -b main) and commit BEFORE creating
    # ORIGIN as a bare clone of it — cloning an empty bare repo triggers
    # git's "You appear to have cloned an empty repository" warning and was
    # flaky on CI.
    git init -q -b main "${WORK}"
    git -C "${WORK}" config user.email "test@test.com"
    git -C "${WORK}" config user.name "test"

    mkdir -p "${WORK}/src/commands"
    echo "readme" > "${WORK}/README.md"
    echo "readme" > "${WORK}/src/README.md"
    echo "params: {}" > "${WORK}/src/commands/swiftlint.yml"
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

@test "no-ops when nothing changed" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "reminds when src/commands changed but README.md did not" {
    echo "strict: true" >> "${WORK}/src/commands/swiftlint.yml"
    git -C "${WORK}" commit -qam "add param"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"did not"* ]]
}

@test "stays quiet when src/commands and README.md both changed" {
    echo "strict: true" >> "${WORK}/src/commands/swiftlint.yml"
    echo "| \`strict\` |" >> "${WORK}/README.md"
    git -C "${WORK}" commit -qam "add param + docs"

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "reminds on uncommitted src/ changes too" {
    echo "strict: true" >> "${WORK}/src/commands/swiftlint.yml"
    # left uncommitted deliberately

    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"did not"* ]]
}
