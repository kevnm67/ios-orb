#!/usr/bin/env bash
# Prepare SSH known_hosts so xcodebuild can resolve SPM packages hosted on
# GitHub / Bitbucket over SSH without interactive host-key prompts.
# Removes the CircleCI-provisioned id_rsa so the deploy key does not shadow
# a user-supplied key. All steps are best-effort.
set -uo pipefail

rm -f ~/.ssh/id_rsa

for host in github.com bitbucket.org; do
    for ip in $(dig @8.8.8.8 "${host}" +short); do
        ssh-keyscan "${host},${ip}" 2>/dev/null
        ssh-keyscan "${ip}" 2>/dev/null
    done >> ~/.ssh/known_hosts || true
done

exit 0
