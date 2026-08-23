---
name: xcode-image-bump
description: "Bumps the default Xcode/macOS image version across the executor, jobs, examples, READMEs and wiki, verified against CircleCI's live image manifest (stable only, never a beta build). Use when the user says 'bump to the latest Xcode', 'update the macOS image', 'new Xcode version available', or when CircleCI announces a new stable image."
allowed-tools: Read Grep Glob Edit Bash(curl:*) Bash(grep:*) Bash(bats:*) Bash(circleci:*) WebFetch
---

# xcode-image-bump

Bumps the orb's default Xcode image (`src/executors/macos.yml` `xcode_version`, and every job/example that repeats the default). **Never answer from memory about what a CircleCI image contains** — always read the live manifest.

## Manifest lookup procedure

1. Fetch the images list page: <https://circleci.com/docs/guides/execution-managed/using-macos/>

2. Extract the per-image manifest URL:

    ```bash
    curl -sL https://circleci.com/docs/guides/execution-managed/using-macos/ | grep -oE 'https://circle-macos-docs\.s3\.amazonaws\.com/image-manifest/[^"]+'
    ```

3. Fetch `manifest.txt` for the candidate image tag. It lists: Xcode build number, Swift version, `Rubies (rbenv)` (must include `3.3`), Fastlane version, and simulator device/runtime names.

4. **Stable only.** Reject any tag whose Xcode build starts with a beta pattern (e.g. `27A...`) — those are pre-release seeds, not what `circleci/macos`'s stable resource classes actually run. Confirm the version is what CircleCI's docs page lists as current, not merely present in some manifest URL you found.

5. If a URL 404s or the page structure changed, WebSearch for the moved page — never guess the image tag or its contents.

## Ruby guard (do not skip)

**`setup.ruby_version` must stay `3.3`.** If the new manifest's `Rubies (rbenv)` line drops 3.3, this bump is **blocked** — escalate to the user rather than silently moving the default to 3.4 or later; 3.4 breaks Fastlane in consumer projects. Confirm by keeping `scripts/ci/assert-ruby-version.sh 3.3` green in `fastlane-fixture-test`.

## What changes in one bump

- `src/executors/macos.yml` — `xcode_version` default.
- `src/jobs/*.yml` — any job that repeats the executor's default inline.
- `src/examples/*.yml` — device/runtime names if simulator names changed (e.g. `iPhone <N>` → `iPhone <N+1>`) alongside the Xcode bump.
- `README.md`, `src/README.md`, `CLAUDE.md` — every mention of the current default Xcode/device.
- `docs/architecture/*.d2` + the wiki, if the diagram labels a version (see the `orb-diagram-sync` skill for the render + wiki-push steps).
- `CHANGELOG.md` — `## [Unreleased]` entry; this is at minimum a **minor** bump per `orb-release`'s version table, **major** if the new image drops support for something a consumer might depend on (a Ruby version, a simulator).

## Verification

```bash
bats tests/scripts tests/hooks tests/ci
cd src && ./pack.sh
circleci config validate .circleci/config.yml
```

Record the verification in the commit message: `"verified YYYY-MM-DD from manifest <image-tag>"` — this is the audit trail the next bump's author reads instead of re-deriving trust in the version.

## Anti-patterns

| Don't | Why |
| --- | --- |
| Bump from memory / a blog post / a CircleCI changelog summary | Only the live manifest confirms what a given image tag actually ships |
| Accept a beta build tag (`27A…`) | Not what production resource classes run |
| Let `ruby_version` default drift to 3.4+ | Breaks Fastlane in every consumer project |
| Bump the executor default without updating examples/READMEs/wiki in the same PR | Docs-in-lockstep is a repo hard rule |
