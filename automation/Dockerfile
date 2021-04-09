FROM maven

ARG GITHUB_CLI_URL="https://github.com/cli/cli/releases/download/v1.8.1/gh_1.8.1_linux_amd64.tar.gz"

# Install GitHub cli
RUN mkdir gh \
  && curl -L ${GITHUB_CLI_URL} | tar -xz --strip-components=1 -C /gh \
  && ln -s /gh/bin/gh /bin/gh

# ------------------------------------
# Required environment variables
# ------------------------------------

# GitHub username
ENV GITHUB_USER=""
# GitHub access token
ENV GITHUB_TOKEN=""
# GitHub email
ENV GITHUB_EMAIL=""
# SDK repository in OWNER/REPO format
ENV GH_REPO="" 

# ------------------------------------

# Optional environment variables
ENV SKIP_PR="false"
# SDK repository branch, defaults to repository default
ENV BRANCH=""

# Utility environment variables
ENV GO_ALGORAND_DIR="/clones/go-algorand"
ENV INDEXER_DIR="/clones/indexer"

ENV TEMPLATE="java -jar /usr/src/app/target/generator-*-jar-with-dependencies.jar template"
ENV ALGOD_SPEC="${GO_ALGORAND_DIR}/daemon/algod/api/algod.oas2.json"
ENV INDEXER_SPEC="${INDEXER_DIR}/api/indexer.oas2.json"

WORKDIR /usr/src/app
COPY . .

# Build the generator and clone the spec repos
RUN ./automation/setup.sh \
  && chmod +x ./automation/publish.sh

# Copy repository files and use the automation/generate.sh script to detect and call the
# repository's templates/generate.sh script
ONBUILD WORKDIR /repo
ONBUILD COPY . .
ONBUILD RUN templates/generate.sh

# Open a PR if there is a repository present in the /repo directory
CMD /usr/src/app/automation/publish.sh
