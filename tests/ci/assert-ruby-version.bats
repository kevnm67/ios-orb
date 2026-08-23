#!/usr/bin/env bats
# Tests for scripts/ci/assert-ruby-version.sh
# Uses local stubs (not tests/stubs/ruby) because that generic stub always
# prints a fixed "ruby 3.2.0 (stub)" banner rather than a bare version
# string, which this script parses with `ruby -e 'puts RUBY_VERSION'`.

SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/ci/assert-ruby-version.sh"
SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

setup() {
    TMPBIN="$(mktemp -d "${BATS_TMPDIR}/assert-ruby-version.XXXXXX")"
}

stub_ruby() {
    local version="$1"
    cat > "${TMPBIN}/ruby" << RUBYSTUB
#!/usr/bin/env bash
echo "${version}"
RUBYSTUB
    chmod +x "${TMPBIN}/ruby"
}

stub_rbenv() {
    cat > "${TMPBIN}/rbenv" << 'RBENVSTUB'
#!/usr/bin/env bash
printf "3.1.0\n3.3.4\n"
RBENVSTUB
    chmod +x "${TMPBIN}/rbenv"
}

stub_bundle() {
    cat > "${TMPBIN}/bundle" << 'BUNDLESTUB'
#!/usr/bin/env bash
echo "fastlane 2.220.0"
BUNDLESTUB
    chmod +x "${TMPBIN}/bundle"
}

@test "passes when active ruby matches the expected major.minor" {
    stub_ruby "3.3.4"
    stub_rbenv
    stub_bundle
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}" 3.3
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Ruby 3.3.4 OK"* ]]
}

@test "defaults expected version to 3.3" {
    stub_ruby "3.3.0"
    stub_rbenv
    stub_bundle
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Ruby 3.3.0 OK"* ]]
}

@test "fails clearly when active ruby does not match expected major.minor" {
    stub_ruby "3.2.0"
    stub_rbenv
    stub_bundle
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}" 3.3
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"ERROR: expected Ruby 3.3.x but got 3.2.0"* ]]
}

@test "reports rbenv not found instead of failing when rbenv is absent" {
    stub_ruby "3.3.4"
    stub_bundle
    export PATH="${TMPBIN}:${SYSTEM_PATH}"
    run bash "${SCRIPT}" 3.3
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"(rbenv not found)"* ]]
}
