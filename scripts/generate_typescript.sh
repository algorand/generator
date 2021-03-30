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
  echo "   -indexer-spec  full path to indexer.oas3.yml"
  echo "   -algod-spec    full path to algod.oas3.yml"
}

function my_exit {
  popd > /dev/null
  exit $1
}

ALGOD_SPEC=/home/will/go/src/github.com/algorand/go-algorand/daemon/algod/api/algod.oas2.json
INDEXER_SPEC=/home/will/algorand/indexer/api/indexer.oas2.json
SDK_DIR=/home/will/algorand/js-algorand-sdk
TEMPLATE_DIR=/home/will/algorand/generator/typescript_templates

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
      template \
      -s "$ALGOD_SPEC" \
      -t "$TEMPLATE_DIR" \
      -m "$SDK_DIR/src/client/v2/algod/models" \
      -p "$TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/parameter_order_overrides.properties" \
