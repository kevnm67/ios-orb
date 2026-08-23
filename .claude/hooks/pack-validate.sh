#!/usr/bin/env bash
# .claude/hooks/pack-validate.sh
#
# PostToolUse gate (matcher: Edit|Write): whenever an unpacked orb source file
# changes (src/{commands,jobs,executors,examples}/*.yml or src/@orb.yml), runs
# `cd src && ./pack.sh` (pack + `circleci orb validate`) and, on success,
# stamps the verification marker that .claude/hooks/check-verified.sh requires
# before `git push` is allowed.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INPUT_JSON="$(cat)"
FILE_PATH="$(jq -r '.tool_input.file_path // empty' <<< "${INPUT_JSON}")"

if [[ -z "${FILE_PATH}" ]]; then
    exit 0
fi

case "${FILE_PATH}" in
    "${PROJECT_DIR}"/*) REL_PATH="${FILE_PATH#"${PROJECT_DIR}"/}" ;;
    *) REL_PATH="${FILE_PATH}" ;;
esac

case "${REL_PATH}" in
    src/commands/*.yml | src/jobs/*.yml | src/executors/*.yml | src/examples/*.yml | src/@orb.yml)
        ;;
    *)
        exit 0
        ;;
esac

if ! command -v circleci &>/dev/null; then
    jq -n '{
        systemMessage: "circleci CLI not found — skipped pack + validate for the src/ change. Install with `brew install circleci` and run `cd src && ./pack.sh` manually before pushing."
    }'
    exit 0
fi

PACK_LOG="$(mktemp)"
trap 'rm -f "${PACK_LOG}"' EXIT

if ! ( cd "${PROJECT_DIR}/src" && ./pack.sh ) >"${PACK_LOG}" 2>&1; then
    cat "${PACK_LOG}" >&2
    echo "pack.sh failed for ${REL_PATH} — fix the error above; it re-runs on the next src/ edit." >&2
    exit 2
fi

GIT_DIR="$(cd "${PROJECT_DIR}" && git rev-parse --absolute-git-dir 2>/dev/null || true)"
if [[ -n "${GIT_DIR}" ]]; then
    touch "${GIT_DIR}/.claude-verified"
fi

jq -n --arg path "${REL_PATH}" '{
    systemMessage: ("pack.sh validated " + $path + " OK — .claude-verified marker stamped.")
}'
