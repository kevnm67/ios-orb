#!/usr/bin/env bats
# Tests for src/scripts/create_release_tag.sh

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/create_release_tag.sh"
STUBS="${BATS_TEST_DIRNAME}/../stubs"

setup() {
    export PATH="${STUBS}:${PATH}"
    export STUB_CALL_LOG="${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log"
    rm -f "${STUB_CALL_LOG}"
    unset VERSION_SOURCE
}

# git stub returns "v1.2.3" for describe and exits 1 for rev-parse (tag doesn't exist)
# so the script should create v1.2.4

@test "defaults to git-describe and increments patch" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Creating tag: v1.2.4"* ]]
}

@test "git-describe source creates correct tag" {
    export VERSION_SOURCE="git-describe"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^git tag -a v1.2.4" "${STUB_CALL_LOG}"
}

@test "git-describe source pushes tag to origin" {
    export VERSION_SOURCE="git-describe"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    grep -q "^git push origin v1.2.4$" "${STUB_CALL_LOG}"
}

@test "marketing-version reads MARKETING_VERSION from xcodebuild" {
    export VERSION_SOURCE="marketing-version"
    export PATH="${STUBS}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    # xcodebuild stub outputs MARKETING_VERSION = 2.5.0
    [[ "${output}" == *"Creating tag: v2.5.0"* ]]
}

@test "unknown version_source exits with error" {
    export VERSION_SOURCE="invalid-source"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Unknown version_source"* ]]
}

@test "skips when tag already exists" {
    # Override git stub to make rev-parse succeed for v1.2.4
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cat > "${TMPBIN}/git" << 'GITSTUB'
#!/usr/bin/env bash
echo "git stub: $*" >> "${STUB_CALL_LOG}"
case "$*" in
    "describe --tags --abbrev=0") echo "v1.2.3" ;;
    "rev-parse v1.2.4") exit 0 ;;   # tag exists
    *) echo "stub:git $*" ;;
esac
GITSTUB
    chmod +x "${TMPBIN}/git"
    export PATH="${TMPBIN}:${PATH}"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already exists"* ]]
}

@test "marketing-version exits non-zero when MARKETING_VERSION empty" {
    export VERSION_SOURCE="marketing-version"
    # Override xcodebuild to return no MARKETING_VERSION line.
    # The script's grep pipeline produces empty NEW_VERSION; set -euo pipefail may
    # kill the script before the explicit error echo, so only assert exit status.
    TMPBIN="${BATS_TMPDIR}/bin_${BATS_TEST_NUMBER}"
    mkdir -p "${TMPBIN}"
    cat > "${TMPBIN}/xcodebuild" << 'XSTUB'
#!/usr/bin/env bash
echo "    SOME_OTHER_SETTING = value"
XSTUB
    chmod +x "${TMPBIN}/xcodebuild"
    export PATH="${TMPBIN}:/usr/bin:/bin:/usr/sbin:/sbin"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
}
