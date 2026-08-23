#!/usr/bin/env bash
# .claude/hooks/readme-sync-check.sh
#
# Stop hook (advisory only — never blocks): when src/commands, src/jobs, or
# src/executors changed (committed vs origin/main, or still uncommitted) but
# neither README.md nor src/README.md changed in the same diff, emits a
# systemMessage reminder. scripts/ci/check-readme-params.sh checks that a row
# exists per parameter; this hook only checks that the docs were touched at
# all in the same piece of work.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "${PROJECT_DIR}"

if ! git rev-parse --git-dir &>/dev/null; then
    exit 0
fi

changed_against() {
    local ref="$1"
    shift
    if [[ -n "${ref}" ]]; then
        git diff --name-only "${ref}" -- "$@" 2>/dev/null || true
    else
        git diff --name-only -- "$@" 2>/dev/null || true
    fi
}

BASE_REF=""
if git rev-parse --verify --quiet origin/main &>/dev/null; then
    BASE_REF="origin/main...HEAD"
fi

SRC_CHANGED="$(changed_against "${BASE_REF}" src/commands src/jobs src/executors)"
SRC_CHANGED+=$'\n'"$(changed_against "" src/commands src/jobs src/executors)"

if [[ -z "${SRC_CHANGED//[$'\n' ]/}" ]]; then
    exit 0
fi

README_CHANGED="$(changed_against "${BASE_REF}" README.md src/README.md)"
README_CHANGED+=$'\n'"$(changed_against "" README.md src/README.md)"

if [[ -n "${README_CHANGED//[$'\n' ]/}" ]]; then
    exit 0
fi

jq -n '{
    systemMessage: "src/commands, src/jobs, or src/executors changed vs origin/main but README.md / src/README.md did not — verify the parameter tables are still in sync (scripts/ci/check-readme-params.sh checks that a row exists, not that it is correct)."
}'
