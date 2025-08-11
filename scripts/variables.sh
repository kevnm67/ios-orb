#!/usr/bin/env bash

##
 # Set up the environment variables for all files to use
 # These include the project directory as the base dir
 # Use this file when reaching for a file in project
 #
 # ${var%/*} - remove everything after the last occurrence of /.
 # ${var##*/} - remove everything up to the last occurrence of /.

# Get the current script dir (this file)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

# Get the name of the project, in case user renamed when cloning.
# Otherwise, this should return the word `orbs`
PROJECT_NAME="${SCRIPT_DIR%'/scripts'*}" # Remove everything after and including '/scripts'
PROJECT_NAME="${PROJECT_NAME##*/}" # Remove everytyhing before last '/'

# Remove everything after and including PROJECT_NAME for a clean DIR
CLEAN_DIR="${SCRIPT_DIR%"$PROJECT_NAME"*}"

# Final directory (removing current directory of this file → ./scripts)
export ORB_DIR="${CLEAN_DIR}${PROJECT_NAME}"
