#!/usr/bin/env bash
# Resolve the source file used for the DerivedData cache checksum key.
# Copies it to DerivedData.cache-key in the working directory so
# {{ checksum }} always has a file to hash. DerivedData caching is
# best-effort: it approximates "did the project structure change", not "did
# the source change" — Xcode's own incremental-build staleness heuristics
# still decide whether a cached build product is actually reusable, so a
# cache hit here is a possible speedup, not a correctness guarantee. Search
# order:
#   1. project.yml (XcodeGen source spec — regenerated deterministically on
#      every build, so it is the most stable proxy for "did the project
#      structure change" available without hashing every source file)
#   2. <XCODE_PROJECT>.xcodeproj/project.pbxproj (checked-in Xcode projects)
#   3. Neither exists -> empty key file (stable cache key, never a hard
#      failure)
# Env vars set by the orb command:
#   XCODE_PROJECT - name of the .xcodeproj (without extension), optional
#   SCHEME        - Xcode scheme; not used in the key itself today, kept as
#                   an env var for a future scheme-scoped cache key
set -euo pipefail

KEY_FILE="DerivedData.cache-key"
XCODE_PROJECT="${XCODE_PROJECT:-}"
PBXPROJ_PATH="${XCODE_PROJECT}.xcodeproj/project.pbxproj"

if [[ -f "project.yml" ]]; then
    cp "project.yml" "${KEY_FILE}"
    echo "-> DerivedData cache key from project.yml"
elif [[ -n "${XCODE_PROJECT}" && -f "${PBXPROJ_PATH}" ]]; then
    cp "${PBXPROJ_PATH}" "${KEY_FILE}"
    echo "-> DerivedData cache key from ${PBXPROJ_PATH}"
else
    : > "${KEY_FILE}"
    echo "⚠ No project.yml or project.pbxproj found. Using empty DerivedData cache key file."
fi
