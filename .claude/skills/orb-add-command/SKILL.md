---
name: orb-add-command
description: "Scaffolds a brand-new orb command end to end: src/commands/<name>.yml, its script(s) in src/scripts/, a bats test per script with stubs, and the README.md + src/README.md rows. Use when the user says 'add a command that...', 'create a new orb step', 'wrap <tool> as a command', or wants to expose a new capability from the orb."
allowed-tools: Read Grep Glob Edit Write Bash(bats:*) Bash(shellcheck:*) Bash(circleci:*)
---

# orb-add-command

Adds one orb command in a single pass, in the order below — skipping the order produces a command with no tests or undocumented parameters, which is exactly what `check-readme-params.sh` and CI catch.

## Naming (do not mix cases)

| Piece | Case | Example |
| --- | --- | --- |
| `src/commands/<name>.yml` file + its `parameters:` keys | **snake_case** (RC010) | `src/commands/upload_dsyms.yml`, param `sentry_org` |
| `src/scripts/<name>_<verb>.sh` | snake_case, 1:1 with the command | `upload_dsyms_run.sh` (or just `upload_dsyms.sh` if there's only one step) |
| `tests/scripts/<script>.bats` | matches the script name | `upload_dsyms_run.bats` |
| Env vars the command passes into the script | `UPPER_SNAKE` | `SENTRY_ORG`, `SENTRY_AUTH_TOKEN` |

## Scaffold order

1. **`src/scripts/<name>.sh`** — all real logic. `set -euo pipefail`, shellcheck-clean. Read every value from environment variables the command will set (never interpolate `<< parameters.x >>` into the script body — that's an `orb-tools/review` RC009-style violation this repo enforces stricter than upstream). Model on `src/scripts/swiftlint_run.sh`: build an `ARGS=()` array from optional params, guard empty-array expansion under `set -u` with `${ARGS[@]+"${ARGS[@]}"}` (macOS ships bash 3.2).

2. **`tests/stubs/<binary>`** — add one only if the external binary the script calls isn't already stubbed (check `tests/stubs/` first). Shape:

    ```bash
    #!/usr/bin/env bash
    echo "<binary> stub: $*" >&2
    echo "<binary> $*" >> "${STUB_CALL_LOG:-/tmp/stub_calls.log}"
    echo "stub:<binary> $*"
    ```

3. **`tests/scripts/<script>.bats`** — prepend `STUBS` to `PATH`, set a per-test `STUB_CALL_LOG` in `${BATS_TMPDIR}/calls_${BATS_TEST_NUMBER}.log`, assert both on `$output` and by grepping `$STUB_CALL_LOG` for the exact invocation. Cover: default/happy path, each optional parameter toggled, and at least one failure/edge case. `bats tests/scripts` must pass before moving on.

4. **`src/commands/<name>.yml`** — `description:` (RC002, benefit + usage — this is what registry search indexes), a `parameters:` block with a `description:` on **every** parameter (RC002 applies per-parameter too), sane defaults, secrets as `type: env_var_name` never a raw default (RC012). Steps section wires params to env vars and calls the script via `<< include(scripts/<name>.sh) >>` — see `src/commands/swiftlint.yml` for the exact shape.

5. **`src/jobs/*.yml`** (only if the command should be reachable without composing steps by hand) — add a pass-through parameter and wire the new command into the job's `steps:`.

6. **`src/examples/*.yml`** — either extend an existing task-named example or add a new one if this command represents a new use case (RC003/RC004: task-named, not generic `example.yml`).

7. **README rows** — run `./scripts/ci/check-readme-params.sh` (or use the `orb-param-sync` skill) and add the missing rows to both `README.md` and `src/README.md`.

## Verification gate

```bash
bats tests/scripts tests/hooks tests/ci
shellcheck src/scripts/*.sh
cd src && ./pack.sh                              # packs + circleci orb validate
circleci config validate .circleci/config.yml
./scripts/ci/check-readme-params.sh              # must exit 0 for the new command
pre-commit run --all-files
```

## Anti-patterns

| Don't | Why |
| --- | --- |
| Interpolate `<< parameters.x >>` directly into script body text | Bypasses this repo's stricter-than-upstream RC009 convention; use `environment:` + env vars |
| kebab-case a `src/commands/*.yml` file or a parameter key | RC010 fails; orb components are the one snake_case exception |
| Write the YAML before the script + bats | Produces an untested command; the scaffold order above exists to prevent that |
| Skip a parameter's `description:` | RC002 fails per-parameter, not just per-component |
| Forget the job-level pass-through parameter | The command becomes usable only via raw `steps:` composition, not through `run_with_setup`/`test`/etc. |
