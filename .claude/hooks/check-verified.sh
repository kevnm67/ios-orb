#!/usr/bin/env bash
# .claude/hooks/check-verified.sh
#
# PreToolUse gate (matcher: Bash, if: "Bash(git push*)"): blocks `git push`
# when src/ or tests/ have commits (vs origin/main) newer than the last
# successful pack + validate run. The marker is stamped by
# .claude/hooks/pack-validate.sh (PostToolUse on Edit|Write) after
# `cd src && ./pack.sh` succeeds.
#
# Reads the standard PreToolUse stdin JSON (unused here — the `if` filter on
# the hook registration already scopes this to `git push` commands) and
# writes a PreToolUse hookSpecificOutput permission decision to stdout.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

allow() {
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow"
        }
    }'
    exit 0
}

deny() {
    local reason="$1"
    jq -n --arg reason "${reason}" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

cd "${PROJECT_DIR}"

# Not a git repo (shouldn't happen for this repo, but never block blindly).
if ! git rev-parse --git-dir &>/dev/null; then
    allow
fi

BASE_REF="origin/main"
if ! git rev-parse --verify --quiet "${BASE_REF}" &>/dev/null; then
    # No remote baseline to diff against — nothing to gate on.
    allow
fi

CHANGED_FILES="$(git diff --name-only "${BASE_REF}"...HEAD -- src tests 2>/dev/null || true)"

if [[ -z "${CHANGED_FILES}" ]]; then
    allow
fi

GIT_DIR="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
if [[ -z "${GIT_DIR}" ]]; then
    # Should be unreachable (the git-dir check above already passed), but
    # never hard-fail the hook over an unexpected git quirk — fail open.
    allow
fi
MARKER="${GIT_DIR}/.claude-verified"

if [[ ! -f "${MARKER}" ]]; then
    deny "src/ or tests/ changed vs origin/main but no verification marker (${MARKER}) exists yet. Edit a file under src/{commands,jobs,executors,examples}/ or src/@orb.yml to trigger the pack-validate hook, or run 'cd src && ./pack.sh' and 'touch \"${MARKER}\"' manually before pushing."
fi

# GNU stat first: on Linux `stat -f %m` is filesystem mode (prints the mount
# point and SUCCEEDS), so BSD-first ordering silently returns garbage there.
MARKER_MTIME="$(stat -c %Y "${MARKER}" 2>/dev/null || stat -f %m "${MARKER}" 2>/dev/null || echo 0)"
LATEST_COMMIT_TS="$(git log -1 --format=%ct "${BASE_REF}"...HEAD -- src tests 2>/dev/null || echo 0)"
LATEST_COMMIT_TS="${LATEST_COMMIT_TS:-0}"

# POSIX test instead of (( )): a false arithmetic command trips `set -e`
# (GNU bash 5 on cimg/base) and killed the deny path with exit 1.
if [ "${MARKER_MTIME}" -gt "${LATEST_COMMIT_TS}" ]; then
    allow
fi

deny "src/ or tests/ have commits newer than the last verified pack/validate run (${MARKER}). Re-run 'cd src && ./pack.sh' (or edit an orb source file again to re-trigger the pack-validate hook) before pushing."
