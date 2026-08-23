#!/usr/bin/env bats
# Tests for .claude/hooks/block-packed-files.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/block-packed-files.sh"

setup() {
    export CLAUDE_PROJECT_DIR
    CLAUDE_PROJECT_DIR="$(mktemp -d "${BATS_TMPDIR}/bpf_project.XXXXXX")"
    mkdir -p "${CLAUDE_PROJECT_DIR}/src"
}

teardown() {
    rm -rf "${CLAUDE_PROJECT_DIR}"
}

@test "denies edits to src/ios.yml (absolute path)" {
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/ios.yml\"}}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "deny"'* ]]
    [[ "${output}" == *"src/ios.yml"* ]]
}

@test "denies edits to root orb.yml (absolute path)" {
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/orb.yml\"}}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "deny"'* ]]
    [[ "${output}" == *"orb.yml"* ]]
}

@test "denies edits given a bare relative path" {
    run bash "${SCRIPT}" <<< '{"tool_input": {"file_path": "src/ios.yml"}}'
    [ "${status}" -eq 0 ]
    [[ "${output}" == *'"permissionDecision": "deny"'* ]]
}

@test "allows edits to unpacked source files" {
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/commands/swiftlint.yml\"}}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows edits to a same-named file in an unrelated directory" {
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/docs/orb.yml\"}}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "no-ops when tool_input has no file_path" {
    run bash "${SCRIPT}" <<< '{"tool_input": {}}'
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
