# Developer convenience targets for ios-orb.
# Real CI runs via .circleci/config.yml (orb-tools) — these mirror it locally.

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "  pack       Pack src/ into src/ios.yml and validate it"
	@echo "  validate   Validate the packed orb and .circleci configs"
	@echo "  test       Run bats tests for src/scripts (no kcov needed locally)"
	@echo "  coverage   Run bats tests under kcov -> coverage/cobertura.xml"
	@echo "  lint       Run pre-commit hooks (yamllint, yamlfmt, hygiene) on all files"
	@echo "  shellcheck Run shellcheck on all shell scripts"
	@echo "  setup      Install local dev dependencies (bats-core, shellcheck, pre-commit)"

.PHONY: pack
pack:
	cd src && ./pack.sh

.PHONY: validate
validate: pack
	circleci config validate .circleci/config.yml
	circleci config validate .circleci/test-deploy.yml

.PHONY: test
test:
	bats tests/scripts

.PHONY: coverage
coverage:
	./scripts/ci/run-script-tests.sh

.PHONY: lint
lint:
	pre-commit run --all-files

.PHONY: shellcheck
shellcheck:
	shellcheck src/scripts/*.sh scripts/ci/*.sh src/pack.sh scripts/variables.sh

.PHONY: setup
setup:
	brew install bats-core shellcheck pre-commit circleci
	pre-commit install
