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

- `src/executors/macos.yml` — the single executor (Apple Silicon, Xcode `26.6` / `m4pro.medium` defaults)
- `src/commands/*.yml` — one file per command (setup, lane, xcodegen, swiftlint, match_signing, SPM caching, coverage export, Qlty upload, …)
- `src/jobs/*.yml` — `run_with_setup`, `test`, `build_and_test_xcode`, `build_and_test_spm`
- `src/examples/*.yml` — usage examples published with the orb
- `src/scripts/*.sh` — **all real shell logic lives here**, pulled into commands via `<< include(scripts/foo.sh) >>`. Commands pass orb parameters to scripts as environment variables (e.g. `SWIFTLINT_STRICT`), never by interpolating into the script body.

### Testing model

Two layers:

1. **bats unit tests** — one bats file per shell script: `tests/scripts/*.bats` for `src/scripts/*.sh`, `tests/ci/*.bats` for `scripts/ci/*.sh`, `tests/hooks/*.bats` for `.claude/hooks/*.sh` (~260 tests total; `bats tests/scripts tests/ci tests/hooks`). External binaries (xcodebuild, swiftlint, brew, bundle, …) are stubbed via `tests/stubs/`, which prepend to `PATH` and append invocations to `$STUB_CALL_LOG`; tests assert on that log. When adding a script, add a matching bats file and any missing stubs. CI runs these under kcov and publishes coverage to Qlty.
2. **Integration fixtures** in `.circleci/test-deploy.yml` on a real macOS executor: `fixture-test` builds/tests the XcodeGen iOS app in `tests/fixture/` with the raw `build_xcode`/`test_xcode` commands; `fastlane-fixture-test` runs the same app through `setup` (Ruby 3.3 + bundle) and the `scan` lane in `tests/fixture/fastlane/Fastfile` — this is the proof that the orb's Ruby default resolves on the current image (`scripts/ci/assert-ruby-version.sh`); `spm-fixture-test` covers the pure-SPM path (`tests/fixture-spm/`). Both Xcode fixtures enforce an 80% coverage gate (`scripts/ci/check-coverage-threshold.sh`).

### CI pipeline

Two-stage dynamic config: `.circleci/config.yml` (`setup: true`) runs lint/pack/review/shellcheck/script-tests, then `orb-tools/continue` triggers `.circleci/test-deploy.yml`, which runs `command-test` + `fixture-test` and — on `v*.*.*` tags only — publishes to the orb registry (`orb-publishing` context). `orb-tools/review` excludes RC006–RC009.

### Releasing

Merge to `main` with conventional commits, then push a semver tag (`vX.Y.Z`). CI publishes the orb and `.github/workflows/release-on-tag.yml` creates the GitHub Release. No manual `circleci orb publish`.

## Conventions

- **Naming — kebab-case everywhere CircleCI lets us choose**: repo pipeline jobs/workflows (`script-tests`, `fixture-test`, `lint-pack`), cache-key prefixes, contexts, `scripts/ci/<verb>-<noun>.sh`, agent files. The one exception is mandated by CircleCI itself: orb components and parameters (`src/commands|jobs|executors/*.yml` file names, keys, `parameters:`) are **snake_case** — `orb-tools/review` RC010 fails on a hyphen, and renaming them is a breaking change for consumers.
- **Orb authoring best practices are enforced by `orb-tools/review`** (RC001–RC012: source/home URL, descriptions on every component/parameter, ≥1 task-named usage example pinned to the current major, named `run` steps, long commands via `<< include() >>`, snake_case components, no `$ENV` defaults used in keys). Use the project agent `.claude/agents/circleci-orb-author.md` for any orb change.
- **Diagrams**: d2 only, rendered **dark** via the engineering-toolkit `design-d2` skill (`...@kjm-classes`, `d2-render.sh` = elk / theme 200). Never `--theme 0` / light renders.
- Inline shell in command/job YAML is forbidden beyond trivial one-liners — extract to `src/scripts/` (orb steps) or `scripts/ci/` (repo CI), `set -euo pipefail`, shellcheck-clean (CI runs `shellcheck/check`).
- YAML: 4-space mappings (yamlfmt), yamllint-clean; pre-commit enforces both.
- **Ruby: `setup.ruby_version` defaults to `3.3` and must never be `3.4`** — 3.4 breaks Fastlane in the consumer projects (26.x CircleCI images ship rbenv 3.3 / 3.4 / 4.0).
- **Fastlane first.** Examples, quick starts and docs lead with `run_with_setup` + the `test` job / `lane` command (scan owns the xcresult + JUnit output). The raw `xcodebuild` commands (`build_xcode`, `test_xcode`, `build_and_test_xcode`) are the fallback for projects without a Fastfile; `swift build/test` is fine for pure SPM packages.
- Coverage uploads go to Qlty Cloud (`QLTY_COVERAGE_TOKEN` in the `qlty-credentials` context). Code Climate is dead — never reintroduce `CC_TEST_REPORTER_ID` or `test_with_code_climate`.
- README parameter tables (`README.md` + `src/README.md` — the registry-facing copy) must stay in sync with the YAML when adding/changing parameters; `src/README.md` also carries the v1→v2 and v2→v3 migration guides.

## Project Claude items

`.claude/` is committed (see `.gitignore`'s `.claude/*` + negations —
`.claude/settings.local.json` stays ignored):

- **Skills** (`.claude/skills/<name>/SKILL.md`): `orb-release` (pre-tag
    gates, tag, verify registry + GitHub Release), `orb-param-sync`
    (README parameter-table sync via `scripts/ci/check-readme-params.sh`),
    `xcode-image-bump` (manifest lookup, stable-only, Ruby 3.3 guard),
    `orb-add-command` (scaffold command yml + script + bats + stub + README
    rows in one pass), `orb-diagram-sync` (dark d2 render + wiki SVG push).
- **Agents** (`.claude/agents/*.md`): `circleci-orb-author` (any `src/`
    change), `bats-test-writer` (bats coverage for `src/scripts/`,
    `.claude/hooks/`, `scripts/ci/`), `orb-docs-syncer` (README/CHANGELOG/wiki
    lockstep).
- **Hooks** (`.claude/settings.json` → `.claude/hooks/*.sh`):
    - `PreToolUse` on `Bash(git push*)` → `check-verified.sh` denies the push
        if `src/`/`tests/` have commits (vs `origin/main`) newer than the last
        successful `cd src && ./pack.sh` run.
    - `PreToolUse` on `Edit|Write` → `block-packed-files.sh` denies edits to
        the generated `src/ios.yml` / `orb.yml` — edit unpacked `src/` instead.
    - `PostToolUse` on `Edit|Write` → `pack-validate.sh` re-runs
        `cd src && ./pack.sh` when the file is under
        `src/{commands,jobs,executors,examples}/` or `src/@orb.yml`, and
        stamps the verification marker `check-verified.sh` requires. Exits 2
        with the pack error on failure; exits 0 with a `systemMessage` if the
        `circleci` CLI isn't installed (never blocks on a missing dependency).
    - `Stop` → `readme-sync-check.sh` is advisory only: reminds (never
        blocks) when `src/commands|jobs|executors` changed without a matching
        `README.md` / `src/README.md` edit.
    - Tested in `tests/hooks/*.bats` (`bats tests/hooks` / `make hooks-test`);
        CI runs them as the `hook-tests` step in the `script-tests` job
        alongside `tests/ci/*.bats`.
