#!/usr/bin/env bats
# Tests for scripts/ci/check-readme-params.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/ci/check-readme-params.sh"

setup() {
    REPO="$(mktemp -d "${BATS_TMPDIR}/crp_repo.XXXXXX")"
    mkdir -p "${REPO}/src/commands" "${REPO}/src/jobs"
}

teardown() {
    rm -rf "${REPO}"
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

steps:
    - run:
          name: Widget
          command: echo widget
EOF
}

run_script_in_repo() {
    REPO_ROOT="${REPO}" bash "${SCRIPT}"
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

steps:
    - run:
          name: Build
          command: echo build
EOF
    printf 'no rows here\n' > "${REPO}/README.md"
    printf 'no rows here\n' > "${REPO}/src/README.md"

    run run_script_in_repo
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"build.resource_class"* ]]
}

@test "guards on PyYAML availability before parsing" {
    # PyYAML is installed system-wide in this environment, so the failure
    # path can't be exercised live without root; assert the guard exists.
    grep -q 'import yaml' "${SCRIPT}"
    grep -q 'PyYAML not found' "${SCRIPT}"
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
