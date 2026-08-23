---
name: orb-param-sync
description: "Finds and fixes orb parameters undocumented in README.md / src/README.md by running scripts/ci/check-readme-params.sh and adding the missing table rows. Use when the user says 'sync the README params', 'check param docs', 'did I document that parameter', or after adding/renaming a parameter on any src/commands/*.yml or src/jobs/*.yml."
allowed-tools: Read Grep Glob Edit Bash(./scripts/ci/check-readme-params.sh) Bash(python3:*)
---

# orb-param-sync

Keeps `README.md` and `src/README.md` parameter tables honest against the YAML in `src/commands/*.yml` and `src/jobs/*.yml`. The check itself lives in `scripts/ci/check-readme-params.sh` (PyYAML-based, no `yq` dependency since it isn't guaranteed on every CI image) — this skill runs it and fixes what it finds.

## What the check does and doesn't catch

```bash
./scripts/ci/check-readme-params.sh
```

For every `parameters:` key under `src/commands/*.yml` + `src/jobs/*.yml`, it greps both README files for a literal `` | `<param>` | `` row and lists every miss, exiting 1 if any exist.

**Presence only, not correctness.** A stale row (wrong default, wrong type, wrong description) passes silently — this script only proves the row exists, not that it matches the YAML. Always read the YAML `description:` and `default:` alongside the README row you're touching or adding.

## Procedure

1. Run the script; capture the full miss list.

2. For each miss, open the source YAML (`src/commands/<name>.yml` or `src/jobs/<name>.yml`) and read that parameter's `description`, `type`, and `default`.

3. Add a row to the matching parameter table in **both** files. `README.md` tables live under the `### \`<command_or_job>\`` heading (see the `match_signing` table for the exact shape: `| Parameter | Default | Description |`). `src/README.md`'s "Commands Reference" section uses a different layout — a single summary table per component listing all its parameter names comma-separated in one cell (see the `swiftlint` / `install_tools` rows) — match whichever format that file already uses in the surrounding section rather than inventing a third shape.

4. Re-run the script until it exits 0.

5. `pre-commit run --all-files` — README fenced YAML blocks are 4-space (qlty editorconfig-checker flags 2-space lines inside them).

## When a command/job has zero documented parameters yet

Some components (e.g. `swiftlint`, `install_tools` at the time this skill was written) have no parameter table at all — the whole section needs adding, not just a missing row. Model the new section on `match_signing`'s in `README.md` and on the neighboring row in `src/README.md`'s Commands Reference table.

## Anti-patterns

| Don't | Why |
| --- | --- |
| Trust a green run as "docs are correct" | The check only verifies a row exists, not that it's accurate |
| Add a row to only one of the two README files | The script (and the repo convention) require both |
| Invent a new table shape for `src/README.md` | It intentionally summarizes differently from `README.md` — match the existing section style |
| Fix misses without reading the YAML `description`/`default` | Copy-pasting a neighboring row's text produces wrong docs that still pass the presence check |
