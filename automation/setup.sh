#!/usr/bin/env bash
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

# ==============================
# > BUILD GENERATOR
# ==============================

mvn package


# ==============================
# > CLONE SPECIFICATION REPOS
# ==============================

GO_ALGORAND_DIR="clones/go-algorand"
INDEXER_DIR="clones/indexer"

# Clone or pull indexer and algod repos
if [[ -d "$GO_ALGORAND_DIR" ]]; then
  pushd "$GO_ALGORAND_DIR" > /dev/null
  git pull
  popd > /dev/null
else
  git clone https://github.com/algorand/go-algorand "$GO_ALGORAND_DIR"
fi

if [[ -d "$INDEXER_DIR" ]]; then
  pushd "$INDEXER_DIR" > /dev/null
  git pull
  popd > /dev/null
else
  git clone https://github.com/algorand/indexer "$INDEXER_DIR"
fi

# ============================================================
# > SET UP GIT CREDENTIALS
# ------------------------------------------------------------
#
# GitHub credentials require only a `GITHUB_TOKEN` environment
# variable, but `git` credentials require explicit setup.
#
# ============================================================

git config credential.helper '!f() { sleep 1; echo "username=${GITHUB_USER}"; echo "password=${GITHUB_TOKEN}"; }; f'
