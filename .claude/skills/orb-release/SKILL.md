---
name: orb-release
description: "Runs the pre-tag gate suite, tags a semver release from main, and verifies the CircleCI orb registry + GitHub Release both landed. Use when the user says 'release the orb', 'cut a release', 'tag vX.Y.Z', 'publish ios-orb', or after a PR merges to main and it's time to ship the next version."
allowed-tools: Read Grep Glob Bash(git:*) Bash(gh:*) Bash(circleci:*) Bash(bats:*) Bash(shellcheck:*) Bash(pre-commit:*)
---

# orb-release

Releases `kevnm67/ios-orb`. There is **no manual `circleci orb publish`** — pushing a `vX.Y.Z` tag from `main` is the only publish trigger (`.circleci/test-deploy.yml`, `orb-publishing` context), and `.github/workflows/release-on-tag.yml` creates the matching GitHub Release with generated notes on the same push.

## Pre-tag gates (all must be green before tagging)

Run these from repo root, in order, and stop at the first failure:

```bash
git fetch origin main && git status                 # must be on main, clean, up to date
bats tests/scripts tests/hooks tests/ci              # every bats suite
shellcheck src/scripts/*.sh scripts/ci/*.sh .claude/hooks/*.sh
cd src && ./pack.sh && cd -                          # packs + circleci orb validate
circleci config validate .circleci/config.yml
circleci config validate .circleci/test-deploy.yml
pre-commit run --all-files
```

The `test-deploy.yml` validate reports `"Cannot find a definition for command named ios-orb/…"` locally — that is EXPECTED. `orb-tools/continue` injects the orb at pipeline runtime, not during local validation.

If any gate fails, fix it on a normal `fix/IOS-ORB-V3-*` branch and merge before releasing — never tag past a red gate.

## Choosing the version bump (strict semver)

| Change since last tag | Bump |
| --- | --- |
| New command/job/parameter, backward-compatible default change | **minor** |
| Bug fix, doc fix, CI-only change, no orb-consumer-visible behavior change | **patch** |
| Renamed/removed component, changed a parameter's meaning or required a new one, changed a default in a way that breaks existing consumers (Xcode image, Ruby version, cache layout) | **major** |

RC011 requires every `src/examples/*.yml` to reference the **current major** — a major bump means every example's `kevnm67/ios-orb@X.Y.Z` pin changes too, plus a migration guide section in `src/README.md` (see the v1→v2 and v2→v3 sections already there for the shape to follow).

## Procedure

1. Confirm the target version and bump type against the table above; read `CHANGELOG.md`'s `## [Unreleased]` section — it should already describe everything going into this release (this repo keeps the changelog current per-PR, not at release time).

2. Run every pre-tag gate above.

3. Rewrite `CHANGELOG.md`: rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it. Update the `src/README.md` "What's new in vX.Y" section if this is a minor/major. Commit this as `docs(changelog): release vX.Y.Z [IOS-ORB-V3]` on `main` (or as the final commit of the PR being released).

4. Tag and push:

    ```bash
    git checkout main && git pull origin main
    git tag vX.Y.Z
    git push origin vX.Y.Z
    ```

5. Watch the CircleCI pipeline the tag triggers (`test-deploy.yml` → `command-test`, `fixture-test`, `spm-fixture-test`, `fastlane-fixture-test`, then the `orb-publishing`-context publish job on `v*.*.*` tags only).

6. Verify the publish actually landed — **do not trust a green CI run alone**:

    ```bash
    circleci orb info kevnm67/ios-orb | grep Latest   # must show X.Y.Z
    gh release view vX.Y.Z --repo kevnm67/ios-orb      # must exist, --generate-notes body
    ```

    If `circleci orb info` doesn't show the new version, check the publish job log directly — orb registry versions are **immutable and orbs cannot be deleted**, so a botched version number can't be reused; the next tag must increment past it.

7. If `gh release view` 404s but the CircleCI publish succeeded, the `release-on-tag.yml` workflow run may have failed independently — check `gh run list --repo kevnm67/ios-orb --workflow release-on-tag.yml` and re-run or manually recreate with `gh release create vX.Y.Z --generate-notes`.

## Anti-patterns

| Don't | Why |
| --- | --- |
| `circleci orb publish` by hand | Only tags publish; manual publish drifts from the tagged commit |
| Tag before `pre-commit run --all-files` is clean | CI will fail after the tag is already pushed — can't delete/reuse the version |
| Skip the `circleci orb info` / `gh release view` verification | A green pipeline doesn't guarantee both side effects landed |
| Reuse or "fix" a bad version number | Registry versions are immutable — bump forward instead |
