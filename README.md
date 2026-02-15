# iOS Orb

[![CircleCI][circleci_main]][circle_project]
[![CircleCI Orb Version][orb_badge]][orb_registry]

A CircleCI orb for iOS CI/CD pipelines — reusable commands, jobs,
and executors for building, testing, and deploying iOS/macOS apps.

## Quick Start

```yaml
version: 2.1

orbs:
  ios: kevnm67/ios-orb@1.0.0

workflows:
  build-test:
    jobs:
      - ios/run_with_setup:
          name: test
          scripts:
            - run: bundle exec fastlane test
```

## Executor

### `macos`

macOS executor with Xcode and Homebrew pre-configured.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `xcode_version` | `26.3.0` | Xcode version |
| `resource_class` | `m4pro.medium` | macOS resource class |

Sets `HOMEBREW_NO_AUTO_UPDATE=1` and `HOMEBREW_NO_INSTALL_CLEANUP=1`.

## Commands

### `setup`

Initialize build environment: checkout, workspace, Ruby/Bundler, SPM
cache.

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

Sync code signing via Fastlane match. Supports multiple types in a
single step.

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

### `test_with_code_climate`

> **Legacy** — consider using [qlty-orb] for coverage instead.

Run tests with Code Climate coverage reporting.

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

Run tests with Code Climate coverage (legacy).

## Workflow Examples

### PR workflow with XcodeGen

```yaml
version: 2.1

orbs:
  ios: kevnm67/ios-orb@1.0.0

jobs:
  setup:
    executor:
      name: ios/macos
    steps:
      - checkout
      - ios/install_tools:
          tools: xcodegen swiftlint
      - ios/xcodegen
      - run: |
          bundle config set --local path vendor/bundle
          bundle install
      - persist_to_workspace:
          root: .
          paths: [.]

  test:
    executor:
      name: ios/macos
    steps:
      - attach_workspace:
          at: .
      - ios/lane:
          named: test
      - ios/save_build_artifacts

  lint:
    executor:
      name: ios/macos
    steps:
      - attach_workspace:
          at: .
      - ios/swiftlint:
          strict: true

workflows:
  pr:
    jobs:
      - setup
      - test:
          requires: [setup]
      - lint:
          requires: [setup]
```

## Orb Dependencies

- `circleci/macos@2.5.2`
- `circleci/ruby@2.6.0`

## Resources

- [Orb Registry](https://circleci.com/orbs/registry/orb/kevnm67/ios-orb)
- [CircleCI Orb Docs](https://circleci.com/docs/orb-intro/)

## Contributing

[Issues](https://github.com/kevnm67/ios-orb/issues) and
[pull requests](https://github.com/kevnm67/ios-orb/pulls) welcome.

## Publishing

1. Merge to main using
   [Conventional Commits](https://conventionalcommits.org/)
2. Create a [semver tag](http://semver.org/) release on GitHub
3. The CI pipeline publishes automatically

[circle_project]: https://dl.circleci.com/status-badge/redirect/gh/kevnm67/ios-orb/tree/main
[circleci_main]: https://dl.circleci.com/status-badge/img/gh/kevnm67/ios-orb/tree/main.svg?style=svg
[orb_registry]: https://circleci.com/orbs/registry/orb/kevnm67/ios-orb
[orb_badge]: https://badges.circleci.com/orbs/kevnm67/ios-orb.svg
[qlty-orb]: https://circleci.com/developer/orbs/orb/qltysh/qlty-orb
