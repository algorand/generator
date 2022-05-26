#!/usr/bin/env bash
set -e

function help() {
  echo "Entry point of our sdk code gen container."
  echo "-k|--sdk             - Which sdk to generate (GO,JS,JAVA,ALL)"
  exit
}

PARAMS=""

while (( "$#" )); do
  case "$1" in
    -k|--sdk)
      shift
      SDK=$1
      ;;
    -h)
      help
      ;;
    *) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
  shift
done

function generate_js {
  JS_SDK_DIR=/clones/js-algorand-sdk
  TEMPLATE_DIR=$GENERATOR_DIR/typescript_templates
  export GH_REPO=$JS_SDK_REPO
  git clone --depth 1 https://github.com/algorand/js-algorand-sdk $JS_SDK_DIR
  # Generate algod.
  $TEMPLATE \
    -s "$ALGOD_SPEC" \
    -t "$TEMPLATE_DIR" \
    -m "$JS_SDK_DIR/src/client/v2/algod/models" \
    -p "$TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/parameter_order_overrides.properties"

  pushd $JS_SDK_DIR
  npm install
  make format
  /publish.sh
}

function generate_go {
  GO_SDK_DIR=/clones/go-algorand-sdk
  TEMPLATE_DIR=$GENERATOR_DIR/go_templates
  export GH_REPO=$GO_SDK_REPO
  git clone https://github.com/algorand/go-algorand-sdk $GO_SDK_DIR
  # Generate algod.
  $TEMPLATE \
    -s $ALGOD_SPEC \
    -t $TEMPLATE_DIR \
    -m $GO_SDK_DIR/client/v2/common/models \
    -q $GO_SDK_DIR/client/v2/algod \
    -c $GO_SDK_DIR/client/v2/algod \
    -p $TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/algod_config.properties

  # Generate indexer.
  $TEMPLATE \
    -s $INDEXER_SPEC \
    -t $TEMPLATE_DIR \
    -m $GO_SDK_DIR/client/v2/common/models \
    -q $GO_SDK_DIR/client/v2/indexer \
    -c $GO_SDK_DIR/client/v2/indexer \
    -p $TEMPLATE_DIR/common_config.properties,$TEMPLATE_DIR/indexer_config.properties

  pushd $GO_SDK_DIR
  go fmt ./...
  /publish.sh
}

function generate_java {
  JAVA_SDK_DIR=/clones/java-algorand-sdk
  export GH_REPO=$JAVA_SDK_REPO
  git clone https://github.com/algorand/java-algorand-sdk $JAVA_SDK_DIR

 $GENERATOR \
    java \
    -c  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/common" \
    -cp "com.algorand.algosdk.v2.client.common" \
    -m  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/model" \
    -mp "com.algorand.algosdk.v2.client.model" \
    -n  "AlgodClient" \
    -p  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/algod" \
    -pp "com.algorand.algosdk.v2.client.algod" \
    -t  "X-Algo-API-Token" \
    -tr \
    -s  "$ALGOD_SPEC"

  # There is one enum only defined by indexer. Run this second to avoid
  # overwriting the second one.
  $GENERATOR \
    java \
    -c  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/common" \
    -cp "com.algorand.algosdk.v2.client.common" \
    -m  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/model" \
    -mp "com.algorand.algosdk.v2.client.model" \
    -n  "IndexerClient" \
    -p  "$JAVA_SDK_DIR/src/main/java/com/algorand/algosdk/v2/client/indexer" \
    -pp "com.algorand.algosdk.v2.client.indexer" \
    -t  "X-Indexer-API-Token" \
    -s  "$INDEXER_SPEC" 

  pushd $JAVA_SDK_DIR
  /publish.sh

}

function generate() {
  if [ -z "$SDK" ]
  then
    echo "Must define SDK to be generated!"
    help
    exit 1
  fi
  case "$1" in
    GO)
      generate_go
      ;;
    JS)
      generate_js
      ;;
    JAVA)
      generate_java
      ;;
    ALL)
      generate_go
      generate_js
      generate_java
      ;;
    *):
      echo "SDK generation for  $1 is not defined. Must be one of JS|GO|JAVA|ALL." >&2
      exit 1
  esac
}

generate $SDK

