#!/usr/bin/env bash
# scripts/ci/check-readme-params.sh
#
# Verifies every `parameters:` key in src/commands/*.yml and src/jobs/*.yml
# has a documented `| `<param>` |` table row in BOTH README.md and
# src/README.md. This is a presence check only (row exists), not a
# correctness check (type/default/description match) — exits 1 and lists
# every miss.
#
# Neither `yq` nor python3+PyYAML is guaranteed to be present on every CI
# image (cimg/base ships neither), so parameter names are extracted with
# `yq` when it's on PATH, falling back to a purpose-built awk parser tuned
# to this repo's yamlfmt 4-space `parameters:` layout: a bare `    <name>:`
# line directly under a top-level `parameters:` key, until the next
# top-level (column-0) key ends the block.
#
# Usage: ./scripts/ci/check-readme-params.sh
set -euo pipefail

# REPO_ROOT can be overridden (e.g. by tests/ci/check-readme-params.bats) to
# point at a fixture repo instead of the one this script lives in.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# extract_params_yq FILE — one parameter name per line via yq (mikefarah v4).
extract_params_yq() {
    yq -r '.parameters // {} | keys | .[]' "$1"
}

# extract_params_awk FILE — one parameter name per line via a plain-text scan.
# Matches a line that is exactly 4-space-indented + `<identifier>:` while
# inside the `parameters:` block; any column-0 line ends the block.
extract_params_awk() {
    awk '
        /^parameters:[[:space:]]*$/ { in_params = 1; next }
        in_params && /^[^[:space:]]/ { in_params = 0 }
        in_params && /^    [A-Za-z_][A-Za-z0-9_]*:/ {
            line = $0
            sub(/^    /, "", line)
            sub(/:.*/, "", line)
            print line
        }
    ' "$1"
}

extract_params() {
    if command -v yq &>/dev/null; then
        extract_params_yq "$1"
    else
        extract_params_awk "$1"
    fi
}

misses=()
checked=0
readmes=("README.md" "src/README.md")

shopt -s nullglob
files=("${REPO_ROOT}"/src/commands/*.yml "${REPO_ROOT}"/src/jobs/*.yml)
shopt -u nullglob

for file in "${files[@]}"; do
    component="$(basename "${file}" .yml)"
    rel_path="${file#"${REPO_ROOT}"/}"

    while IFS= read -r param; do
        [[ -z "${param}" ]] && continue
        checked=$((checked + 1))
        row="| \`${param}\` |"
        for readme in "${readmes[@]}"; do
            if ! grep -qF -- "${row}" "${REPO_ROOT}/${readme}"; then
                misses+=("${component}.${param} — missing \`${row}\` in ${readme} (declared in ${rel_path})")
            fi
        done
    done < <(extract_params "${file}")
done

echo "Checked ${checked} parameter(s) across src/commands/*.yml + src/jobs/*.yml against ${readmes[0]} and ${readmes[1]}."

if [[ ${#misses[@]} -gt 0 ]]; then
    echo
    echo "${#misses[@]} missing README row(s):"
    echo
    for miss in "${misses[@]}"; do
        echo "  - ${miss}"
    done
    exit 1
fi

echo "All parameters documented in both README.md and src/README.md."
