RUBY := $(shell command -v ruby 2>/dev/null)
HOMEBREW := $(shell command -v brew 2>/dev/null)
BUNDLER := $(shell command -v bundle 2>/dev/null)

VERSION = 0.0.1

.PHONY: help
help:
	@echo "Please use \`make <command>' where <command> is one of"
	@echo "  setup              to validate orb.yml and the main circle ci config."
	@echo "  publish_ios_dev    to publish ios dev."
	@echo "  install_gems       to install gem deps."
	@echo "  install_bundler    to install bundler."

orb_org=kevnm67
orbname=$orb_org/ios-orb
default=validate

default: setup

validate:
	circleci orb validate orb.yaml
	if [ -f .circleci/config.yml ]; then circleci config validate; fi

publish_ios_dev:
	$(sh echo "export VERSION = ${VERSION}")
	Scripts/orb_publish.sh

setup: \
	# $(MAKE) validate
	$(MAKE) install_gems \
	$(MAKE) install_ios_dependencies

install_gems:

ifeq ($(CIRCLECI),)
	$(info Not running on circle CI...)
	$(MAKE) install_bundler
endif

	bundle install

install_bundler:

ifeq ($(BUNDLER),)
	gem install bundler
else
	gem update bundler
endif
