#!/usr/bin/env bats
# Tests for .claude/hooks/pack-validate.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../.claude/hooks/pack-validate.sh"

setup() {
    # bats sources test functions in-process, so a PATH change inside a test
    # body persists into bats-exec-test's own post-test housekeeping (e.g.
    # its own `rm` of scratch files) — save the inherited PATH so teardown
    # can restore it before removing any directory a test's PATH pointed at.
    ORIGINAL_PATH="${PATH}"

    export CLAUDE_PROJECT_DIR
    CLAUDE_PROJECT_DIR="$(mktemp -d "${BATS_TMPDIR}/pv_project.XXXXXX")"
    mkdir -p "${CLAUDE_PROJECT_DIR}/src/commands"
    git init -q -b main "${CLAUDE_PROJECT_DIR}"
    git -C "${CLAUDE_PROJECT_DIR}" config user.email "test@test.com"
    git -C "${CLAUDE_PROJECT_DIR}" config user.name "test"

    STUBBIN="$(mktemp -d "${BATS_TMPDIR}/pv_stubbin.XXXXXX")"
    export PATH="${STUBBIN}:${PATH}"

    # A fully isolated PATH containing ONLY symlinks to the specific
    # binaries pack-validate.sh needs (bash for the pack.sh/circleci-stub
    # shebangs, plus the coreutils/git/jq it shells out to directly). Some
    # CI images (cimg/base) ship a real `circleci` CLI under /usr/bin, so
    # appending the inherited PATH — or even a generic /usr/bin:/bin — is
    # not safe for the "circleci missing" test; build an allowlist instead.
    ISOLATED_BIN="$(mktemp -d "${BATS_TMPDIR}/pv_isolated.XXXXXX")"
    for bin in bash jq git mktemp cat rm touch mkdir chmod; do
        ln -sf "$(command -v "${bin}")" "${ISOLATED_BIN}/${bin}"
    done
}

teardown() {
    export PATH="${ORIGINAL_PATH}"
    rm -rf "${CLAUDE_PROJECT_DIR}" "${STUBBIN}" "${ISOLATED_BIN}"
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
    # Fully isolated PATH — no circleci stub here, and no inherited system
    # dirs that might carry a real circleci CLI on this CI image.
    export PATH="${ISOLATED_BIN}"
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
