#!/usr/bin/env bash
# scripts/ci/check-readme-params.sh
#
# Verifies every `parameters:` key in src/commands/*.yml and src/jobs/*.yml
# has a documented `| `<param>` |` table row in BOTH README.md and
# src/README.md. This is a presence check only (row exists), not a
# correctness check (type/default/description match) — exits 1 and lists
# every miss.
#
# `yq` is not guaranteed to be present in every CI image; PyYAML is, so the
# actual parsing/matching runs in a python3 heredoc and this wrapper just
# checks the dependency and forwards the exit code.
#
# Usage: ./scripts/ci/check-readme-params.sh
set -euo pipefail

# REPO_ROOT can be overridden (e.g. by tests/ci/check-readme-params.bats) to
# point at a fixture repo instead of the one this script lives in.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

if ! python3 -c "import yaml" 2>/dev/null; then
    echo "ERROR: python3 module PyYAML not found. Install with: pip3 install pyyaml" >&2
    exit 1
fi

python3 - "${REPO_ROOT}" << 'PYEOF'
import glob
import os
import sys

import yaml

repo_root = sys.argv[1]
readme_paths = ["README.md", "src/README.md"]

readme_text = {}
for rel in readme_paths:
    with open(os.path.join(repo_root, rel), encoding="utf-8") as fh:
        readme_text[rel] = fh.read()

misses = []
checked = 0

for pattern in ("src/commands/*.yml", "src/jobs/*.yml"):
    for path in sorted(glob.glob(os.path.join(repo_root, pattern))):
        with open(path, encoding="utf-8") as fh:
            data = yaml.safe_load(fh) or {}

        component = os.path.splitext(os.path.basename(path))[0]
        rel_path = os.path.relpath(path, repo_root)

        for name in (data.get("parameters") or {}):
            checked += 1
            row = f"| `{name}` |"
            for rel in readme_paths:
                if row not in readme_text[rel]:
                    misses.append(
                        f"{component}.{name} — missing `{row}` in {rel} (declared in {rel_path})"
                    )

print(
    f"Checked {checked} parameter(s) across src/commands/*.yml + src/jobs/*.yml "
    f"against {' and '.join(readme_paths)}."
)

if misses:
    print(f"\n{len(misses)} missing README row(s):\n")
    for miss in misses:
        print(f"  - {miss}")
    sys.exit(1)

print("All parameters documented in both README.md and src/README.md.")
PYEOF
