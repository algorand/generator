#!/usr/bin/env bash

# Regenerates the client code from the spec files.
#
# Builds and executes the generator CLI with parameters for the Java SDK.
#
#
# Example:
#    indexer repo cloned to ~/algorand/indexer
#    go-algorand repo cloned to ~/go/src/github.com/algorand/go-algorand
#
#    ./run_generator.sh \
#         -indexer-spec ~/algorand/indexer/api/indexer.oas2.json \
#         -algod-spec ~/go/src/github.com/algorand/go-algorand/daemon/algod/api/algod.oas2.json
#
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

function help {
  echo "Options:"
  echo "   --sdk-dir       full path to java SDK directory"
  echo "   --indexer-spec  full path to indexer.oas2.json"
  echo "   --algod-spec    full path to algod.oas2.json"
}

function my_exit {
  popd > /dev/null
  exit $1
}

INDEXER_SPEC=""
ALGOD_SPEC=""
#ALGOD_SPEC=/home/will/go/src/github.com/algorand/go-algorand/daemon/algod/api/algod.oas2.json
#INDEXER_SPEC=/home/will/algorand/indexer/api/indexer.oas2.json
SDK_DIR=/home/will/algorand/java-algorand-sdk

while [ "$1" != "" ]; do
    case "$1" in
        -s|--skip-build)
            SKIP_BUILD=1
            ;;
        -i|--indexer-spec)
            shift
            INDEXER_SPEC=$1
            ;;
        -a|--algod-spec)
            shift
            ALGOD_SPEC=$1
            ;;
        -k|--sdk-dir)
            shift
            SDK_DIR=$1
            ;;
        *)
            echo "Unknown option $1"
            help
            my_exit 0
            ;;
    esac
    shift
done

if [[ ! -f "$INDEXER_SPEC" ]]; then
  echo "Could not open indexer spec file at: '$INDEXER_SPEC'"
  help
  my_exit 1
fi

if [[ ! -f "$ALGOD_SPEC" ]]; then
  echo "Could not open algod spec file at: '$ALGOD_SPEC'"
  help
  my_exit 1
fi

if [ -z $SKIP_BUILD ]; then
  # Build generator.
  mvn package
fi

java -jar target/generator-*-jar-with-dependencies.jar \
       java \
       -c  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/common" \
       -cp "com.algorand.algosdk.v2.client.common" \
       -m  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/model" \
       -mp "com.algorand.algosdk.v2.client.model" \
       -n  "AlgodClient" \
       -p  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/algod" \
       -pp "com.algorand.algosdk.v2.client.algod" \
       -t  "X-Algo-API-Token" \
       -tr \
       -s  "$ALGOD_SPEC"

# There is one enum only defined by indexer. Run this second to avoid
# overwriting the second one.
java -jar target/generator-*-jar-with-dependencies.jar \
       java \
       -c  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/common" \
       -cp "com.algorand.algosdk.v2.client.common" \
       -m  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/model" \
       -mp "com.algorand.algosdk.v2.client.model" \
       -n  "IndexerClient" \
       -p  "$SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/indexer" \
       -pp "com.algorand.algosdk.v2.client.indexer" \
       -t  "X-Indexer-API-Token" \
       -s  "$INDEXER_SPEC"
