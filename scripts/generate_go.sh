#!/usr/bin/env bash
set -e

rootdir=`dirname $0`
pushd $rootdir/.. > /dev/null

function help() {
  echo "Wrapper to the generate template command to call algod/indexer + go fmt."
  echo "-s|--skip-build   - Skip building the generator."
  echo "-a|--algod-spec   - Algod specfile."
  echo "-i|--indexer-spec - Indexer specfile."
  echo "-k|--sdk-dir      - Go SDK directory."
  echo "-t|--template-dir - Template directory."
  exit
}

ALGOD_SPEC=/home/will/go/src/github.com/algorand/go-algorand/daemon/algod/api/algod.oas2.json
INDEXER_SPEC=/home/will/algorand/indexer/api/indexer.oas2.json
SDK_DIR=/home/will/go/src/github.com/algorand/go-algorand-sdk
TEMPLATE_DIR=/home/will/algorand/generator/go_templates

PARAMS=""

while (( "$#" )); do
  case "$1" in
    -s|--skip-build)
      SKIP_BUILD=1
      ;;
    -a|--algod-spec)
      shift
      ALGOD_SPEC=$1
      ;;
    -i|--indexer-spec)
      shift
      INDEXER_SPEC=$1
      ;;
    -k|--sdk-dir)
      shift
      SDK_DIR=$1
      ;;
    -t|--template-dir)
      shift
      TEMPLATE_DIR=$1
      ;;
    -h)
      help
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      ;;
  esac
  shift
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ -z $SKIP_BUILD ]; then
  # Build generator.
  mvn package
fi

# Generate algod.
java -jar target/generator-*-jar-with-dependencies.jar \
    template \
    -s $ALGOD_SPEC \
    -t $TEMPLATE_DIR \
    -m $SDK_DIR/client/v2/common/models \
    -q $SDK_DIR/client/v2/algod \
    -p $TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/algod_config.properties

# Generate indexer.
java -jar target/generator-*-jar-with-dependencies.jar \
    template \
    -s $INDEXER_SPEC \
    -t $TEMPLATE_DIR \
    -m $SDK_DIR/client/v2/common/models \
    -q $SDK_DIR/client/v2/indexer \
    -p $TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/indexer_config.properties

# Run go fmt to fix the stuff I didn't get quite right in the templates.
pushd $SDK_DIR
go fmt ./...
