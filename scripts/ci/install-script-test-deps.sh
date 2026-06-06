#!/bin/bash
set -euo pipefail

# Install bats-core + kcov on a cimg/base (Ubuntu 24.04) executor.
# kcov was dropped from Ubuntu 24.04 repos, so build it from a pinned
# source release. The CI job caches KCOV_PREFIX keyed on KCOV_VERSION.

KCOV_VERSION="${KCOV_VERSION:-v43}"
KCOV_PREFIX="${KCOV_PREFIX:-$HOME/kcov}"

sudo apt-get update -qq
sudo apt-get install -y bats cmake g++ binutils-dev libssl-dev \
    libcurl4-openssl-dev libdw-dev libiberty-dev zlib1g-dev

if [ ! -x "${KCOV_PREFIX}/bin/kcov" ]; then
    workdir="$(mktemp -d)"
    curl -fsSL "https://github.com/SimonKagstrom/kcov/archive/refs/tags/${KCOV_VERSION}.tar.gz" \
        | tar -xz -C "$workdir" --strip-components=1
    cmake -S "$workdir" -B "$workdir/build" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$KCOV_PREFIX"
    make -C "$workdir/build" -j"$(nproc)"
    make -C "$workdir/build" install
    rm -rf "$workdir"
fi

sudo ln -sf "${KCOV_PREFIX}/bin/kcov" /usr/local/bin/kcov

bats --version
kcov --version | head -1
