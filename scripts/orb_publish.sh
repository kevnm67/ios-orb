#!/usr/bin/env bash

# Global Variables
# Update the path here depending on folder you run command
# Best place to run script is the main directory

# Get the current script dir (this file)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

# shellcheck source=/dev/null
. "$SCRIPT_DIR"/variables.sh

# Set exit script if any statement returns falsy
set -e

# https://circleci.com/docs/2.0/local-cli/

declare script_dir="$ORB_DIR"/scripts

# shellcheck source=/dev/null
source "$script_dir"/orb_utility.sh

# shellcheck source=/dev/null
source "$script_dir"/colors.sh

#############
# Variables #
#############

export NAMESPACE="kevnm67"
export ORB_NAME="ios-orb"
export orb_version="0.0.1"

## Paths

# Project directory
BASE_DIR="${ORB_DIR}"

# Path to packed orb config
IOS_ORB="${ORB_DIR}/orb.yml"

#############
# Functions #
#############

publish_ios() {
    # publish dev version of orb

    IOS_ORB="$ORB_DIR/orb.yml"

    _pack_orb

    echo "publishing $IOS_ORB"

    circleci orb publish "$IOS_ORB" "${NAMESPACE}/${ORB_NAME}@dev:${orb_version}"

    # circleci orb publish promote "${NAMESPACE}/${ORB_NAME}@dev:${orb_version}" patch
}

_pack_orb() {
    ORB_DIR="$BASE_DIR/src/"
    ORB_FILE="orb.yml"
    ORB_PACK_PATH="${BASE_DIR}/$ORB_FILE"

    fancy_echo "Packing orb from $ORB_DIR to $ORB_PACK_PATH"

    circleci orb pack --skip-update-check "$ORB_DIR" >"$ORB_PACK_PATH"

    # validate
    # circleci config validate "$ORB_PACK_PATH"
}

is_ci() {
    local __resultvar="${CI}"
    local is_ci_result='false'

    if [[ "$__resultvar" ]]; then
        is_ci_result='true'
        fancy_echo "$is_ci_result"
    else
        fancy_echo "$is_ci_result"
    fi
}

_publish_locally() {
    fancy_echo "Running script locally..."
    publish_ios
}

exec_in_ci() {
    fancy_echo "Publishing a new orb version..."

    publish_ios

    circleci orb publish promote "${NAMESPACE}/${ORB_NAME}@${orb_version}" patch
}

main() {
    # get_published_orb_version ios-orb

    if [ "$(is_ci)" == true ]; then
        fancy_echo "Running in CI environment..."
        export is_ci=true
        exec_in_ci
    elif [[ -t 1 ]]; then
        _publish_locally
    else
        _publish_locally
    fi
}

########
# Main #
########

# TODO: Parameterize this script to publish orbs
# _pack_orb

main
