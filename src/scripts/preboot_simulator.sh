#!/usr/bin/env bash
# Boots the simulator device parsed by parse_simulator_destination.sh ahead
# of the build/test steps, shrinking simulator warm-up time in the test step.
# No-ops when SIMULATOR_DEVICE is empty (non-simulator destination) — this is
# implemented here, in the script, because a CircleCI orb `when:` step
# condition cannot inspect a value exported to $BASH_ENV at runtime.
# Env vars set by the orb command:
#   SIMULATOR_DEVICE - device name to boot (optional; empty = no-op)
set -euo pipefail

SIMULATOR_DEVICE="${SIMULATOR_DEVICE:-}"

if [ -z "${SIMULATOR_DEVICE}" ]; then
    echo "→ No simulator device to preboot; skipping."
    exit 0
fi

echo "→ Prebooting simulator: ${SIMULATOR_DEVICE}"
# "Unable to boot device in current state: Booted" is not a failure — it
# just means a previous step already warmed it up.
xcrun simctl boot "${SIMULATOR_DEVICE}" || true
