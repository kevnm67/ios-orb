# ios-orb

[![CircleCI Orb](https://img.shields.io/badge/CircleCI-ios--orb-blue.svg)](https://circleci.com/developer/orbs/orb/kevnm67/ios-orb)

A CircleCI orb for iOS and macOS CI/CD. Provides reusable jobs, commands, and executors for building, testing, linting, and deploying Swift projects -- SPM packages, XcodeGen-based apps, and standard Xcode projects.

---

## Table of Contents

- [Quick Start: SPM Package](#quick-start-spm-package)
- [Quick Start: XcodeGen Project](#quick-start-xcodegen-project)
- [Executor](#executor)
- [Jobs Reference](#jobs-reference)
- [Commands Reference](#commands-reference)
- [Examples](#examples)
- [Migration from v1](#migration-from-v1)

---

## Quick Start: SPM Package

```yaml
version: 2.1
orbs:
  ios: kevnm67/ios-orb@2.0.0
workflows:
  ci:
    jobs:
      - ios/run_with_setup:
          xcode_version: "26.3.0"
          scripts:
            - run: swift build
            - run: swift test
```

## Quick Start: XcodeGen Project

```yaml
version: 2.1
orbs:
  ios: kevnm67/ios-orb@2.0.0
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

Test job with Qlty Cloud coverage integration (Code Climate's successor).

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
| `result_bundle_path` | string | `TestResults.xcresult` | xcresult bundle from the test run |
| `coverage_file` | string | `coverage.xml` | Exported cobertura XML uploaded to Qlty |
| `qlty_tag` | string | `""` | Optional Qlty coverage tag |
| `pretest_steps` | steps | `[]` | Steps to run before tests |
| `test_steps` | steps | `[]` | Steps to run during test phase |
| `lane` | string | `""` | Fastlane lane to execute |
| `scripts` | steps | `[]` | Setup workspace scripts |

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
| `test_with_qlty` | Run tests and upload coverage to Qlty Cloud | `lane`, `pretest_steps`, `test_steps`, `result_bundle_path`, `coverage_file`, `qlty_tag`, `xcode_project` |

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
- [ ] Remove inline `brew install` steps -- use `ios/install_tools`
- [ ] Remove inline XcodeGen steps -- use `ios/xcodegen`
- [ ] Remove inline SwiftLint steps -- use `ios/swiftlint`
- [ ] Remove manual executor config -- use `ios/macos` executor
- [ ] Set `xcode_project` parameter to enable automatic SPM caching
- [ ] Update resource class references (Silicon runners use `m4pro.medium`)
