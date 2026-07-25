#!/usr/bin/env bats
# Tests for src/scripts/resolve_spm_cache_key.sh
# The script must always produce Package.resolved.cache-key so that
# {{ checksum }} never fails, preferring the xcodeproj Package.resolved,
# then the root Package.resolved, then an empty file.

SCRIPT="${BATS_TEST_DIRNAME}/../../src/scripts/resolve_spm_cache_key.sh"

setup() {
    WORK_DIR="${BATS_TMPDIR}/cachekey_${BATS_TEST_NUMBER}"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
}

@test "uses xcodeproj Package.resolved when XCODE_PROJECT is set and file exists" {
    mkdir -p "MyApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
    echo "xcodeproj-pins" > "MyApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    echo "root-pins" > Package.resolved
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"MyApp.xcodeproj"* ]]
    [ "$(cat Package.resolved.cache-key)" = "xcodeproj-pins" ]
}

@test "falls back to root Package.resolved for pure SPM packages" {
    echo "root-pins" > Package.resolved
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"root Package.resolved"* ]]
    [ "$(cat Package.resolved.cache-key)" = "root-pins" ]
}

@test "falls back to root Package.resolved when XCODE_PROJECT set but xcodeproj file missing" {
    echo "root-pins" > Package.resolved
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"root Package.resolved"* ]]
    [ "$(cat Package.resolved.cache-key)" = "root-pins" ]
}

@test "writes an empty key file when no Package.resolved exists" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No Package.resolved found"* ]]
    [ -f Package.resolved.cache-key ]
    [ ! -s Package.resolved.cache-key ]
}

@test "key file content matches source so existing cache checksums stay valid" {
    mkdir -p "MyApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
    printf 'pin-content\nline2\n' > "MyApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    XCODE_PROJECT="MyApp" run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    cmp -s "MyApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" Package.resolved.cache-key
}
