#!/usr/bin/env bash

# Global Variables
# Update the path here depending on folder you run command
# Best place to run script is the main directory
source ./scripts/variables.sh

ORB_DIR="${PWD}"
local_dir="${ORB_DIR}/src"
output_orb_name="ios.yml"

echo "packing local dir $local_dir"

# pack
circleci config pack "$local_dir" | tee "$local_dir"/"$output_orb_name"

# validate
circleci config validate "$local_dir"/"$output_orb_name"
