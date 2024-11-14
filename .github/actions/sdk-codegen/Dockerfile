FROM golang:1.23.3

ARG GITHUB_CLI_URL="https://github.com/cli/cli/releases/download/v1.8.1/gh_1.8.1_linux_amd64.tar.gz"

# Manually install npm
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y maven openjdk-17-jdk nodejs

ENV TMP_DIR=/tmp
ENV GH_DIR=$TMP_DIR/gh
WORKDIR $TMP_DIR
# Install GitHub cli
RUN mkdir $GH_DIR \
  && curl -L ${GITHUB_CLI_URL} | tar -xz --strip-components=1 -C $GH_DIR \
  && ln -s $GH_DIR/bin/gh /bin/gh

# ------------------------------------
# Required environment variables
# ------------------------------------
# GitHub username
ENV GITHUB_USER="codegen-user"
# GitHub email
ENV GITHUB_EMAIL="codegen@algorand.com"
# SDK repository in OWNER/REPO format
ENV GITHUB_URL_BASE="https://github.com/"
ENV GO_ALGORAND_REPO="algorand/go-algorand"
ENV INDEXER_REPO="algorand/indexer"
ENV JS_SDK_REPO="algorand/js-algorand-sdk"
ENV GO_SDK_REPO="algorand/go-algorand-sdk"
ENV JAVA_SDK_REPO="algorand/java-algorand-sdk"

# ------------------------------------
# Utility environment variables
# ------------------------------------
ENV GO_ALGORAND_DIR="/clones/go-algorand"
ENV INDEXER_DIR="/clones/indexer"
ENV GENERATOR_DIR="/clones/generator"

# Retrieve spec files
RUN git clone --depth 1 $GITHUB_URL_BASE$GO_ALGORAND_REPO "$GO_ALGORAND_DIR"
RUN git clone --depth 1 $GITHUB_URL_BASE$INDEXER_REPO "$INDEXER_DIR"
ENV ALGOD_SPEC="${GO_ALGORAND_DIR}/daemon/algod/api/algod.oas2.json"
ENV INDEXER_SPEC="${INDEXER_DIR}/api/indexer.oas2.json"

# Build generator 
RUN git clone --depth 1 https://github.com/algorand/generator $GENERATOR_DIR
WORKDIR $GENERATOR_DIR
RUN mvn package
ENV TEMPLATE="java -jar ${GENERATOR_DIR}/target/generator-*-jar-with-dependencies.jar template"
ENV GENERATOR="java -jar ${GENERATOR_DIR}/target/generator-*-jar-with-dependencies.jar"

# Run
COPY publish.sh /publish.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chmod +x /publish.sh
ENTRYPOINT ["/entrypoint.sh"]
