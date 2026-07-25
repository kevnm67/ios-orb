#!/usr/bin/env bash
# Resolve the Package.resolved file used for the SPM cache checksum key.
# Copies it to Package.resolved.cache-key in the working directory so
# {{ checksum }} always has a file to hash. Search order:
#   1. <XCODE_PROJECT>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
#      (Xcode projects, when XCODE_PROJECT is set)
#   2. Package.resolved at the repo root (pure SPM packages)
#   3. Neither exists -> empty key file (stable cache key, never a hard failure)
# Copying preserves file contents, so checksums are identical to keying on the
# original path — existing caches keyed on the xcodeproj path stay valid.
set -euo pipefail

KEY_FILE="Package.resolved.cache-key"
XCODE_PROJECT="${XCODE_PROJECT:-}"
XCODEPROJ_RESOLVED="${XCODE_PROJECT}.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if [[ -n "${XCODE_PROJECT}" && -f "${XCODEPROJ_RESOLVED}" ]]; then
    cp "${XCODEPROJ_RESOLVED}" "${KEY_FILE}"
    echo "-> SPM cache key from ${XCODEPROJ_RESOLVED}"
elif [[ -f "Package.resolved" ]]; then
    cp "Package.resolved" "${KEY_FILE}"
    echo "-> SPM cache key from root Package.resolved"
else
    : > "${KEY_FILE}"
    echo "⚠ No Package.resolved found. Using empty cache key file."
fi
