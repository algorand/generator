#!/usr/bin/env bash

# Utility script to run setup.sh and then generate.sh for each repository
# set in the GH_REPOS environment variable.

set -e

rootdir=`dirname $0`
pushd $rootdir > /dev/null

function repeat() {
  # Usage: repeat [symbol] [count] [ending]
  printf "$1"'%.s' $(eval "echo {1.."$(($2))"}")
  printf "$3"
}

function log_section_header() {
  # Usage: log_section_header "title" will print:
  # ===============
  # > title
  # ===============
  header_len=${#1}
  end_buffer=10
  divider_len=$(($header_len+$end_buffer))
  echo ""
  repeat "=" $divider_len "\n"
  echo "> $1"
  repeat "=" $divider_len "\n"
  echo ""
}

log_section_header "Running setup script"
./setup.sh

IFS=', ' read -r -a REPOS <<< "$GH_REPOS"
for REPO in "${REPOS[@]}"
do
  log_section_header "Starting generation for $REPO"

  # Break repository URL into repo/branch segments
  IFS='#' read -r -a REPO_SEGMENTS <<< "$REPO"
  REPO_URL="${REPO_SEGMENTS[0]}"
  BRANCH="${REPO_SEGMENTS[1]}"

  # Run generation script, don't stop if there is an early stop
  ./generate.sh \
    --repo "$REPO_URL" \
    --branch "$BRANCH" \
  || true
done