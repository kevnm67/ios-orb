#!/usr/bin/env bash

ruby -v || rbenv local "$(rbenv versions --bare | tail -1)" || rbenv local "$(rbenv global)"
ruby -v
which ruby
