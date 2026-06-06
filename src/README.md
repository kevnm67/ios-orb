# ios-orb

[![CircleCI Orb](https://img.shields.io/badge/CircleCI-ios--orb-blue.svg)](https://circleci.com/developer/orbs/orb/kevnm67/ios-orb)

A CircleCI orb for iOS and macOS CI/CD. Provides reusable jobs, commands, and executors for building, testing, linting, and deploying Swift projects — SPM packages, XcodeGen-based apps, and standard Xcode projects.

---

## Table of Contents

- [Quick Start: SPM Package](#quick-start-spm-package)
- [Quick Start: XcodeGen Project](#quick-start-xcodegen-project)
- [Executor](#executor)
- [Jobs Reference](#jobs-reference)
- [Commands Reference](#commands-reference)
- [Examples](#examples)
- [Migration from v1](#migration-from-v1)
- [Migration from v2 to v3](#migration-from-v2-to-v3)

---

## Quick Start: SPM Package

```yaml
version: 2.1
orbs:
  ios: kevnm67/ios-orb@3.0.0
workflows:
  ci:
    jobs:
      - ios/build_and_test_spm:
          xcode_version: "26.3.0"
          qlty: true
```

## Quick Start: XcodeGen Project

```yaml
version: 2.1
orbs:
  ios: kevnm67/ios-orb@3.0.0
workflows:
  ci:
    jobs:
      - ios/run_with_setup:
          xcode_version: "26.3.0"
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
| `xcode_version` | string | `26.3.0` | Xcode version to use. See [supported versions](https://circleci.com/docs/testing-ios/#supported-xcode-versions). |
| `resource_class` | string | `m4pro.medium` | macOS resource class. |

---

## Jobs Reference

### `run_with_setup`

General-purpose job: checkout, attach workspace, run custom scripts, save artifacts.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.3.0` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `checkout` | boolean | `true` | Checkout source code |
| `attach_workspace` | boolean | `true` | Attach to existing workspace |
| `xcode_project` | string | `""` | Xcode project name (for SPM cache key) |
| `homebrew_no_auto_update` | integer | `1` | Disable Homebrew auto-update (1=yes) |
| `logs_path` | string | `~/Library/Logs/scan` | Path to scan logs |
| `build_logs_path` | string | `~/Library/Logs/DiagnosticReports/` | Path to diagnostic reports |
| `test_output_path` | string | `./fastlane/test_output` | Path to test output |
| `scripts` | steps | `[]` | Custom steps to run |

### `test`

Run tests via a fastlane lane and upload coverage to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.3.0` | Xcode version |
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

### `build_and_test_xcode`

Complete CI job for Xcode projects. Optionally runs XcodeGen, builds,
tests, exports coverage, and uploads to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scheme` | string | — | Xcode scheme to build and test |
| `xcode_version` | string | `26.3.0` | Xcode version |
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

### `build_and_test_spm`

Complete CI job for Swift Package Manager projects. Builds, tests, exports
coverage, and optionally uploads to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.3.0` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `parallelism` | integer | `1` | CircleCI parallelism level |
| `coverage` | boolean | `true` | Export code coverage |
| `qlty` | boolean | `true` | Upload coverage to Qlty Cloud |
| `build_flags` | string | `""` | Additional flags for `swift build` |
| `configuration` | string | `debug` | Build configuration (`debug` or `release`) |
| `filter` | string | `""` | Test filter pattern |
| `pre_steps` | steps | `[]` | Steps to run before build |

---

## Commands Reference

| Command | Description | Key Parameters |
|---------|-------------|----------------|
| `setup` | Checkout, attach workspace, install Ruby gems, restore caches | `checkout`, `attach_workspace`, `bundle_install`, `ruby_version`, `xcode_project`, `with_spm`, `scripts` |
| `install_tools` | Install Homebrew formulas (skips already-installed) | `tools` (space-separated, default: `xcodegen swiftlint`) |
| `xcodegen` | Install XcodeGen and generate the Xcode project | `spec` (default: `project.yml`), `quiet` |
| `swiftlint` | Install and run SwiftLint | `strict`, `config`, `reporter` |
| `lane` | Run a Fastlane lane | `named` |
| `match_signing` | Sync code signing via Fastlane Match | `type` (default: `appstore`), `readonly`, `app_identifier` |
| `brew_install` | Install a Homebrew formula with caching | `formula`, `reinstall`, `with_cache` |
| `cache_spm` | Save SPM package cache | `key`, `xcode_project`, `path` |
| `restore_spm_cache` | Restore SPM package cache | `key`, `xcode_project` |
| `save_build_artifacts` | Store build logs and test results | `logs_path`, `build_logs_path`, `test_output_path` |
| `test_with_qlty` | Run tests and upload coverage to Qlty Cloud | `lane`, `pretest_steps`, `test_steps`, `result_bundle_path`, `coverage_file`, `qlty_tag`, `qlty_skip_errors`, `xcode_project` |
| `upload_qlty_coverage` | Upload a coverage file to Qlty Cloud | `file`, `format`, `tag`, `token`, `skip_errors` |
| `export_coverage` | Export coverage to cobertura XML | `type` (`spm` or `xcode`), `result_bundle` |

---

## Examples

See the [`src/examples/`](examples/) directory for complete workflow examples:

| Example | Description |
|---------|-------------|
| [`spm_workflow.yml`](examples/spm_workflow.yml) | Minimal SPM package build + test + coverage |
| [`xcode_workflow.yml`](examples/xcode_workflow.yml) | XcodeGen project build + test + coverage |
| [`full_workflow.yml`](examples/full_workflow.yml) | PR + main workflows with release tagging |
| [`multi_platform.yml`](examples/multi_platform.yml) | iOS + macOS dual-platform testing |
| [`run_tests.yml`](examples/run_tests.yml) | Simple Fastlane test runner |
| [`xcodegen_workflow.yml`](examples/xcodegen_workflow.yml) | Full XcodeGen + test + deploy |

---

## Migration from v1

### Key changes in v2

1. **Orb reference**: Update `kevnm67/ios-orb@1.x.x` to `kevnm67/ios-orb@2.0.0`
2. **Executor defaults**: Xcode defaults to `26.3.0`, resource class to `m4pro.medium` (Apple Silicon)
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

1. **Orb reference**: Update `kevnm67/ios-orb@2.0.0` to `kevnm67/ios-orb@3.0.0`
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
  ios: kevnm67/ios-orb@3.0.0
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
