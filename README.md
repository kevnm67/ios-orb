# iOS Orb

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/kevnm67/ios-orb/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/kevnm67/ios-orb/tree/main)
[![CircleCI Orb Version][orb_badge]][orb_registry]
[![Maintainability](https://qlty.sh/badges/f5e5400a-92d0-4f83-82e8-640bd86fb9ee/maintainability.svg)](https://qlty.sh/gh/kevnm67/projects/ios-orb)
[![Code Coverage](https://qlty.sh/badges/f5e5400a-92d0-4f83-82e8-640bd86fb9ee/coverage.svg)](https://qlty.sh/gh/kevnm67/projects/ios-orb)

A CircleCI orb for iOS CI/CD pipelines — reusable commands, jobs,
and executors for building, testing, and deploying iOS/macOS apps.

**📦 [kevnm67/ios-orb on the CircleCI Orb Registry][orb_registry]**

---

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Executor](#executor)
- [Commands](#commands)
  - [setup](#setup)
  - [lane](#lane)
  - [xcodegen](#xcodegen)
  - [install\_tools](#install_tools)
  - [swiftlint](#swiftlint)
  - [match\_signing](#match_signing)
  - [brew\_install](#brew_install)
  - [cache\_spm / restore\_spm\_cache](#cache_spm--restore_spm_cache)
  - [save\_build\_artifacts](#save_build_artifacts)
  - [test\_with\_qlty](#test_with_qlty)
  - [upload\_qlty\_coverage](#upload_qlty_coverage)
  - [export\_coverage](#export_coverage)
- [Jobs](#jobs)
  - [run\_with\_setup](#run_with_setup)
  - [test](#test)
  - [build\_and\_test\_xcode](#build_and_test_xcode)
  - [build\_and\_test\_spm](#build_and_test_spm)
- [Workflow Examples](#workflow-examples)
- [Orb Dependencies](#orb-dependencies)
- [Resources](#resources)
- [Contributing](#contributing)
- [Publishing](#publishing)

---

## Quick Start

```yaml
version: 2.1

orbs:
  ios: kevnm67/ios-orb@3.0.0

workflows:
  build-test:
    jobs:
      - ios/run_with_setup:
          name: test
          scripts:
            - run: bundle exec fastlane test
```

---

## Architecture

![ios-orb architecture](docs/architecture/orb_pipeline.svg)

---

## Executor

### `macos`

macOS executor with Xcode and Homebrew pre-configured.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `xcode_version` | `26.3.0` | Xcode version |
| `resource_class` | `m4pro.medium` | macOS resource class |

Sets `HOMEBREW_NO_AUTO_UPDATE=1` and `HOMEBREW_NO_INSTALL_CLEANUP=1`.

---

## Commands

### `setup`

Initialize build environment: checkout, workspace, Ruby/Bundler, SPM cache.

```yaml
steps:
  - ios/setup:
      checkout: true
      bundle_install: true
      persist_workspace: true
```

### `lane`

Run a Fastlane lane.

```yaml
steps:
  - ios/lane:
      named: test
```

### `xcodegen`

Install XcodeGen and generate the Xcode project.

```yaml
steps:
  - ios/xcodegen:
      spec: project.yml
      quiet: true
```

### `install_tools`

Install Homebrew tools (only if missing).

```yaml
steps:
  - ios/install_tools:
      tools: xcodegen swiftlint xcresultparser
```

### `swiftlint`

Run SwiftLint with optional strict mode.

```yaml
steps:
  - ios/swiftlint:
      strict: true
```

### `match_signing`

Sync code signing via Fastlane match. Supports multiple types in a single step.

```yaml
steps:
  - ios/match_signing:
      type: "adhoc,appstore"
      readonly: false
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `type` | `appstore` | Comma-separated match types |
| `readonly` | `false` | Run match in read-only mode |
| `app_identifier` | `""` | Bundle ID (inferred from Matchfile if empty) |

### `brew_install`

Install a Homebrew formula with optional caching.

### `cache_spm` / `restore_spm_cache`

Cache and restore Swift Package Manager dependencies.

### `save_build_artifacts`

Store build logs, diagnostics, and test results as artifacts.

### `test_with_qlty`

Run tests and upload coverage to Qlty Cloud. Successor to the removed
`test_with_code_climate` command.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lane` | string | `""` | Fastlane lane to run |
| `pretest_steps` | steps | `[]` | Steps to run before tests |
| `test_steps` | steps | `[]` | Steps that execute tests (non-Fastlane) |
| `xcode_project` | string | `""` | Project name for SPM cache key |
| `result_bundle_path` | string | `TestResults.xcresult` | Path to xcresult bundle |
| `coverage_file` | string | `coverage.xml` | Exported cobertura XML path |
| `qlty_tag` | string | `""` | Optional Qlty coverage tag (e.g. `unit`, `ui`) |
| `qlty_skip_errors` | boolean | `false` | Make Qlty upload errors non-fatal |

```yaml
steps:
  - ios/test_with_qlty:
      lane: tests
      result_bundle_path: TestResults.xcresult
      coverage_file: coverage.xml
      qlty_tag: unit
      qlty_skip_errors: false
```

### `upload_qlty_coverage`

Upload a coverage file to Qlty Cloud via the official `qltysh/qlty-orb`.
Requires the `QLTY_COVERAGE_TOKEN` environment variable (project or workspace
token from Qlty's settings).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | `coverage.xml` | Path to coverage file |
| `format` | enum | `""` | Report format (`cobertura`, `lcov`, `clover`, `jacoco`, `simplecov`, `coverprofile`, `qlty`, or auto-detect) |
| `tag` | string | `""` | Optional coverage report tag |
| `token` | env_var_name | `QLTY_COVERAGE_TOKEN` | Env var holding the Qlty token |
| `skip_errors` | boolean | `false` | Make upload errors non-fatal |

```yaml
steps:
  - ios/upload_qlty_coverage:
      file: coverage.xml
      format: cobertura
      tag: unit
      skip_errors: false
```

### `export_coverage`

Export code coverage to cobertura-compatible XML. Supports both SPM
(`llvm-cov`) and Xcode (`xcresultparser`) coverage sources.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | enum | — | Coverage source: `spm` or `xcode` |
| `result_bundle` | string | `TestResults.xcresult` | Path to xcresult bundle (Xcode only) |

```yaml
steps:
  - ios/export_coverage:
      type: xcode
      result_bundle: TestResults.xcresult
```

---

## Jobs

### `run_with_setup`

Generic job: checkout → setup → run your scripts → save artifacts.

```yaml
jobs:
  - ios/run_with_setup:
      xcode_version: "26.3.0"
      scripts:
        - run: bundle exec fastlane build
```

### `test`

Run tests via a fastlane lane and upload coverage to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.3.0` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `checkout` | boolean | `true` | Checkout source code |
| `attach_workspace` | boolean | `true` | Attach to existing workspace |
| `xcode_project` | string | `""` | Project name (SPM cache key) |
| `with_spm` | boolean | `false` | Setup environment for SPM packages |
| `homebrew_no_auto_update` | integer | `1` | Disable Homebrew auto-update |
| `logs_path` | string | `~/Library/Logs/scan` | Path to scan logs |
| `build_logs_path` | string | `~/Library/Logs/DiagnosticReports/` | Path to diagnostic reports |
| `test_output_path` | string | `./fastlane/test_output` | Path to test output |
| `result_bundle_path` | string | `TestResults.xcresult` | Path to xcresult bundle |
| `coverage_file` | string | `coverage.xml` | Exported cobertura XML path |
| `qlty_tag` | string | `""` | Optional Qlty coverage tag |
| `qlty_skip_errors` | boolean | `false` | Make Qlty upload errors non-fatal |
| `pretest_steps` | steps | `[]` | Steps to run before tests |
| `test_steps` | steps | `[]` | Steps to execute tests (non-Fastlane) |
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

```yaml
jobs:
  - ios/build_and_test_xcode:
      scheme: MyApp
      xcode_version: "26.3.0"
      destination: "platform=iOS Simulator,name=iPhone 16"
      xcodegen: true
      xcode_project: MyApp
      qlty: true
```

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

```yaml
jobs:
  - ios/build_and_test_spm:
      xcode_version: "26.3.0"
      qlty: true
```

---

## Workflow Examples

### PR workflow with XcodeGen

```yaml
version: 2.1

orbs:
  ios-orb: kevnm67/ios-orb@3.0.0

workflows:
  pr:
    when:
      not:
        equal: [main, << pipeline.git.branch >>]
    jobs:
      - ios-orb/run_with_setup:
          name: setup
          xcode_version: 26.3.0
          xcode_project: MyApp
          scripts:
            - ios-orb/install_tools:
                tools: xcodegen swiftlint
            - ios-orb/xcodegen
      - ios-orb/run_with_setup:
          name: lint
          attach_workspace: true
          checkout: false
          scripts:
            - ios-orb/swiftlint:
                strict: true
          requires:
            - setup
      - ios-orb/test:
          name: test
          xcode_version: 26.3.0
          xcode_project: MyApp
          lane: test
          requires:
            - setup
```

---

## Orb Dependencies

- `circleci/macos@2.5.2`
- `circleci/ruby@2.6.0`
- `qltysh/qlty-orb@0.1.1`

---

## Resources

- [Orb Registry](https://circleci.com/developer/orbs/orb/kevnm67/ios-orb)
- [CircleCI Orb Docs](https://circleci.com/docs/orb-intro/)
- [Qlty Coverage Orb](https://circleci.com/developer/orbs/orb/qltysh/qlty-orb)

## Contributing

[Issues](https://github.com/kevnm67/ios-orb/issues) and
[pull requests](https://github.com/kevnm67/ios-orb/pulls) welcome.

## Publishing

1. Merge to `main` using [Conventional Commits](https://conventionalcommits.org/)
2. Create a [semver tag](http://semver.org/) release on GitHub (e.g. `v3.0.1`)
3. The CI pipeline (`release-on-tag` workflow) publishes to the orb registry automatically
4. A GitHub Release is auto-created from the tag — releases default to **PATCH** version bumps

[orb_registry]: https://circleci.com/developer/orbs/orb/kevnm67/ios-orb
[orb_badge]: https://badges.circleci.com/orbs/kevnm67/ios-orb.svg
[qlty-orb]: https://circleci.com/developer/orbs/orb/qltysh/qlty-orb
