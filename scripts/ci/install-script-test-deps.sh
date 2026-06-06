#!/bin/bash
set -euo pipefail

# Install bats-core + kcov on a cimg/base (Ubuntu) executor.
# kcov lives in the 'universe' component, which isn't enabled by default.
sudo add-apt-repository -y universe
sudo apt-get update -qq
sudo apt-get install -y bats kcov

bats --version
kcov --version | head -1
