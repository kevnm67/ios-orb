#!/usr/bin/env bash
# Warn (never fail) when the SPM cache path doesn't exist before save_cache
# runs. This is the common pure-SPM footgun: cache_spm's `path` default
# targets the Xcode-managed SourcePackages directory, which a pure `swift
# build` never creates (`.build` is the real output there). save_cache
# already treats a missing path as a no-op, so this is diagnostic only.
# Env: CACHE_PATH - path that will be passed to save_cache
set -euo pipefail

CACHE_PATH="${CACHE_PATH:-}"

if [[ -z "${CACHE_PATH}" ]]; then
    echo "⚠ cache_spm: no path configured. Nothing will be cached."
    exit 0
fi

if [[ ! -e "${CACHE_PATH}" ]]; then
    echo "⚠ cache_spm: path '${CACHE_PATH}' does not exist yet. Nothing will be cached this run."
    echo "  Pure SPM packages must pass path: .build to cache_spm."
    exit 0
fi

echo "-> cache_spm: caching ${CACHE_PATH}"
