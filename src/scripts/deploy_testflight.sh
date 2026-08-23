#!/usr/bin/env bash
# Upload a build to TestFlight via Fastlane.
# Fastlane-first: when LANE is set, run that lane and ignore every other
# parameter — teams with a Fastfile should own their own upload logic.
# Otherwise, run the upload_to_testflight action directly as a one-off via
# `bundle exec fastlane run`.
#
# Env vars set by the orb command:
#   LANE             - Fastlane lane to run instead of upload_to_testflight (optional)
#   IPA_PATH         - path to the .ipa to upload (optional)
#   APP_IDENTIFIER   - bundle identifier (optional, inferred from Appfile if empty)
#   API_KEY_PATH_VAR - name of the env var holding the ASC API key JSON path (optional)
#   SKIP_WAITING     - "true"/"1" for skip_waiting_for_build_processing:true
#   TESTFLIGHT_GROUPS - comma-separated beta tester group names (optional).
#                       Deliberately not named GROUPS: bash auto-populates a
#                       builtin $GROUPS array in every shell (current user's
#                       group IDs), which would shadow an env var of that name.
#   CHANGELOG        - "What to Test" changelog text (optional)
set -euo pipefail

if [ -n "${LANE:-}" ]; then
    echo "→ Running: bundle exec fastlane ${LANE}"
    bundle exec fastlane "${LANE}"
    exit 0
fi

ARGS=("run" "upload_to_testflight")

if [ -n "${IPA_PATH:-}" ]; then
    ARGS+=("ipa:${IPA_PATH}")
fi

if [ -n "${APP_IDENTIFIER:-}" ]; then
    ARGS+=("app_identifier:${APP_IDENTIFIER}")
fi

# Indirect expansion: API_KEY_PATH_VAR names the env var holding the ASC API
# key path (bash 3.2-compatible ${!var} form — macOS ships bash 3.2).
if [ -n "${API_KEY_PATH_VAR:-}" ]; then
    API_KEY_PATH_VALUE="${!API_KEY_PATH_VAR:-}"
    if [ -n "${API_KEY_PATH_VALUE}" ]; then
        ARGS+=("api_key_path:${API_KEY_PATH_VALUE}")
    fi
fi

case "${SKIP_WAITING:-true}" in
    true | 1)
        ARGS+=("skip_waiting_for_build_processing:true")
        ;;
    *)
        ARGS+=("skip_waiting_for_build_processing:false")
        ;;
esac

if [ -n "${TESTFLIGHT_GROUPS:-}" ]; then
    ARGS+=("groups:${TESTFLIGHT_GROUPS}")
fi

if [ -n "${CHANGELOG:-}" ]; then
    ARGS+=("changelog:${CHANGELOG}")
fi

echo "→ Running: bundle exec fastlane ${ARGS[*]}"
bundle exec fastlane "${ARGS[@]}"
