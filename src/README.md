# ios-orb

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/kevnm67/ios-orb/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/kevnm67/ios-orb/tree/main)
[![CircleCI Orb Version](https://badges.circleci.com/orbs/kevnm67/ios-orb.svg)](https://circleci.com/developer/orbs/orb/kevnm67/ios-orb)
[![Maintainability](https://qlty.sh/badges/f5e5400a-92d0-4f83-82e8-640bd86fb9ee/maintainability.svg)](https://qlty.sh/gh/kevnm67/projects/ios-orb)
[![Code Coverage](https://qlty.sh/badges/f5e5400a-92d0-4f83-82e8-640bd86fb9ee/coverage.svg)](https://qlty.sh/gh/kevnm67/projects/ios-orb)

A CircleCI orb for iOS and macOS CI/CD. Provides reusable jobs, commands, and executors for building, testing, linting, and deploying Swift projects — SPM packages, XcodeGen-based apps, and standard Xcode projects.

---

## Table of Contents

- [Quick Start: SPM Package](#quick-start-spm-package)
- [Quick Start: XcodeGen Project](#quick-start-xcodegen-project)
- [Executor](#executor)
- [Jobs Reference](#jobs-reference)
- [Commands Reference](#commands-reference)
    - [Command Parameter Reference](#command-parameter-reference)
- [Examples](#examples)
- [Migration from v1](#migration-from-v1)
- [Migration from v2 to v3](#migration-from-v2-to-v3)
- [What's new in v3.1](#whats-new-in-v31)

---

## Quick Start: SPM Package

```yaml
version: 2.1
orbs:
    ios: kevnm67/ios-orb@3.2.0
workflows:
    ci:
        jobs:
            - ios/build_and_test_spm:
                xcode_version: "26.6"
                qlty: true
```

## Quick Start: XcodeGen Project

```yaml
version: 2.1
orbs:
    ios: kevnm67/ios-orb@3.2.0
workflows:
    ci:
        jobs:
            - ios/run_with_setup:
                xcode_version: "26.6"
                scripts:
                    - ios/install_tools:
                        tools: xcodegen swiftlint
                    - ios/xcodegen
                    - run: bundle exec fastlane test
```

---

## Executor

### `macos`

Apple Silicon macOS executor with Xcode pre-installed.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.6` | Xcode image tag (Xcode 26.6 / Swift 6.3 / iOS 26.5 simulators). See [supported versions](https://circleci.com/docs/guides/execution-managed/using-macos/#supported-xcode-versions-silicon). |
| `resource_class` | string | `m4pro.medium` | macOS resource class. |

---

## Jobs Reference

### `run_with_setup`

General-purpose job: checkout, attach workspace, run custom scripts, save artifacts.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.6` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `checkout` | boolean | `true` | Checkout source code |
| `attach_workspace` | boolean | `true` | Attach to existing workspace |
| `xcode_project` | string | `""` | Xcode project name (for SPM cache key) |
| `homebrew_no_auto_update` | integer | `1` | Disable Homebrew auto-update (1=yes) |
| `logs_path` | string | `~/Library/Logs/scan` | Path to scan logs |
| `build_logs_path` | string | `~/Library/Logs/DiagnosticReports/` | Path to diagnostic reports |
| `test_output_path` | string | `./fastlane/test_output` | Path to test output |
| `scripts` | steps | `[]` | Custom steps to run |
| `bundle_install` | boolean | `true` | Whether to run `bundle install` during setup |
| `ruby_version` | string | `3.3` | Ruby version to install during setup |
| `key` | string | `gems-v2` | The cache key to use for the gems cache during setup. The key is immutable |

### `test`

Run tests via a fastlane lane and upload coverage to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.6` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `checkout` | boolean | `true` | Checkout source code |
| `attach_workspace` | boolean | `true` | Attach to existing workspace |
| `xcode_project` | string | `""` | Xcode project name (for SPM cache key) |
| `with_spm` | boolean | `false` | Setup SSH for SPM dependencies |
| `homebrew_no_auto_update` | integer | `1` | Disable Homebrew auto-update (1=yes) |
| `logs_path` | string | `~/Library/Logs/scan` | Path to scan logs |
| `build_logs_path` | string | `~/Library/Logs/DiagnosticReports/` | Path to diagnostic reports |
| `test_output_path` | string | `./fastlane/test_output` | Path to test output |
| `result_bundle_path` | string | `TestResults.xcresult` | xcresult bundle path from the test run |
| `coverage_file` | string | `coverage.xml` | Exported cobertura XML uploaded to Qlty |
| `qlty_tag` | string | `""` | Optional Qlty coverage tag |
| `qlty_skip_errors` | boolean | `false` | Make Qlty upload errors non-fatal |
| `pretest_steps` | steps | `[]` | Steps to run before tests |
| `test_steps` | steps | `[]` | Steps to run during test phase |
| `lane` | string | `""` | Fastlane lane to execute |
| `scripts` | steps | `[]` | Setup workspace scripts |
| `bundle_install` | boolean | `true` | Whether to run `bundle install` during setup |
| `ruby_version` | string | `3.3` | Ruby version to install during setup |
| `key` | string | `gems-v2` | The cache key to use for the gems cache during setup. The key is immutable |

### `build_and_test_xcode`

Complete CI job for Xcode projects. Optionally runs XcodeGen, builds,
tests, exports coverage, and uploads to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scheme` | string | — | Xcode scheme to build and test |
| `xcode_version` | string | `26.6` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `xcodegen` | boolean | `false` | Run XcodeGen before building |
| `project` | string | `""` | Path to `.xcodeproj` (empty = default) |
| `destination` | string | `platform=macOS` | Build and test destination |
| `configuration` | string | `Debug` | Build configuration |
| `result_bundle_path` | string | `TestResults.xcresult` | Path to xcresult bundle |
| `parallelism` | integer | `1` | CircleCI parallelism level |
| `coverage` | boolean | `true` | Export code coverage |
| `qlty` | boolean | `true` | Upload coverage to Qlty Cloud |
| `xcode_project` | string | `""` | Project name for SPM cache key |
| `pre_steps` | steps | `[]` | Steps to run before build |
| `junit_report` | string | `test-results.xml` | Path of the JUnit XML report written by xcbeautify and stored as test results |

### `build_and_test_spm`

Complete CI job for Swift Package Manager projects. Builds, tests, exports
coverage, and optionally uploads to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.6` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `parallelism` | integer | `1` | CircleCI parallelism level |
| `coverage` | boolean | `true` | Export code coverage |
| `qlty` | boolean | `true` | Upload coverage to Qlty Cloud |
| `build_flags` | string | `""` | Additional flags for `swift build` |
| `configuration` | string | `debug` | Build configuration (`debug` or `release`) |
| `filter` | string | `""` | Test filter pattern |
| `pre_steps` | steps | `[]` | Steps to run before build |
| `parallel` | boolean | `true` | Whether to run tests in parallel |
| `report_path` | string | `build/reports` | Directory the JUnit report is written to and stored from |

---

## Commands Reference

| Command | Description | Key Parameters |
|---------|-------------|----------------|
| `setup` | Checkout, attach workspace, install Ruby gems, restore caches | `checkout`, `attach_workspace`, `bundle_install`, `ruby_version`, `key`, `persist_workspace`, `xcode_project`, `with_spm`, `scripts`, `workspace_root` |
| `install_tools` | Install Homebrew formulas (skips already-installed) | `tools` (space-separated, default: `xcodegen swiftlint`) |
| `xcodegen` | Install XcodeGen and generate the Xcode project | `spec` (default: `project.yml`), `quiet` |
| `swiftlint` | Install and run SwiftLint | `strict`, `config`, `reporter` |
| `swiftformat` | Install and run SwiftFormat (check-only lint mode by default) | `lint` (default: `true`), `config`, `paths` (default: `.`) |
| `periphery_scan` | Install Periphery and scan for unused Swift code | `config`, `strict`, `extra_args` |
| `upload_dsyms` | Install sentry-cli and upload dSYMs to Sentry | `dsym_path` (default: `.`), `sentry_org`, `sentry_project`, `auth_token` (default: `SENTRY_AUTH_TOKEN`), `skip_errors` |
| `notarize_macos` | Notarize and staple a macOS `.app` bundle via `notarytool` | `app_path`, `api_key_path` (default: `ASC_KEY_PATH`), `api_key_id` (default: `ASC_KEY_ID`), `api_issuer_id` (default: `ASC_ISSUER_ID`), `staple` (default: `true`) |
| `lane` | Run a Fastlane lane | `named` |
| `match_signing` | Sync code signing via Fastlane Match | `type` (default: `appstore`), `readonly`, `app_identifier` |
| `build_xcode` | `xcodebuild build` piped through xcbeautify | `scheme`, `project`, `destination`, `configuration` |
| `test_xcode` | `xcodebuild test` with coverage + JUnit report | `scheme`, `project`, `destination`, `result_bundle_path`, `junit_report` (default: `test-results.xml`) |
| `build_spm` | `swift build` piped through xcbeautify | `configuration`, `build_flags` |
| `test_spm` | `swift test` with coverage, `--parallel` and JUnit report | `filter`, `parallel`, `coverage`, `report_path` (default: `build/reports`) |
| `create_release_tag` | Tag and push the next `vX.Y.Z` release | `version_source` (`git-describe` or `marketing-version`) |
| `brew_install` | Install a Homebrew formula with caching | `formula`, `reinstall`, `with_cache`, `brew_cache_key`, `brew_dir`, `cellar_dir`, `post_steps` |
| `restore_brew` | Restore the Homebrew cache written by `brew_install` | `brew_cache_key` (default: `brew-v1`) |
| `cache_spm` | Save SPM package cache | `key`, `xcode_project`, `path` |
| `restore_spm_cache` | Restore SPM package cache | `key`, `xcode_project` |
| `save_build_artifacts` | Store build logs and test results | `logs_path`, `build_logs_path`, `test_output_path`, `gym_logs_path` |
| `test_with_qlty` | Run tests and upload coverage to Qlty Cloud | `lane`, `pretest_steps`, `test_steps`, `result_bundle_path`, `coverage_file`, `qlty_tag`, `qlty_skip_errors`, `xcode_project` |
| `upload_qlty_coverage` | Upload a coverage file to Qlty Cloud | `file`, `format`, `tag`, `token`, `skip_errors` |
| `export_coverage` | Export coverage — `spm` → `coverage.lcov` (lcov), `xcode` → `coverage.xml` (cobertura) | `type` (`spm` or `xcode`), `result_bundle` |

### Command Parameter Reference

Full type/default/description detail for the "Key Parameters" named above.

| Command | Parameter | Type | Default | Description |
|---------|-----------|------|---------|-------------|
| `brew_install` | `brew_cache_key` | string | `brew-v1` | Cache key (prefixed). The key is immutable |
| `brew_install` | `brew_dir` | string | `/opt/homebrew` | Local homebrew directory |
| `brew_install` | `cellar_dir` | string | `/opt/homebrew/Cellar` | Local cellar directory for brew casks |
| `brew_install` | `formula` | string | `""` | Homebrew formula to install if needed |
| `brew_install` | `reinstall` | boolean | `false` | Whether to reinstall the formula |
| `brew_install` | `with_cache` | boolean | `true` | Whether to restore and save cache between brew commands |
| `brew_install` | `post_steps` | steps | `[]` | Additional steps to run after brew install |
| `cache_spm` | `path` | string | `.build_output/SourcePackages` | Path where swift packages to be cached are located. Defaults to the Xcode-managed SourcePackages path; pure SPM packages must pass `path: .build` |
| `create_release_tag` | `version_source` | string | `git-describe` | How to determine the version number: `git-describe` increments patch from the latest tag, `marketing-version` reads `MARKETING_VERSION` from the Xcode project |
| `export_coverage` | `type` | enum | — | Coverage source: `spm` (→ `coverage.lcov`) or `xcode` (→ `coverage.xml`) |
| `export_coverage` | `result_bundle` | string | `TestResults.xcresult` | Path to the xcresult bundle (only used when `type` is `xcode`) |
| `install_tools` | `tools` | string | `xcodegen swiftlint` | Space-separated list of Homebrew formulas to install |
| `match_signing` | `type` | string | `appstore` | Comma-separated match types: development, adhoc, appstore, enterprise |
| `match_signing` | `readonly` | boolean | `false` | Whether to run match in read-only mode |
| `match_signing` | `app_identifier` | string | `""` | App bundle identifier. Leave empty to infer from Matchfile or `MATCH_APP_IDENTIFIER` |
| `notarize_macos` | `app_path` | string | — | Path to the `.app` bundle to notarize |
| `notarize_macos` | `api_key_path` | env_var_name | `ASC_KEY_PATH` | Env var name holding the path to the App Store Connect API key (`.p8`) |
| `notarize_macos` | `api_key_id` | env_var_name | `ASC_KEY_ID` | Env var name holding the App Store Connect API key ID |
| `notarize_macos` | `api_issuer_id` | env_var_name | `ASC_ISSUER_ID` | Env var name holding the App Store Connect API issuer ID |
| `notarize_macos` | `staple` | boolean | `true` | Whether to staple the notarization ticket to the app after a successful submission |
| `periphery_scan` | `config` | string | `""` | Path to a Periphery configuration file |
| `periphery_scan` | `strict` | boolean | `false` | Whether to fail the scan on any result (`--strict`) |
| `periphery_scan` | `extra_args` | string | `""` | Additional space-separated flags to pass to `periphery scan` |
| `restore_brew` | `brew_cache_key` | string | `brew-v1` | Cache key (prefixed). The key is immutable |
| `save_build_artifacts` | `gym_logs_path` | string | `~/Library/Logs/gym` | Path to Fastlane gym (build) logs |
| `setup` | `persist_workspace` | boolean | `true` | Whether the job should persist files to a workspace |
| `setup` | `workspace_root` | string | `.` | Either an absolute path or a path relative to `working_directory` |
| `swiftlint` | `strict` | boolean | `false` | Whether to use strict mode (warnings become errors) |
| `swiftlint` | `config` | string | `""` | Path to SwiftLint configuration file |
| `swiftlint` | `reporter` | string | `""` | Reporter type (`xcode`, `json`, `csv`, `emoji`, etc.) |
| `swiftformat` | `lint` | boolean | `true` | Whether to run in check-only mode (`--lint`, fails on unformatted files without changing them). Set to `false` to format in place |
| `swiftformat` | `config` | string | `""` | Path to a SwiftFormat configuration file |
| `swiftformat` | `paths` | string | `.` | Space-separated paths to format or lint |
| `upload_dsyms` | `dsym_path` | string | `.` | Directory searched for `.dSYM` files to upload |
| `upload_dsyms` | `sentry_org` | string | — | Sentry organization slug |
| `upload_dsyms` | `sentry_project` | string | — | Sentry project slug |
| `upload_dsyms` | `auth_token` | env_var_name | `SENTRY_AUTH_TOKEN` | Env var name holding the Sentry auth token |
| `upload_dsyms` | `skip_errors` | boolean | `false` | Whether an upload failure should be non-fatal to the pipeline |
| `upload_qlty_coverage` | `file` | string | `coverage.xml` | Path to the coverage file to upload |
| `upload_qlty_coverage` | `format` | enum | `""` | Coverage report format. Empty infers from the file extension or contents (`simplecov`, `clover`, `cobertura`, `coverprofile`, `lcov`, `jacoco`, `qlty`) |
| `upload_qlty_coverage` | `tag` | string | `""` | Optional tag for the coverage report (e.g. `unit`, `ui`) |
| `upload_qlty_coverage` | `token` | env_var_name | `QLTY_COVERAGE_TOKEN` | Env var name holding the Qlty coverage token |
| `upload_qlty_coverage` | `skip_errors` | boolean | `false` | Whether upload errors should be non-fatal to the pipeline |
| `xcodegen` | `spec` | string | `project.yml` | Path to the XcodeGen spec file |
| `xcodegen` | `quiet` | boolean | `true` | Whether to suppress XcodeGen output |

---

## Examples

See the [`src/examples/`](examples/) directory for complete workflow examples:

| Example | Description |
|---------|-------------|
| [`xcode_workflow.yml`](examples/xcode_workflow.yml) | **Recommended** — XcodeGen + SwiftLint, then the `test` job runs a Fastlane lane (scan) with Qlty coverage |
| [`full_workflow.yml`](examples/full_workflow.yml) | Fastlane PR + main workflows with `create_release_tag` |
| [`multi_platform.yml`](examples/multi_platform.yml) | One `test` job per Fastlane lane (`test_ios`, `test_macos`), shared setup workspace |
| [`run_tests.yml`](examples/run_tests.yml) | Simple Fastlane test runner |
| [`xcodegen_workflow.yml`](examples/xcodegen_workflow.yml) | Hand-rolled two-stage Fastlane workflow on the `macos` executor |
| [`spm_workflow.yml`](examples/spm_workflow.yml) | `build_and_test_spm` for pure Swift packages (no Fastfile) — debug test+coverage plus a release build |
| [`xcode_single_job_workflow.yml`](examples/xcode_single_job_workflow.yml) | `build_and_test_xcode` no-Fastfile path — XcodeGen + raw `xcodebuild` in one job |
| [`deploy_match_signing.yml`](examples/deploy_match_signing.yml) | Main-only deploy workflow: `match_signing` (read-only App Store profiles) then a Fastlane `beta` lane |
| [`pipeline_parameters_workflow.yml`](examples/pipeline_parameters_workflow.yml) | Threads a top-level pipeline parameter into `xcode_version` |
| [`matrix_destinations_workflow.yml`](examples/matrix_destinations_workflow.yml) | `matrix` build of `build_and_test_xcode` across macOS and iPhone 17 simulator destinations |

Fastlane is the preferred way to drive Xcode builds: `scan`/`gym` own the
xcresult bundle, JUnit output and signing, and the `test` job plugs straight
into `test_with_qlty`. The raw `xcodebuild` commands (`build_xcode`,
`test_xcode`, `build_and_test_xcode`) exist for projects without a Fastfile.

---

## Migration from v1

### Key changes in v2

1. **Orb reference**: Update `kevnm67/ios-orb@1.x.x` to `kevnm67/ios-orb@2.0.0`
2. **Executor defaults**: Xcode defaults to `26.6`, resource class to `m4pro.medium` (Apple Silicon)
3. **New commands**: `install_tools`, `xcodegen`, `swiftlint`, `match_signing` replace inline shell scripts
4. **SPM caching built-in**: The `setup` command auto-restores SPM caches when `xcode_project` is set

### Before (v1 inline config)

```yaml
jobs:
    test:
        macos:
            xcode: "15.4.0"
        resource_class: macos.m1.medium.gen1
        steps:
            - checkout
            - run: brew install xcodegen swiftlint
            - run: xcodegen generate
            - run: bundle install
            - run: bundle exec fastlane test
```

### After (v2 orb)

```yaml
orbs:
    ios: kevnm67/ios-orb@2.0.0
workflows:
    ci:
        jobs:
            - ios/run_with_setup:
                scripts:
                    - ios/install_tools:
                        tools: xcodegen swiftlint
                    - ios/xcodegen
                    - run: bundle exec fastlane test
```

### Migration checklist

- [ ] Update orb version to `@2.0.0`
- [ ] Remove inline `brew install` steps — use `ios/install_tools`
- [ ] Remove inline XcodeGen steps — use `ios/xcodegen`
- [ ] Remove inline SwiftLint steps — use `ios/swiftlint`
- [ ] Remove manual executor config — use `ios/macos` executor
- [ ] Set `xcode_project` parameter to enable automatic SPM caching
- [ ] Update resource class references (Silicon runners use `m4pro.medium`)

---

## Migration from v2 to v3

### Breaking changes in v3

1. **Orb reference**: Update `kevnm67/ios-orb@2.0.0` to `kevnm67/ios-orb@3.1.1`
2. **`test_with_code_climate` removed**: Code Climate's test reporter is end-of-life. Replace all uses with `test_with_qlty`.
3. **`test` job `cc_prefix` parameter removed**: The `cc_prefix` parameter no longer exists. Remove it from any `test` job invocations.
4. **`test` job new parameters**: `result_bundle_path`, `coverage_file`, `qlty_tag`, and `qlty_skip_errors` are the new coverage control parameters.
5. **`upload_qlty_coverage` new pass-through parameters**: `file`, `format`, `tag`, `token`, `skip_errors` replace the previous single-option call.
6. **`QLTY_COVERAGE_TOKEN` env var required**: Add `QLTY_COVERAGE_TOKEN` to your CircleCI project or context (obtain from qlty.sh project settings). Code Climate's `CC_TEST_REPORTER_ID` is no longer used.
7. **Flagship jobs added**: `build_and_test_xcode` and `build_and_test_spm` provide complete single-job CI for most projects.

### Before (v2 test job)

```yaml
orbs:
    ios: kevnm67/ios-orb@2.0.0
workflows:
    ci:
        jobs:
            - ios/test:
                xcode_project: MyApp
                lane: tests
                cc_prefix: MyApp
```

### After (v3 test job)

```yaml
orbs:
    ios: kevnm67/ios-orb@3.1.1
workflows:
    ci:
        jobs:
            - ios/test:
                xcode_project: MyApp
                lane: tests
                result_bundle_path: TestResults.xcresult
                coverage_file: coverage.xml
                qlty_tag: unit
```

### Before (v2 test_with_code_climate command)

```yaml
steps:
    - ios/test_with_code_climate:
        lane: tests
        cc_prefix: MyApp
```

### After (v3 test_with_qlty command)

```yaml
steps:
    - ios/test_with_qlty:
        lane: tests
        result_bundle_path: TestResults.xcresult
        coverage_file: coverage.xml
        qlty_tag: unit
```

### v2 → v3 migration checklist

- [ ] Update orb version to `@3.0.0`
- [ ] Replace `test_with_code_climate` → `test_with_qlty` in all commands
- [ ] Remove `cc_prefix` from `test` job invocations
- [ ] Add `result_bundle_path`, `coverage_file` to `test` job as needed
- [ ] Add `QLTY_COVERAGE_TOKEN` to CircleCI context (qlty.sh project settings)
- [ ] Remove `CC_TEST_REPORTER_ID` from CircleCI contexts/env vars
- [ ] For single-job Xcode pipelines consider switching to `build_and_test_xcode`
- [ ] For SPM packages consider switching to `build_and_test_spm`

---

## What's new in v3.1

- **Xcode 26.6 default** (Swift 6.3.3, iOS 26.5 runtime, macOS 26.5.1) for the executor and every job; the 26.3.0 image remains selectable via `xcode_version`.
- **`setup` Ruby default is now `3.3`** (v3.1.1; v3.1.0 briefly defaulted to 3.4, which breaks Fastlane setups) — the 26.x images ship rbenv Rubies 3.3 / 3.4 / 4.0 only, so the previous `3.2` default no longer resolves.
- **Bundled orbs bumped** to `circleci/macos@3.0.0`, `circleci/ruby@3.0.0`, `qltysh/qlty-orb@0.1.2`.
- **`build_and_test_spm` cache key** now goes through `restore_spm_cache` / `cache_spm`, so packages without a `Package.resolved` (no dependencies) no longer fail on `checksum`.
- **`brew_install` defaults** use the Apple Silicon Homebrew prefix (`/opt/homebrew`).
- **New parameters**: `test_xcode.junit_report`, `test_spm.report_path`.
- All `xcodebuild` / `swift build` / `swift test` logic moved from inline YAML into unit-tested `src/scripts/*.sh` (behaviour unchanged; `pipefail` now fails the step when the underlying build fails instead of being masked by `xcbeautify`).
