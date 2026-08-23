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
    - [build\_xcode / test\_xcode](#build_xcode--test_xcode)
    - [build\_spm / test\_spm](#build_spm--test_spm)
    - [create\_release\_tag](#create_release_tag)
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
    ios: kevnm67/ios-orb@3.1.1

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

Apple Silicon macOS executor with Xcode and Homebrew pre-configured. The
default image is Xcode 26.6 (Swift 6.3, iOS 26.5 simulators, macOS 26.5);
see CircleCI's [supported Xcode versions](https://circleci.com/docs/guides/execution-managed/using-macos/#supported-xcode-versions-silicon).

| Parameter | Default | Description |
|-----------|---------|-------------|
| `xcode_version` | `26.6` | Xcode version (CircleCI image tag, e.g. `26.6`, `26.5`, `27.0` beta) |
| `resource_class` | `m4pro.medium` | macOS resource class (`m4pro.medium` or `m4pro.large`) |

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

### `build_xcode` / `test_xcode`

Fallback for projects **without a Fastfile**: build and test with raw
`xcodebuild`, piped through `xcbeautify`. `test_xcode` enables code coverage,
writes the xcresult bundle and stores a JUnit report for CircleCI Test
Insights. Fastlane projects should use [`lane`](#lane) / the [`test`](#test)
job instead — `scan` produces the xcresult and JUnit output natively.

```yaml
steps:
    - ios/build_xcode:
        scheme: MyApp
        destination: "platform=iOS Simulator,name=iPhone 17"
    - ios/test_xcode:
        scheme: MyApp
        destination: "platform=iOS Simulator,name=iPhone 17"
        result_bundle_path: TestResults.xcresult
```

### `build_spm` / `test_spm`

Build and test a Swift package. `test_spm` runs with coverage and `--parallel`
by default and stores a JUnit report from `build/reports`.

```yaml
steps:
    - ios/build_spm:
        configuration: release
        build_flags: -Xswiftc -warnings-as-errors
    - ios/test_spm:
        filter: MyModuleTests
```

### `create_release_tag`

Create and push the next `vX.Y.Z` tag — patch-increment of the latest tag
(`git-describe`) or read from the project's `MARKETING_VERSION`.

```yaml
steps:
    - ios/create_release_tag:
        version_source: marketing-version
```

### `brew_install`

Install a Homebrew formula with optional caching.

### `cache_spm` / `restore_spm_cache`

Cache and restore Swift Package Manager dependencies. The cache checksum keys
on `<xcode_project>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
when `xcode_project` is set, and falls back to the root `Package.resolved` for
pure SPM packages (leave `xcode_project` empty).

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

Export code coverage for upload. `type: spm` (`llvm-cov`) writes lcov to
`coverage.lcov`; `type: xcode` (`xcresultparser`) writes cobertura XML to
`coverage.xml`. Pass the matching `file`/`format` to `upload_qlty_coverage`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | enum | — | Coverage source: `spm` (→ `coverage.lcov`) or `xcode` (→ `coverage.xml`) |
| `result_bundle` | string | `TestResults.xcresult` | Path to xcresult bundle (Xcode only) |

```yaml
steps:
    - ios/export_coverage:
        type: xcode
        result_bundle: TestResults.xcresult

    # SPM packages export lcov — upload with format: lcov
    - ios/export_coverage:
        type: spm
    - ios/upload_qlty_coverage:
        file: coverage.lcov
        format: lcov
```

---

## Jobs

### `run_with_setup`

Generic job: checkout → setup → run your scripts → save artifacts.

```yaml
jobs:
    - ios/run_with_setup:
        xcode_version: "26.6"
        scripts:
            - run: bundle exec fastlane build
```

### `test`

**Preferred job for Fastlane projects.** Runs a lane (typically `scan`),
exports cobertura from the xcresult bundle and uploads coverage to Qlty Cloud.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.6` | Xcode version |
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

Complete single-job CI for Xcode projects that **do not use Fastlane**.
Optionally runs XcodeGen, builds, tests, exports coverage, and uploads to
Qlty Cloud. Fastlane projects: prefer `run_with_setup` + the `test` job.

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

```yaml
jobs:
    - ios/build_and_test_xcode:
        scheme: MyApp
        xcode_version: "26.6"
        destination: "platform=iOS Simulator,name=iPhone 17"
        xcodegen: true
        xcode_project: MyApp
        qlty: true
```

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

```yaml
jobs:
    - ios/build_and_test_spm:
        xcode_version: "26.6"
        qlty: true
```

---

## Workflow Examples

### PR workflow with XcodeGen

```yaml
version: 2.1

orbs:
    ios-orb: kevnm67/ios-orb@3.1.1

workflows:
    pr:
        when:
            not:
                equal: [main, << pipeline.git.branch >>]
        jobs:
            - ios-orb/run_with_setup:
                name: setup
                xcode_version: 26.6
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
                xcode_version: 26.6
                xcode_project: MyApp
                lane: test
                requires:
                    - setup
```

---

## Orb Dependencies

- `circleci/macos@3.0.0`
- `circleci/ruby@3.0.0`
- `qltysh/qlty-orb@0.1.2`

---

## Resources

- [Orb Registry](https://circleci.com/developer/orbs/orb/kevnm67/ios-orb)
- [CircleCI Orb Docs](https://circleci.com/docs/orb-intro/)
- [Qlty Coverage Orb](https://circleci.com/developer/orbs/orb/qltysh/qlty-orb)

## Contributing

[Issues](https://github.com/kevnm67/ios-orb/issues) and
[pull requests](https://github.com/kevnm67/ios-orb/pulls) welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md) for the dev workflow and
[CHANGELOG.md](CHANGELOG.md) for release history.

## Publishing

1. Merge to `main` using [Conventional Commits](https://conventionalcommits.org/)
2. Push a [semver tag](https://semver.org/) (e.g. `v3.1.0`)
3. CircleCI (`.circleci/test-deploy.yml`, `orb-publishing` context) publishes to the orb registry
4. `.github/workflows/release-on-tag.yml` creates the matching GitHub Release with generated notes

[orb_registry]: https://circleci.com/developer/orbs/orb/kevnm67/ios-orb
[orb_badge]: https://badges.circleci.com/orbs/kevnm67/ios-orb.svg
[qlty-orb]: https://circleci.com/developer/orbs/orb/qltysh/qlty-orb
