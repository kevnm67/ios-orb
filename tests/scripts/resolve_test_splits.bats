#!/usr/bin/env bats
# Tests for src/scripts/resolve_test_splits.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/resolve_test_splits.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    export PATH="${STUBS}:${SYSTEM_PATH}"
    export BASH_ENV="${BATS_TMPDIR}/bash_env_${BATS_TEST_NUMBER}"
    : > "${BASH_ENV}"
    WORK_DIR="${BATS_TMPDIR}/splits_${BATS_TEST_NUMBER}"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
}

@test "spm mode discovers Tests/ subdirectory names and splits via circleci CLI" {
    mkdir -p Tests/FooTests Tests/BarTests
    export SPLIT_KIND=spm
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ "$(cat test-splits.txt)" = "$(printf 'BarTests\nFooTests')" ]
    grep -q "^circleci tests split --split-by=name$" "${STUB_CALL_LOG}"
    grep -q '^export TEST_SPLITS_FILE=' "${BASH_ENV}"
}

@test "spm mode honours a custom TEST_TARGETS_DIR" {
    mkdir -p UnitTests/ATests UnitTests/BTests
    export SPLIT_KIND=spm TEST_TARGETS_DIR=UnitTests
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ "$(cat test-splits.txt)" = "$(printf 'ATests\nBTests')" ]
}

@test "spm mode with no Tests/ directory writes an empty split file" {
    export SPLIT_KIND=spm
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"no test units discovered"* ]]
    [ -f test-splits.txt ]
    [ ! -s test-splits.txt ]
    ! grep -q "^circleci" "${STUB_CALL_LOG}"
}

@test "xcode mode discovers *Tests.swift class names via basename" {
    mkdir -p Sources
    printf 'class FooTests {}\n' > Sources/FooTests.swift
    printf 'class BarTests {}\n' > Sources/BarTests.swift
    printf 'class NotATest {}\n' > Sources/Helper.swift
    export SPLIT_KIND=xcode
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ "$(cat test-splits.txt)" = "$(printf 'BarTests\nFooTests')" ]
    grep -q "^circleci tests split --split-by=name$" "${STUB_CALL_LOG}"
}

@test "xcode mode honours a custom TEST_CLASSES_DIR and SPLIT_BY" {
    mkdir -p Nested/Deep
    printf 'class FooTests {}\n' > Nested/Deep/FooTests.swift
    export SPLIT_KIND=xcode TEST_CLASSES_DIR=Nested SPLIT_BY=timings
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ "$(cat test-splits.txt)" = "FooTests" ]
    grep -q "^circleci tests split --split-by=timings$" "${STUB_CALL_LOG}"
}

@test "falls back to the full unit list with a warning when circleci CLI is absent" {
    mkdir -p Tests/FooTests Tests/BarTests
    export SPLIT_KIND=spm
    # cimg/base ships a real `circleci` inside the system paths, so PATH
    # exclusion is not enough — build an isolated PATH holding only the
    # binaries the script needs (same pattern as pack-validate.bats).
    TMPBIN="$(mktemp -d "${BATS_TMPDIR}/nocli.XXXXXX")"
    for b in bash find sort sed cat dirname mkdir grep basename tr wc; do
        src="$(command -v "$b" 2>/dev/null)" || continue
        ln -s "$src" "${TMPBIN}/$b"
    done
    export PATH="${TMPBIN}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"circleci CLI not found"* ]]
    [ "$(cat test-splits.txt)" = "$(printf 'BarTests\nFooTests')" ]
}

@test "rejects an unknown SPLIT_KIND" {
    export SPLIT_KIND=bogus
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"unknown SPLIT_KIND"* ]]
}

@test "defaults SPLIT_KIND to spm when unset" {
    mkdir -p Tests/FooTests
    unset SPLIT_KIND
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [ "$(cat test-splits.txt)" = "FooTests" ]
}
