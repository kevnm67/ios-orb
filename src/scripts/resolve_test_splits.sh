#!/usr/bin/env bash
# Discover test unit names for an Xcode or SPM project and split them across
# CircleCI parallel test nodes via `circleci tests split`, writing the
# assigned slice to test-splits.txt and exporting TEST_SPLITS_FILE via
# $BASH_ENV so xcodebuild_test.sh / spm_test.sh (later steps in the job) can
# consume it without any extra wiring. Only useful when the job's
# `parallelism` is greater than 1 — with parallelism 1 every node gets the
# full unit list, which is a no-op.
#
# Falls back to writing the full discovered unit list (with a warning)
# instead of failing when the `circleci` CLI isn't on PATH, so local/non-CI
# runs still work.
#
# Env vars set by the orb command:
#   SPLIT_KIND       - "xcode" or "spm"
#   TEST_TARGETS_DIR - (spm) directory whose immediate subdirectories are
#                       treated as test target names (default: Tests)
#   TEST_CLASSES_DIR - (xcode) directory searched recursively for
#                       "*Tests.swift" files (default: .)
#   SPLIT_BY         - value passed to `circleci tests split --split-by`
#                       (default: name)
set -euo pipefail

SPLIT_KIND="${SPLIT_KIND:-spm}"
SPLIT_BY="${SPLIT_BY:-name}"
BASH_ENV="${BASH_ENV:-/dev/null}"
OUTPUT_FILE="test-splits.txt"

discover_spm() {
    local dir="${TEST_TARGETS_DIR:-Tests}"
    if [ -d "${dir}" ]; then
        find "${dir}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
    fi
}

discover_xcode() {
    local dir="${TEST_CLASSES_DIR:-.}"
    find "${dir}" -name '*Tests.swift' -exec basename {} .swift \; | sort
}

case "${SPLIT_KIND}" in
    xcode) UNITS="$(discover_xcode)" ;;
    spm) UNITS="$(discover_spm)" ;;
    *)
        echo "error: unknown SPLIT_KIND '${SPLIT_KIND}' (expected 'xcode' or 'spm')" >&2
        exit 1
        ;;
esac

if [ -z "${UNITS}" ]; then
    echo "warning: no test units discovered for split_kind=${SPLIT_KIND}; writing an empty test-splits.txt (test step runs unfiltered)." >&2
    : > "${OUTPUT_FILE}"
elif command -v circleci &> /dev/null; then
    printf '%s\n' "${UNITS}" | circleci tests split --split-by="${SPLIT_BY}" > "${OUTPUT_FILE}"
else
    echo "warning: circleci CLI not found; running the full discovered unit set on this node (no split)." >&2
    printf '%s\n' "${UNITS}" > "${OUTPUT_FILE}"
fi

echo "export TEST_SPLITS_FILE=\"${PWD}/${OUTPUT_FILE}\"" >> "${BASH_ENV}"

COUNT="$(wc -l < "${OUTPUT_FILE}" | tr -d ' ')"
echo "→ Resolved ${COUNT} test unit(s) for this node (split_kind=${SPLIT_KIND}, split_by=${SPLIT_BY})"
