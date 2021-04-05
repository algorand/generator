#!/usr/bin/env bash
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

# Build generator
mvn package

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
