#!/usr/bin/env bash
set -e

# ==============================
# > BUILD GENERATOR
# ==============================

mvn package

# ==============================
# > CLONE SPECIFICATION REPOS
# ==============================

git clone https://github.com/algorand/go-algorand "$GO_ALGORAND_DIR"
git clone https://github.com/algorand/indexer "$INDEXER_DIR"
