#!/usr/bin/env bats
# Tests for scripts/ci/check-readme-params.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/ci/check-readme-params.sh"

setup() {
    REPO="$(mktemp -d "${BATS_TMPDIR}/crp_repo.XXXXXX")"
    mkdir -p "${REPO}/src/commands" "${REPO}/src/jobs"

    # A fully isolated PATH containing only what the script needs, with NO
    # yq — used by the tests that must exercise the awk fallback
    # deterministically regardless of whether yq happens to be installed
    # on the machine running the suite (it is not guaranteed on cimg/base).
    NO_YQ_BIN="$(mktemp -d "${BATS_TMPDIR}/crp_noyq.XXXXXX")"
    for bin in bash grep awk basename dirname cat sed mktemp; do
        ln -sf "$(command -v "${bin}")" "${NO_YQ_BIN}/${bin}"
    done
}

teardown() {
    rm -rf "${REPO}" "${NO_YQ_BIN}"
}

write_command_yml() {
    cat > "${REPO}/src/commands/widget.yml" << 'EOF'
---
description: Do widget things.

parameters:
    strict:
        description: Strict mode.
        type: boolean
        default: false
    label:
        description: A label.
        type: string
        default: ''

steps: []
EOF
}

run_script_in_repo() {
    REPO_ROOT="${REPO}" bash "${SCRIPT}"
}

run_script_in_repo_no_yq() {
    REPO_ROOT="${REPO}" PATH="${NO_YQ_BIN}" bash "${SCRIPT}"
}

@test "exits 0 and reports all documented when every param has a row in both READMEs" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"All parameters documented in both README.md and src/README.md."* ]]
}

@test "exits 1 and lists a parameter missing from README.md" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"widget.strict"* ]]
    [[ "${output}" == *"missing"*"README.md"* ]]
}

@test "exits 1 and lists a parameter missing from src/README.md" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"widget.label"* ]]
    [[ "${output}" == *"src/README.md"* ]]
}

@test "checks parameters declared on jobs as well as commands" {
    cat > "${REPO}/src/jobs/build.yml" << 'EOF'
---
description: Build the thing.

parameters:
    resource_class:
        description: Resource class.
        type: string
        default: m4pro.medium

steps: []
EOF
    printf 'no rows here\n' > "${REPO}/README.md"
    printf 'no rows here\n' > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"build.resource_class"* ]]
}

@test "no misses reported when there are no command/job yml files" {
    rm -rf "${REPO}/src/commands" "${REPO}/src/jobs"
    mkdir -p "${REPO}/src/commands" "${REPO}/src/jobs"
    : > "${REPO}/README.md"
    : > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Checked 0 parameter(s)"* ]]
}

@test "awk fallback (no yq on PATH): exits 0 when every param is documented" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo_no_yq
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Checked 2 parameter(s)"* ]]
    [[ "${output}" == *"All parameters documented in both README.md and src/README.md."* ]]
}

@test "awk fallback (no yq on PATH): lists the same misses as the yq path" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo_no_yq
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"widget.strict"* ]]
    [[ "${output}" == *"missing"*"README.md"* ]]
}

@test "awk fallback (no yq on PATH): stops the parameters block at the next top-level key" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo_no_yq
    [ "${status}" -eq 0 ]
    # steps: [] is a top-level key after parameters: — must not be scanned
    # as if it were another parameter.
    [[ "${output}" != *"widget.steps"* ]]
}

@test "does not require yq: works when yq is absent from PATH" {
    write_command_yml
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/README.md"
    printf '| Parameter |\n|---|\n| `strict` |\n| `label` |\n' > "${REPO}/src/README.md"

    run run_script_in_repo_no_yq
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"PyYAML"* ]]
    [[ "${output}" != *"yq"*"not found"* ]]
}
