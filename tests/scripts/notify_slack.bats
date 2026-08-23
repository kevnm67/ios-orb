#!/usr/bin/env bats
# Tests for src/scripts/notify_slack.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/notify_slack.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"

    export WEBHOOK_VAR="SLACK_WEBHOOK"
    export SLACK_WEBHOOK="https://hooks.slack.com/services/T00/B00/xxx"
    export MESSAGE="Job build finished"
    unset STUB_CURL_FAIL
}

@test "sends the payload to the webhook URL" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "--data {\"text\": \"Job build finished\"} https://hooks.slack.com/services/T00/B00/xxx" "${STUB_CALL_LOG}"
    [[ "${output}" == *"Slack notification sent"* ]]
}

@test "skips with a warning when the named env var is unset" {
    unset SLACK_WEBHOOK
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"unset or empty"* ]]
    [ ! -s "${STUB_CALL_LOG}" ]
}

@test "skips with a warning when the named env var is empty" {
    export SLACK_WEBHOOK=""
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"unset or empty"* ]]
    [ ! -s "${STUB_CALL_LOG}" ]
}

@test "exits 0 with a warning when curl fails" {
    export STUB_CURL_FAIL=1
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"curl failed"* ]]
}

@test "escapes double quotes in the message" {
    export MESSAGE='Say "hello" now'
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -qF '{"text": "Say \"hello\" now"}' "${STUB_CALL_LOG}"
}

@test "escapes backslashes in the message" {
    export MESSAGE='C:\path\to\thing'
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -qF '{"text": "C:\\path\\to\\thing"}' "${STUB_CALL_LOG}"
}

@test "posts as a JSON content-type POST" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q -- "-X POST -H Content-type: application/json" "${STUB_CALL_LOG}"
}
