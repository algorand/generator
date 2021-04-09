#!/usr/bin/env bash
set -e

# Navigate to the /repo directory
cd /repo

# Don't continue if there are no files in the /repo directory
if [ -z "$(ls -A ./)" ]; then
  echo "Error: /repo directory is empty"
  exit 1
fi

# Don't continue if there were no changes
if git diff-index --quiet HEAD --; then
  echo "No changes after code generation, stopping"
  exit 0
fi

# Skip PR if the SKIP_PR build arg is set to true
if [ "$SKIP_PR" = true ];  then
  echo "Skip PR flag was set, stopping"
  exit 0
fi

# ============================================================
# > SET UP GIT
# ------------------------------------------------------------
#
# GitHub credentials require only a `GITHUB_TOKEN` environment
# variable, but `git` credentials require explicit setup.
#
# ============================================================

git config credential.helper '!f() { sleep 1; echo "username=${GITHUB_USER}"; echo "password=${GITHUB_TOKEN}"; }; f'
git config --global pull.ff only
git config --global user.name "Algorand Generation Bot"
git config --global user.email "$GITHUB_EMAIL"

# ========================================================
# > PULL LATEST CHANGES & EXPORT DATA FROM SPEC FILES
# ========================================================

pushd "$GO_ALGORAND_DIR" > /dev/null
git pull
export ALGOD_SPEC_HASH=`git log -n 1 --pretty=format:%h -- daemon/algod/api/algod.oas2.json`
export ALGOD_SPEC_COMMIT_MSG=`git log -n 1 --pretty=format:%s -- daemon/algod/api/algod.oas2.json`
popd > /dev/null
pushd "$INDEXER_DIR" > /dev/null
git pull
export INDEXER_SPEC_HASH=`git log -n 1 --pretty=format:%h -- api/indexer.oas2.json`
export INDEXER_SPEC_COMMIT_MSG=`git log -n 1 --pretty=format:%s -- api/indexer.oas2.json`
popd > /dev/null

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

# Push
git push --set-upstream origin $PR_BRANCH

# ==============================
# > CREATE A PR
# ==============================

# Design PR content
ALGOD_REPO_URL="https://github.com/algorand/go-algorand"
INDEXER_REPO_URL="https://github.com/algorand/indexer"

PR_BODY="This PR was automatically created using [Algorand's code generator](https://github.com/algorand/generator), in response to the following commits:

### Algod

 - [$ALGOD_SPEC_HASH]($ALGOD_REPO_URL/commit/$ALGOD_SPEC_HASH) – $ALGOD_SPEC_COMMIT_MSG

### Indexer

 - [$INDEXER_SPEC_HASH]($INDEXER_REPO_URL/commit/$INDEXER_SPEC_HASH) - $INDEXER_SPEC_COMMIT_MSG


> **Disclaimer:** I'm just a bot. Feel free to make changes to this pull request as needed."

# Only set the branch base if a BRANCH environment variable has been set
if [[ ! -z "$BRANCH" ]]; then
  BASE_ARG_PAIR="--base $BRANCH"
fi

gh pr create \
  --repo $GH_REPO \
  $BASE_ARG_PAIR \
  --title "Regenerate code with the latest specification file ($PR_ID)" \
  --body "$PR_BODY" \
  --label "generated"