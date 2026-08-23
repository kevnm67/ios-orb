#!/usr/bin/env bash
# Fails fast when XCODE_VERSION looks like a beta/build-string Xcode image
# (e.g. "27A5228h") instead of a stable dotted release (e.g. "26.6" or
# "26.4.1"), so CI does not silently pin to an unstable Xcode channel.
# Env vars set by the orb command:
#   XCODE_VERSION    - Xcode version to validate
#   ALLOW_BETA_XCODE - "true"/"1" to permit a beta/build-string version
set -euo pipefail

XCODE_VERSION="${XCODE_VERSION:-}"
ALLOW_BETA_XCODE="${ALLOW_BETA_XCODE:-false}"

case "${ALLOW_BETA_XCODE}" in
    true | 1)
        echo "→ allow_beta_xcode is set; skipping stable-channel check for '${XCODE_VERSION}'."
        exit 0
        ;;
    *) ;;
esac

if [[ "${XCODE_VERSION}" =~ [A-Za-z] ]]; then
    echo "error: XCODE_VERSION '${XCODE_VERSION}' looks like a beta/build-string Xcode image (it contains a letter), not a stable dotted release such as '26.6'." >&2
    echo "Set allow_beta_xcode: true on the job if this is intentional." >&2
    exit 1
fi

echo "→ Xcode version '${XCODE_VERSION}' looks like a stable release."
