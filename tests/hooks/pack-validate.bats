#!/usr/bin/env bats
# Tests for .claude/hooks/pack-validate.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/pack-validate.sh"

setup() {
    export CLAUDE_PROJECT_DIR
    CLAUDE_PROJECT_DIR="$(mktemp -d "${BATS_TMPDIR}/pv_project.XXXXXX")"
    mkdir -p "${CLAUDE_PROJECT_DIR}/src/commands"
    git init -q "${CLAUDE_PROJECT_DIR}"
    git -C "${CLAUDE_PROJECT_DIR}" config user.email "test@test.com"
    git -C "${CLAUDE_PROJECT_DIR}" config user.name "test"

    STUBBIN="$(mktemp -d "${BATS_TMPDIR}/pv_stubbin.XXXXXX")"
    # jq lives under Homebrew on macOS (not /usr/bin) — symlink it in so the
    # "circleci missing" test can drop Homebrew from PATH without losing jq.
    ln -sf "$(command -v jq)" "${STUBBIN}/jq"
    export PATH="${STUBBIN}:${PATH}"
}

teardown() {
    rm -rf "${CLAUDE_PROJECT_DIR}" "${STUBBIN}"
}

fake_circleci() {
    cat > "${STUBBIN}/circleci" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "${STUBBIN}/circleci"
}

@test "no-ops for a file outside watched src/ paths" {
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/scripts/foo.sh\"}}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "no-ops when tool_input has no file_path" {
    run bash "${SCRIPT}" <<< '{"tool_input": {}}'
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "exits 0 with a systemMessage when circleci CLI is missing" {
    # No circleci stub on PATH; keep system dirs for jq/rm/etc but drop
    # Homebrew (where a real circleci CLI may be installed on this machine).
    export PATH="${STUBBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/commands/swiftlint.yml\"}}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"circleci CLI not found"* ]]
}

@test "runs pack.sh and stamps the verification marker on success" {
    fake_circleci
    mkdir -p "${CLAUDE_PROJECT_DIR}/src"
    cat > "${CLAUDE_PROJECT_DIR}/src/pack.sh" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "${CLAUDE_PROJECT_DIR}/src/pack.sh"

    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/commands/swiftlint.yml\"}}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"validated"* ]]
    [ -f "${CLAUDE_PROJECT_DIR}/.git/.claude-verified" ]
}

@test "exits 2 with stderr when pack.sh fails" {
    fake_circleci
    mkdir -p "${CLAUDE_PROJECT_DIR}/src"
    cat > "${CLAUDE_PROJECT_DIR}/src/pack.sh" << 'EOF'
#!/usr/bin/env bash
echo "boom: invalid orb" >&2
exit 1
EOF
    chmod +x "${CLAUDE_PROJECT_DIR}/src/pack.sh"

    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/@orb.yml\"}}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"boom: invalid orb"* ]]
    [ ! -f "${CLAUDE_PROJECT_DIR}/.git/.claude-verified" ]
}

@test "matches src/@orb.yml and src/jobs/*.yml as well as src/commands" {
    fake_circleci
    mkdir -p "${CLAUDE_PROJECT_DIR}/src/jobs"
    cat > "${CLAUDE_PROJECT_DIR}/src/pack.sh" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "${CLAUDE_PROJECT_DIR}/src/pack.sh"

    run bash "${SCRIPT}" <<< "{\"tool_input\": {\"file_path\": \"${CLAUDE_PROJECT_DIR}/src/jobs/test.yml\"}}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"validated"* ]]
}
