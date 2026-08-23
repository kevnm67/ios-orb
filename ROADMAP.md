# ios-orb Roadmap

Groomed 2026-08-23 from a four-track discovery pass (features, quality, Claude project
items, docs). Research notes live in `.tasks/roadmap/`. Each phase ships as one orb
release; each track inside a phase is one PR. Orb components stay snake_case
(orb-tools RC010); everything else is kebab-case. Ruby 3.3 never 3.4; Fastlane first.

## Phase 1 — v3.2.0 "foundations & polish"

| Track | Scope | Items |
| --- | --- | --- |
| A — Claude project items + repo hygiene | `.claude/skills/*`, `.claude/hooks/*`, `.claude/settings.json`, `.claude/agents/*`, `scripts/ci/check-readme-params.sh`, LICENSE, issue templates, labeler, release-drafter, CHANGELOG, CONTRIBUTING | C-1…C-12, D-11, D-12, D-13, D-14, D-15, D-16, D-17 |
| B — Docs & examples | README/src/README parameter tables for every command/job, env-var section, light/dark `<picture>` diagram, registry badges, new examples (`build_and_test_xcode`, deploy with match, pipeline parameters, matrix), consumer-neutral context names, plain-text orb description | D-1…D-8, D-18…D-25, F-14, F-15 |
| E — Quality audit fixes | bugs / hardening / test gaps from the quality audit (`.tasks/roadmap/research-quality.md`) | Q-* |

## Phase 2 — v3.3.0 "small features"

| Track | Items |
| --- | --- |
| C — build/test ergonomics | F-1 `preboot_simulator`, F-3 Swift Testing `--xunit-output` (`test_framework`), F-6 `retry_on_failure`/`test_iterations`, F-13 beta-image guard |
| C2 — tooling commands | F-5 `swiftformat` + `periphery_scan`, F-2 `upload_dsyms` (Sentry), F-7 `notarize_macos` |

## Phase 3 — v3.4.0 "scale & deploy"

| Track | Items |
| --- | --- |
| D — deploy | F-4 `deploy_testflight` (fastlane pilot), F-10 `notify_slack` |
| D2 — speed | F-8 `split_tests` (`circleci tests split`), F-9 DerivedData cache, F-11 `junit_source: xcresulttool`, F-12 `tuist_generate` |

## Definition of done (every track)

- `bats tests/scripts` green with a bats file per new script; `shellcheck` clean; `cd src && ./pack.sh` valid; `pre-commit run --all-files` clean; README fenced YAML 4-space.
- README.md + src/README.md tables, `CLAUDE.md`, examples (`@current`), CHANGELOG entry updated in the same PR.
- PR green (incl. `fixture-test`, `spm-fixture-test`, `fastlane-fixture-test`), qlty 0 findings, squash-merged; phase ends with a `vX.Y.Z` tag.

## Dropped / already done

- D-9, D-10 (CLAUDE.md Xcode default / fixture list) — fixed in v3.1.1 before grooming.
