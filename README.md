# iOS Orb

| Badges  | Insights |
| ------------- | ------------- |
| [![CircleCI][circleci_main]][circle_project] | [![CircleCI][insights]][insights_snapshot] |
| [![Maintainability][maintainability_badge]][maintainability] | |
| [![Test Coverage][test_coverage_badge]][test_coverage] | |

A CircleCI orb for iOS development that provides reusable commands, jobs, and executors for building, testing, and deploying iOS applications.

## Features

- macOS executor with configurable Xcode version and resource class
- Ruby/Bundler setup with caching
- Swift Package Manager (SPM) caching
- Homebrew formula installation with caching
- Code Climate test coverage integration
- Fastlane lane execution
- Build artifact storage

## Requirements

- CircleCI account with macOS execution environment access
- Xcode project or workspace

## Usage

Add the orb to your `.circleci/config.yml`:

```yaml
version: 2.1

orbs:
    ios: kevnm67/ios-orb@1.0.0

workflows:
    build-test:
        jobs:
            - ios/run_with_setup:
                  name: build_and_test
                  scripts:
                      - run: bundle exec fastlane test
```

## Executors

### macos

macOS executor with Xcode support.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.2.0` | Xcode version to use |
| `resource_class` | string | `m4pro.medium` | macOS resource class |

```yaml
jobs:
    build:
        executor:
            name: ios/macos
            xcode_version: "26.2.0"
            resource_class: m4pro.medium
```

## Jobs

### run_with_setup

Run scripts or commands with automatic environment setup including checkout, workspace attachment, Ruby/Bundler installation, and SPM cache restoration.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.2.0` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `checkout` | boolean | `true` | Whether to checkout code |
| `attach_workspace` | boolean | `true` | Whether to attach workspace |
| `scripts` | steps | `[]` | Steps to run after setup |
| `xcode_project` | string | `""` | Xcode project name for SPM cache |

### test

Run tests with Code Climate coverage reporting.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xcode_version` | string | `26.2.0` | Xcode version |
| `resource_class` | string | `m4pro.medium` | macOS resource class |
| `lane` | string | `""` | Fastlane lane to run |
| `pretest_steps` | steps | `[]` | Steps before testing |
| `test_steps` | steps | `[]` | Custom test steps |

## Commands

### setup

Initialize the build environment with checkout, workspace attachment, Ruby installation, and dependency caching.

### lane

Execute a Fastlane lane.

```yaml
steps:
    - ios/lane:
          named: test
```

### brew_install

Install Homebrew formulas with optional caching.

### cache_spm / restore_spm_cache

Cache and restore Swift Package Manager dependencies.

### save_build_artifacts

Store build logs, diagnostic reports, and test results as CircleCI artifacts.

## Orb Dependencies

This orb uses the following CircleCI orbs:

- `circleci/macos@2.5.2` - macOS utilities
- `circleci/ruby@2.6.0` - Ruby installation and caching

## Resources

- [CircleCI Orb Registry](https://circleci.com/orbs/registry/orb/kevnm67/ios-orb) - Official registry page
- [CircleCI Orb Docs](https://circleci.com/docs/orb-intro/) - Documentation for using and creating orbs

## Contributing

We welcome [issues](https://github.com/kevnm67/ios-orb/issues) and [pull requests](https://github.com/kevnm67/ios-orb/pulls)!

## Publishing Updates

1. Merge pull requests with desired changes to the main branch
    - Use [Conventional Commit Messages](https://conventionalcommits.org/) for best experience
2. Check the current version: `circleci orb info kevnm67/ios-orb | grep "Latest"`
3. Create a [new Release](https://github.com/kevnm67/ios-orb/releases/new) on GitHub
    - Create a [semantically versioned](http://semver.org/) tag (e.g., v1.0.0)
4. Click "Auto-generate release notes"
5. Verify the version tag is semantically accurate
6. Click "Publish Release" to trigger the publishing pipeline

[circle_project]: https://dl.circleci.com/status-badge/redirect/gh/kevnm67/ios-orb/tree/main
[circleci_main]: https://dl.circleci.com/status-badge/img/gh/kevnm67/ios-orb/tree/main.svg?style=svg

[insights_snapshot]: https://circleci.com/orbs/registry/orb/kevnm67/ios-orb
[insights]: https://badges.circleci.com/orbs/kevnm67/ios-orb.svg

[maintainability]: https://codeclimate.com/github/kevnm67/ios-orb/maintainability
[maintainability_badge]: https://api.codeclimate.com/v1/badges/1cfc2fcff5164444fd22/maintainability

[test_coverage]: https://codeclimate.com/github/kevnm67/ios-orb/test_coverage
[test_coverage_badge]: https://api.codeclimate.com/v1/badges/1cfc2fcff5164444fd22/test_coverage
