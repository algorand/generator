#!/usr/bin/env bash
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

# ==============================
# > ARGUMENT PARSER
# ==============================

function help() {
  echo "Automated generator script to open PRs on spec changes."
  echo "-r|--repo - SDK GitHub repository."
  echo "-b|--branch — Branch for the repository."
  echo "-s|--skip-pr — Don't open a PR. Useful for testing "
  exit
}

REPO=
BRANCH=
SKIP_PR=false

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
    -s|--skip-pr)
      SKIP_PR=true
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

# Set up spec paths and details about each spec's latest commit
pushd ../go-algorand > /dev/null
ALGOD_SPEC="`pwd`/daemon/algod/api/algod.oas2.json"
ALGOD_SPEC_HASH=`git log -n 1 --pretty=format:%h -- daemon/algod/api/algod.oas2.json`
ALGOD_SPEC_COMMIT_MSG=`git log -n 1 --pretty=format:%s -- daemon/algod/api/algod.oas2.json`
popd > /dev/null
pushd ../indexer > /dev/null
INDEXER_SPEC="`pwd`/api/indexer.oas2.json"
INDEXER_SPEC_HASH=`git log -n 1 --pretty=format:%h -- api/indexer.oas2.json`
INDEXER_SPEC_COMMIT_MSG=`git log -n 1 --pretty=format:%s -- api/indexer.oas2.json`
popd > /dev/null

# Set up generator jar path
pushd ../../ > /dev/null
JAR_WILDCARD_PATTERN="`pwd`/target/generator-*-jar-with-dependencies.jar"
JAR_WILDCARD_FILES=($JAR_WILDCARD_PATTERN)
TEMPLATE_JAR=${JAR_WILDCARD_FILES[1]}
if [[ -z $TEMPLATE_JAR ]]; then
  TEMPLATE_JAR=${JAR_WILDCARD_FILES}
fi
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

# Don't continue if there were no changes
if git diff-index --quiet HEAD --; then
  echo "No changes after code generation, stopping"
  exit 0
fi

# Skip PR if the --skip-pr flag was set
if [ "$SKIP_PR" = true ];  then
  echo "Skip PR flag was set, stopping"
  exit 0
fi

# ==============================
# > CREATE BRANCH
# ==============================

# Generate an identifier for this PR (first four chars of algod/indexer hashes, concatenated)
PR_ID="${ALGOD_SPEC_HASH:0:4}${INDEXER_SPEC_HASH:0:4}"
PR_BRANCH="generate/$PR_ID"

# Don't continue if a remote branch has already been created
REMOTE_PR_BRANCH_EXISTS=`git ls-remote origin $PR_BRANCH | wc -l`
if [ $REMOTE_PR_BRANCH_EXISTS -eq 1 ]; then
  echo "Generated branch already exists, stopping"
  exit 1
fi

# Delete the branch if it exists locally
PR_BRANCH_EXISTS=`git branch -v | grep $PR_BRANCH | wc -l`
if [ $PR_BRANCH_EXISTS -eq 1 ]; then
  git checkout $BRANCH
  git branch -D $PR_BRANCH > /dev/null
fi

# Create a new branch
git checkout -b $PR_BRANCH

# Create commit and store hash
git add .
git commit -m "Regenerate code from specification file"

# ==============================
# > CREATE A PR
# ==============================

# Explicitly set repository in OWNER/REPO format
REPO_NAME="$(basename "$REPO" .git)"
REPO_DIRNAME="$(dirname "$REPO" .git)"
REPO_OWNER="$(basename "$REPO_DIRNAME")"
REPO_FULL_NAME="$REPO_OWNER/$REPO_NAME"

# Design PR content
ALGOD_REPO_URL="https://github.com/algorand/go-algorand"
INDEXER_REPO_URL="https://github.com/algorand/indexer"

PR_BODY="This PR was automatically created using [Algorand's code generator](https://github.com/algorand/generator) in response to the following commits:

### Algod

 - [$ALGOD_SPEC_HASH]($ALGOD_REPO_URL/commit/$ALGOD_SPEC_HASH) – $ALGOD_SPEC_COMMIT_MSG

### Indexer

 - [$INDEXER_SPEC_HASH]($INDEXER_REPO_URL/commit/$INDEXER_SPEC_HASH) - $INDEXER_SPEC_COMMIT_MSG


> **Disclaimer:** I'm just a bot. Feel free to make changes to this pull request as needed."

gh pr create \
  --repo $REPO_FULL_NAME \
  --base $BRANCH \
  --title "Regenerate code with the latest specification file ($PR_ID)" \
  --body "$PR_BODY" \
  --label "generated"