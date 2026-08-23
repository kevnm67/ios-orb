# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `build_and_test_xcode`: `preboot_simulator` parameter — preboots the
    Simulator device parsed from `destination` before building via the new
    `preboot_simulator` command (`src/scripts/parse_simulator_destination.sh`
    + `src/scripts/preboot_simulator.sh`); no-ops for non-simulator
    destinations.
- `test_spm` / `build_and_test_spm`: `test_framework` parameter (`auto`,
    `xctest`, `swift-testing`) — `auto` detects Swift Testing via
    `import Testing` in `Tests/`; `swift-testing` forces `--parallel` and
    writes an xunit report via `swift test --xunit-output` instead of
    xcbeautify's JUnit reporter.
- `test_xcode` / `build_and_test_xcode`: `retry_on_failure` and
    `test_iterations` parameters — retries only failed tests via
    `xcodebuild -retry-tests-on-failure -test-iterations` for flaky-test
    resilience.
- New `assert_xcode_channel` command + script, wired as the first step of
    `build_and_test_xcode` and `build_and_test_spm` via the new
    `allow_beta_xcode` job parameter — fails fast if `xcode_version` looks
    like a beta/build-string image (e.g. `27A5228h`) instead of a stable
    dotted release.
- `swiftformat` command — installs SwiftFormat via Homebrew and runs it in
    check-only `--lint` mode by default (`lint`, `config`, `paths`
    parameters), matching the `swiftlint` command's shape.
- `periphery_scan` command — installs Periphery via Homebrew (now a core
    formula; the `peripheryapp/homebrew-periphery` tap is unmaintained) and
    runs an unused-code scan (`config`, `strict`, `extra_args` parameters).
- `upload_dsyms` command — installs `sentry-cli` via Homebrew if needed and
    uploads `.dSYM` files to Sentry (`dsym_path`, `sentry_org`,
    `sentry_project`, `auth_token`, `skip_errors` parameters).
- `notarize_macos` command — zips a `.app` bundle, submits it to
    `xcrun notarytool`, and staples the ticket (`app_path`, `api_key_path`,
    `api_key_id`, `api_issuer_id`, `staple` parameters). Credential
    parameters are `env_var_name`, never raw secret values.
- `tests/stubs/swiftformat`, `tests/stubs/periphery`,
    `tests/stubs/sentry-cli`, `tests/stubs/ditto`, plus a controlled-failure
    hook added to `tests/stubs/xcrun` for notarization failure test cases.

## [3.2.0] - 2026-08-23

### Added

- Complete `README.md` and `src/README.md` parameter documentation — every
    orb command and job parameter now has a documented table row — plus new
    `src/examples/` workflow examples (#118).
- `.claude/skills/` (`orb-release`, `orb-param-sync`, `xcode-image-bump`,
    `orb-add-command`, `orb-diagram-sync`), `.claude/hooks/` (verified-push
    gate, packed-file edit guard, pack + validate on src/ change, README-sync
    advisory) and `.claude/settings.json` wiring them up, `.claude/agents/`
    (`bats-test-writer`, `orb-docs-syncer`) — committed project Claude Code
    configuration, plus `CONTRIBUTING.md`, this `CHANGELOG.md`, and other
    repo hygiene (#120).
- `scripts/ci/check-readme-params.sh` — verifies every orb command/job
    parameter has a documented row in both `README.md` and `src/README.md`.
- `tests/hooks/*.bats` and `tests/ci/*.bats` suites, run as a `hook-tests`
    step in the `script-tests` CI job, bringing the suite to 111 `bats`
    tests (#119).
- Advisory `pr-review` CI workflow that posts automated Claude review
    comments on pull requests (#123, #124).

### Changed

- Quality-audit fixes across orb commands and jobs, including missing
    parameter pass-throughs on job wrappers, `setup`'s SPM cache falling
    back to the root `Package.resolved` for pure-SPM packages (no
    `xcode_project` set), and hardened `src/scripts/*.sh` (#119).
- Pinned `anthropics/claude-code-action` to a specific commit digest
    instead of a floating tag (#121).
- `.gitignore`: `.claude/skills/`, `.claude/hooks/`, and `.claude/settings.json`
    are now committed (only `.claude/settings.local.json` stays ignored).
- `.github/labeler.yml`: removed the dead `config-iOS` block (referenced
    nonexistent `orbs/ios*/**` paths), added a `claude` label for `.claude/**`,
    and widened `documentation` to cover `docs/**`, `src/README.md`, `wiki/**`.

### Removed

- `.github/release_drafter.yml` — orphaned; nothing referenced it.
    `.github/workflows/release-on-tag.yml`'s `gh release create --generate-notes`
    is the only release-notes source.

### Fixed

- `LICENSE` copyright holder (`<organization>` placeholder → Kevin Morton).
- `.github/ISSUE_TEMPLATE/BUG.yml` / `FEATURE_REQUEST.yml`: issue-search and
    orb-name placeholders pointed at unrelated repos; now point at
    `kevnm67/ios-orb`.

## [3.1.1] - 2026-08-22

### Fixed

- `setup`'s Ruby default is `3.3`, not `3.4` — 3.4 breaks Fastlane in consumer
    projects. Examples and the quick-start docs now lead with `run_with_setup`
    + the `test` job / `lane` command (Fastlane-first), with the raw
    `xcodebuild` commands documented as the fallback for projects without a
    Fastfile.
- Added the `fastlane-fixture-test` CI job as the regression proof that the
    Ruby default actually resolves on the current image
    (`scripts/ci/assert-ruby-version.sh`).

## [3.1.0] - 2026-08-22

### Changed

- **Xcode 26.6** default (Swift 6.3.3, iOS 26.5 runtime, macOS 26.5.1) for the
    executor and every job; the previous `26.3.0` image remains selectable via
    `xcode_version`.
- Bundled orbs bumped to `circleci/macos@3.0.0`, `circleci/ruby@3.0.0`.
- All `xcodebuild` / `swift build` / `swift test` logic moved from inline
    command-step shell into unit-tested `src/scripts/*.sh` — behavior
    unchanged, but `pipefail` now correctly fails a step when the underlying
    build fails instead of that failure being masked by `xcbeautify`.
- `build_and_test_spm`'s cache key now goes through `restore_spm_cache` /
    `cache_spm`, so packages with no `Package.resolved` (no dependencies) no
    longer fail on `checksum`.
- `brew_install` defaults switched to the Apple Silicon Homebrew prefix
    (`/opt/homebrew`).

### Added

- `test_xcode.junit_report`, `test_spm.report_path` parameters.

## [3.0.0] - 2026-06-06

### Changed

- **Breaking:** replaced the end-of-life Code Climate test reporter with
    [Qlty Cloud](https://qlty.sh). `test_with_code_climate` is removed;
    replace with `test_with_qlty`.
- **Breaking:** the `test` job's `cc_prefix` parameter is removed. The `test`
    job gained `result_bundle_path`, `coverage_file`, `qlty_tag`, and
    `qlty_skip_errors` in its place.
- **Breaking:** `upload_qlty_coverage`'s pass-through parameters
    (`file`, `format`, `tag`, `token`, `skip_errors`) replace the previous
    single-option Code Climate call shape.
- `QLTY_COVERAGE_TOKEN` (from qlty.sh project settings) is now required in
    place of Code Climate's `CC_TEST_REPORTER_ID`, which is no longer used.

### Added

- `build_and_test_xcode` and `build_and_test_spm` flagship jobs, providing
    complete single-job CI for most Xcode and SPM projects respectively.

[Unreleased]: https://github.com/kevnm67/ios-orb/compare/v3.2.0...HEAD
[3.2.0]: https://github.com/kevnm67/ios-orb/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/kevnm67/ios-orb/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/kevnm67/ios-orb/compare/v3.0.2...v3.1.0
[3.0.0]: https://github.com/kevnm67/ios-orb/compare/v2.0.1...v3.0.0
