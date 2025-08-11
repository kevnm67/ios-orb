#!/usr/bin/env bash

set -e
# shellcheck source=/dev/null
. "$SCRIPT_DIR"/variables.sh

# https://circleci.com/docs/2.0/local-cli/
# https://circleci.com/orbs/registry/orb/protimenet/ios#jobs-build-ios-framework

# Orb functions mostly from:
# https://github.com/artsy/orbs

export DRY_RUN=${DRY_RUN:-""}
export CI=${CI:-""}

VERSION_REGEX="[0-9]*\.[0-9]*\.[0-9]*"

###########
# Utility #
###########

fancy_echo() {
  local fmt="$1"; shift
  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}

#############
# Functions #
#############

get_orb_path() {
  local ORB="$1"

  if [[ -z "$ORB_PARENT_DIR" ]]; then
    # Default parent directory is the name of the orb.
    ORB_PARENT_DIR=$ORB
  fi

  local YML_PATH="$BASE_DIR/$ORB_PARENT_DIR/$ORB.yml"

  fancy_echo "$YML_PATH"
}

get_orb_version() {
  local YML_PATH
  YML_PATH=$(get_orb_path "$1")

  fancy_echo "yml path $YML_PATH"

  VERSION_COMMENT=$(head -n 1 "$YML_PATH")
  VERSION=$(fancy_echo "$VERSION_COMMENT" | grep -o "$VERSION_REGEX")

  echo "$VERSION"
}

is_orb_created() {
  check_for_namespace
  local CREATED
  CREATED=$(circleci orb list "$NAMESPACE" | grep -w "$NAMESPACE/$1")

  if [ -n "$CREATED" ]; then
    fancy_echo "$(GREEN "Orb ($NAMESPACE/$1) was previously created.")"
  fi
}

is_orb_published() {
  check_for_namespace

  local published_orb
  published_orb=$(circleci orb info "$NAMESPACE"/"$1" > /dev/null 2>&1; fancy_echo $?)

  if [ "$published_orb" -eq "0" ]; then
    echo "true"
  fi
}

get_published_orb_version() {
  check_for_namespace
  local last_published
  last_published=$(circleci orb info "$NAMESPACE"/"$1" | grep -i latest | grep -o "$VERSION_REGEX")
  fancy_echo "$last_published"
}

compare_version() {
  local GREATER=">"
  local LESS="<"
  local EQUAL="="

  IFS='.' read -ra VERSION1 <<< "$1"
  IFS='.' read -ra VERSION2 <<< "$2"

  for ((i=0; i<${#VERSION1[@]}; ++i)); do
    if [ "${VERSION1[i]}" -gt "${VERSION2[i]}" ]; then
      fancy_echo $GREATER
      return
    elif [ "${VERSION1[i]}" -lt "${VERSION2[i]}" ]; then
      fancy_echo $LESS
      return
    fi
  done

  fancy_echo $EQUAL
}

###############
# ORB Utility #
###############

is_ci() {
  local  __resultvar="${CI}"
  local  is_ci_result='false'

  if [[ "$__resultvar" ]]; then
    is_ci_result='true'
  fi

  echo "$is_ci_result"
}

check_defaults() {
  # Set the base dir if not previously set.
  if [ -z "$BASE_DIR" ]; then
    BASE_DIR=../src
  fi
}

check_for_namespace() {
  NAMESPACE=${NAMESPACE:-""}

  if [ -z "$NAMESPACE" ]; then
    fancy_echo "An env variable NAMESPACE must be provided that matches your CircleCI orb namespace"
    exit 1
  fi
}

prepare() {
  check_for_namespace
  check_defaults

  # Set a dry-run mode
  if [ -n "$DRY_RUN" ] || [ -z "$CI" ]; then
    DRY_RUN="true"
    fancy_echo "$(YELLOW "[Running in dry-run mode]")"
  else
    DRY_RUN=""
  fi
}

validate_token() {
  # Build CircleCI token argument
  TOKEN=""

  if [ -n "${CIRCLECI_API_KEY:-}" ]; then
    # shellcheck disable=SC2034
    TOKEN="--token $CIRCLECI_API_KEY"
  elif [ -z "$DRY_RUN" ]; then
    fancy_echo "$(RED "Must provide CIRCLECI_API_KEY env var")"
    exit 1
  fi
}

check_published() {
  ORB=$1
  is_published=$(is_orb_published "$ORB")

  # If the orb has been previously published (i.e. it already exists in circle's registry)
  if [ -n "$is_published" ]; then
    last_published=$(get_published_orb_version "$ORB")

    fancy_echo "$(GREEN "Last published $last_published")"
  else
    fancy_echo "$(YELLOW "Orb ($NAMESPACE/$ORB) has not been published.")"
    ask_to_publish_dev "$ORB"
  fi
}

ask_to_publish_dev() {
  fancy_echo "Do you want to publish the dev version of your orb? (y/n)? "

  read -r response

  if [ "$response" != "${response#[Yy]}" ]; then
    ORB_PATH=$(get_orb_path "$ORB")

    publish_dev "$1"
  else
      exit 1
  fi
}

publish_dev() {
  ORB_PATH=$(get_orb_path "$1")

  fancy_echo "$(GREEN "Publishing orb $NAMESPACE/$1 at path $ORB_PATH")"

  circleci orb publish "$ORB_PATH" "$NAMESPACE"/"$1"@dev:alpha patch
}

publish_prod() {
  ORB_PATH=$(get_orb_path "$1")

  fancy_echo "$(GREEN "Publishing orb $NAMESPACE/$1 at path $ORB_PATH")"

  circleci orb publish increment "$ORB_PATH" "$NAMESPACE"/"$1" patch
}

check_created() {
  ORB=$1
  IS_CREATED=$(is_orb_created "$ORB")

  if [ -n "$IS_CREATED" ]; then
    CREATED=$(get_published_orb_version "$ORB")

    fancy_echo "$(GREEN "Last published $CREATED")"
  else
    fancy_echo "$(YELLOW "Orb ($NAMESPACE/$ORB) has NOT been created...")"
    ask_to_create "$ORB"
  fi
}


ask_to_create() {
  fancy_echo "Do you want to publish your orb now? (y/n)? "

  read -r response

  if [ "$response" != "${response#[Yy]}" ]; then
    create_orb "$1"
  else
    exit 1
  fi
}

create_orb() {
  # ex: create_orb ruby-ci
  # create_orb cache-commands
  fancy_echo "$(GREEN "Creating orb $NAMESPACE/$1")"
  circleci orb create "$NAMESPACE"/"$1"
}

publish() {
  orb_path=$1
  orb_name=$2

  circleci orb validate "$orb_path"
  circleci orb publish "$orb_path" "$orb_name"
}

validate_local_config() {
  circleci config validate ../.circleci/config.yml
}
