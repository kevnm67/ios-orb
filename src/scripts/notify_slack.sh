#!/usr/bin/env bash
# Post a Slack notification via an Incoming Webhook. Notifications must
# never fail the build: a missing/empty webhook or a curl error is a
# warning, and the script always exits 0.
#
# Env vars set by the orb command:
#   WEBHOOK_VAR - name of the env var holding the Slack Incoming Webhook URL
#   MESSAGE     - message text to post. CircleCI's `environment:` step
#                 already interpolates any ${CIRCLE_*} references in the
#                 raw parameter value via bash double-quote expansion, so
#                 this script sees the fully-resolved text.
set -euo pipefail

# Indirect expansion: WEBHOOK_VAR names the env var holding the webhook URL
# (bash 3.2-compatible ${!var} form — macOS ships bash 3.2).
WEBHOOK_URL="${!WEBHOOK_VAR:-}"

if [ -z "${WEBHOOK_URL}" ]; then
    echo "⚠ notify_slack: \$${WEBHOOK_VAR} is unset or empty — skipping Slack notification"
    exit 0
fi

# Escape backslashes, then double quotes, so MESSAGE is safe inside a JSON
# string literal. Order matters — escaping quotes first would double-escape
# the backslashes just inserted for them.
ESCAPED_MESSAGE="${MESSAGE//\\/\\\\}"
ESCAPED_MESSAGE="${ESCAPED_MESSAGE//\"/\\\"}"

if curl -sf -X POST -H 'Content-type: application/json' \
    --data "{\"text\": \"${ESCAPED_MESSAGE}\"}" \
    "${WEBHOOK_URL}"; then
    echo "✓ Slack notification sent"
else
    echo "⚠ notify_slack: curl failed to post to the webhook — continuing"
fi

exit 0
