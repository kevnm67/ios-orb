#!/usr/bin/env bash
# Not `-e`: this script's whole job is a chain of `||` fallbacks where an
# earlier command is *expected* to fail (ruby missing, no rbenv versions).
set -uo pipefail

ruby -v || rbenv local "$(rbenv versions --bare | tail -1)" || rbenv local "$(rbenv global)"
ruby -v
which ruby
