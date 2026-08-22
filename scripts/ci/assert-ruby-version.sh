#!/usr/bin/env bash
# Assert the active Ruby matches the expected major.minor (default 3.3) and
# print what the CircleCI Xcode image offers via rbenv. Used by the
# fastlane-fixture-test job to prove the orb's `setup` Ruby default resolves
# on the current image before fastlane runs.
#
# Usage: ./scripts/ci/assert-ruby-version.sh [expected-major.minor]
set -euo pipefail

EXPECTED="${1:-3.3}"

echo "-> rbenv versions available on this image:"
rbenv versions --bare 2>/dev/null || echo "   (rbenv not found)"

ACTUAL="$(ruby -e 'puts RUBY_VERSION')"
echo "-> active ruby: ${ACTUAL} ($(command -v ruby))"

if [[ "${ACTUAL}" != "${EXPECTED}".* ]]; then
    echo "ERROR: expected Ruby ${EXPECTED}.x but got ${ACTUAL}" >&2
    exit 1
fi

echo "-> fastlane: $(bundle exec fastlane --version 2>/dev/null | tail -1)"
echo "✓ Ruby ${ACTUAL} OK"
