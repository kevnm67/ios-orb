# Research: Claude project items (2026-08-23)

| id | kind | name | value | effort | note |
|---|---|---|---|---|---|
| C-1 | skill | orb-release | 4 | M | pre-tag gates, tag, verify registry + GH release |
| C-2 | skill | orb-param-sync | 4 | S | YAML params vs README tables via C-12 |
| C-3 | skill | xcode-image-bump | 4 | M | manifest lookup, stable-only, Ruby 3.3 guard |
| C-4 | skill | orb-add-command | 5 | M | scaffold yml+script+bats+stub+README rows |
| C-5 | skill | orb-diagram-sync | 3 | S | dark d2 render + wiki SVG push |
| C-6 | hook | block-push-without-verify | 4 | M | PreToolUse Bash git push; marker from C-8 |
| C-7 | hook | block-packed-file-edits | 4 | S | deny Edit/Write on src/ios.yml, orb.yml |
| C-8 | hook | pack-validate-on-src-edit | 5 | S | PostToolUse Edit/Write src/**.yml → pack.sh |
| C-9 | hook | readme-sync-reminder | 3 | S | Stop hook advisory |
| C-10 | agent | bats-test-writer | 4 | M | |
| C-11 | agent | orb-docs-syncer | 4 | S | |
| C-12 | script | scripts/ci/check-readme-params.sh | 4 | S | yq-based; reusable by skill/hook/CI |

Notes: .gitignore needs `!.claude/skills/`, `!.claude/hooks/`, `!.claude/settings.json`.
