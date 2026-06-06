# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`kevnm67/ios-orb` — a CircleCI orb for iOS/macOS CI/CD (SPM packages, XcodeGen apps, standard Xcode projects). The orb is authored in **unpacked form** under `src/` and packed/published by CircleCI's `orb-tools` pipeline. The root `orb.yml` is a packed snapshot, not the source of truth — **edit `src/`, never the packed file**.

## Commands

```bash
# Run all bash script tests (bats); kcov not required locally
bats tests/scripts

# Run a single test file
bats tests/scripts/swiftlint_run.bats

# Run a single test by name
bats tests/scripts/swiftlint_run.bats -f "adds --strict"

# CI-equivalent test run with kcov coverage → coverage/cobertura.xml (Linux/CI)
./scripts/ci/run-script-tests.sh

# Pack + validate the orb locally (writes src/ios.yml — do not commit it)
cd src && ./pack.sh

# Validate any CircleCI config
circleci config validate .circleci/config.yml

# Lint (yamllint config in .yamllint, 4-space mappings enforced by yamlfmt)
pre-commit run --all-files
```

## Architecture

Standard CircleCI unpacked-orb layout — `circleci config pack src` assembles `src/@orb.yml` (header: description, display, bundled orbs `circleci/macos`, `circleci/ruby`, `qltysh/qlty-orb`) with one YAML file per component:

- `src/executors/macos.yml` — the single executor (Apple Silicon, Xcode `26.3.0` / `m4pro.medium` defaults)
- `src/commands/*.yml` — one file per command (setup, lane, xcodegen, swiftlint, match_signing, SPM caching, coverage export, Qlty upload, …)
- `src/jobs/*.yml` — `run_with_setup`, `test`, `build_and_test_xcode`, `build_and_test_spm`
- `src/examples/*.yml` — usage examples published with the orb
- `src/scripts/*.sh` — **all real shell logic lives here**, pulled into commands via `<< include(scripts/foo.sh) >>`. Commands pass orb parameters to scripts as environment variables (e.g. `SWIFTLINT_STRICT`), never by interpolating into the script body.

### Testing model

Two layers:

1. **bats unit tests** (`tests/scripts/*.bats`) — one bats file per `src/scripts/*.sh`. External binaries (xcodebuild, swiftlint, brew, bundle, …) are stubbed via `tests/stubs/`, which prepend to `PATH` and append invocations to `$STUB_CALL_LOG`; tests assert on that log. When adding a script, add a matching bats file and any missing stubs. CI runs these under kcov and publishes coverage to Qlty.
2. **Integration fixture** (`tests/fixture/`) — a tiny XcodeGen iOS app (`FixtureApp`) built/tested by the `fixture_test` job in `.circleci/test-deploy.yml` on a real macOS executor, with an 80% coverage gate (`scripts/ci/check_coverage_threshold.sh`).

### CI pipeline

Two-stage dynamic config: `.circleci/config.yml` (`setup: true`) runs lint/pack/review/shellcheck/script_tests, then `orb-tools/continue` triggers `.circleci/test-deploy.yml`, which runs `command-test` + `fixture_test` and — on `v*.*.*` tags only — publishes to the orb registry (`orb-publishing` context). `orb-tools/review` excludes RC006–RC009.

### Releasing

Merge to `main` with conventional commits, then push a semver tag (`vX.Y.Z`). CI publishes the orb and `.github/workflows/release-on-tag.yml` creates the GitHub Release. No manual `circleci orb publish`.

## Conventions

- Inline shell in command/job YAML is forbidden beyond trivial one-liners — extract to `src/scripts/` (orb steps) or `scripts/ci/` (repo CI), `set -euo pipefail`, shellcheck-clean (CI runs `shellcheck/check`).
- YAML: 4-space mappings (yamlfmt), yamllint-clean; pre-commit enforces both.
- Coverage uploads go to Qlty Cloud (`QLTY_COVERAGE_TOKEN` in the `qlty-credentials` context). Code Climate is dead — never reintroduce `CC_TEST_REPORTER_ID` or `test_with_code_climate`.
- README parameter tables (`README.md` + `src/README.md` — the registry-facing copy) must stay in sync with the YAML when adding/changing parameters; `src/README.md` also carries the v1→v2 and v2→v3 migration guides.
