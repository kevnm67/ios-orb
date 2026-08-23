#!/usr/bin/env bash
# Generate an Xcode workspace via Tuist. Always passes --no-open so CI never
# tries to launch Xcode (verified 2026-08-23 against tuist 4.203.1:
# `tuist generate run --help` -> "-o, --open/--no-open ... default: --open").
# Env vars set by the orb command:
#   TUIST_PATH - path to the project directory or subdirectory (optional)
set -euo pipefail

ARGS=("generate" "--no-open")

if [ -n "${TUIST_PATH:-}" ]; then
    ARGS+=("--path" "${TUIST_PATH}")
fi

echo "→ Running: tuist ${ARGS[*]}"
tuist "${ARGS[@]}"
