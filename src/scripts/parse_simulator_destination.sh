#!/usr/bin/env bash
# Parses a `name=<device>` value out of an xcodebuild -destination string and
# exports it as SIMULATOR_DEVICE via $BASH_ENV for later steps to consume.
# No-ops (writes an empty SIMULATOR_DEVICE) for non-simulator destinations,
# a missing DESTINATION, or a destination without a `name=` field — bash 3.2
# safe (no associative arrays, no ${var,,}).
# Env vars set by the orb command:
#   DESTINATION - xcodebuild -destination value to parse (optional)
set -euo pipefail

DESTINATION="${DESTINATION:-}"
BASH_ENV="${BASH_ENV:-/dev/null}"

DEVICE=""
if [[ "${DESTINATION}" == *"Simulator"* ]]; then
    # Extract the value of name=... up to the next comma or end of string,
    # so "name=iPad (A16),OS=18.0" yields "iPad (A16)" and "name=iPhone 17"
    # (no trailing field) yields "iPhone 17".
    DEVICE="$(printf '%s' "${DESTINATION}" | sed -n 's/.*name=\([^,]*\).*/\1/p')"
fi

echo "export SIMULATOR_DEVICE=\"${DEVICE}\"" >> "${BASH_ENV}"

if [ -n "${DEVICE}" ]; then
    echo "→ Parsed simulator device from destination: ${DEVICE}"
else
    echo "→ No simulator device found in destination; preboot will no-op."
fi
