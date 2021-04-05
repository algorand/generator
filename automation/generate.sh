#!/usr/bin/env bash
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

# ==============================
# > ARGUMENT PARSER
# ==============================

function help() {
  echo "Automated generator script to open PRs on spec changes."
  echo "-r|--repo - SDK GitHub repository, including the particular branch."
  exit
}

REPO=
BRANCH=

while (( "$#" )); do
  case "$1" in
    -r|--repo)
      REPO=$2
      shift
      ;;
    -b|--branch)
      BRANCH=$2
      shift
      ;;
    *)
      echo "Unknown option $1"
      help
      ;;
  esac
  shift
done

# Guard against REPO being unset
if [ -z $REPO ]; then
  echo "Error: Repo argument must be set"
  exit 1
fi

# ==============================
# > GIT CLONE
# ==============================

function gclonecd() {
  # Clone or pull a repo and then pushd afterwards
  # Usage: gcloned [repo] [branch]
  REPO_NAME="$(basename "$1" .git)"
  if [[ -d "./$REPO_NAME" ]]; then
    pushd "$REPO_NAME" > /dev/null
    git fetch origin "$2"
    git reset --hard origin/"$2"
  else
    git clone -b "$2" "$1" && pushd "$REPO_NAME" > /dev/null
  fi
}

# Create clones directory if one doesn't exist
if [[ ! -d clones ]]; then
  mkdir clones
fi

# Clone repo and cd into it
pushd clones > /dev/null
gclonecd $REPO $BRANCH

# ==============================
# > RUNNER
# ==============================

# Set up paths
pushd .. > /dev/null
ALGOD_SPEC="`pwd`/go-algorand/daemon/algod/api/algod.oas2.json"
INDEXER_SPEC="`pwd`/indexer/api/indexer.oas2.json"
pushd .. > /dev/null
JAR_WILDCARD_PATTERN="`pwd`/target/generator-*-jar-with-dependencies.jar"
JAR_WILDCARD_FILES=($JAR_WILDCARD_PATTERN)
TEMPLATE_JAR=${JAR_WILDCARD_FILES[1]}
popd > /dev/null
popd > /dev/null

# Error if a Dockerfile is not present
if [[ ! -f templates/Dockerfile ]]; then
  echo "Error: Could not find Dockerfile in the repo's templates directory"
  exit 1
fi

# Remove existing containers
docker rm code-gen > /dev/null || true

# Run the repo's Dockerfile, populated with necessary environment variables
docker build -t code-gen-img -f templates/Dockerfile .
docker run \
  -v "$ALGOD_SPEC":/mnt/algod.json \
  -v "$INDEXER_SPEC":/mnt/indexer.json \
  -v "$TEMPLATE_JAR":/mnt/generator.jar \
  -e ALGOD_SPEC="/mnt/algod.json" \
  -e INDEXER_SPEC="/mnt/indexer.json" \
  -e TEMPLATE="java -jar /mnt/generator.jar template" \
  --name code-gen \
  code-gen-img
docker cp code-gen:/repo/. .

# Cleanup
docker rm code-gen > /dev/null

# Don't continue if the generate script failed
if [ $? -ne 0 ]; then
  echo "Error: repo's Dockerfile failed, stopping"
  exit 1
fi

# ==============================
# > CREATE BRANCH
# ==============================



# ==============================
# > CREATE A PR
# ==============================
