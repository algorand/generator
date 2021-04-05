# Algorand SDK Code Generation Templates

Files in this directory are used by the [Algorand code generator](https://github.com/algorand/generator) when generating code and opening PRs.

## Instructions

### Generation script

Since different repositories have different requirements for code generation and formatting, we've outsourced the generation commands to each individual SDK repository through the use of a generation script. This file, typically named `generate.sh`, should contain every command required to generate and format code from the model schema. An example generation script is [included here](./generate.sh).

This script will be used in the `Dockerfile` as the `CMD` argument. In practice, a distinct generation file separate from the `Dockerfile` is not necessary for simple scripts.

When run from the Docker container, the generation script will include the following environment variables:

- `$TEMPLATE` – A prebuilt `template` command
- `$ALGOD_SPEC` — The absolute path of the Algod spec file
- `$INDEXER_SPEC` — The absolute path of the indexer spec file

### Docker

A Docker environment is necessary for installing a repository's dependencies. Since the environment outlined above won't be included by default, you'll have to include environment variables in your Dockerfile like so:

```dockerfile
ENV TEMPLATE
ENV ALGOD_SPEC
ENV INDEXER_SPEC
```

Don't worry about setting values for these environment variables; they will be populated during runtime by the code generator automation.

#### Requirements

1. Since the code generation library requires a Java Runtime to run, be sure to include commands to install a JRE in your `Dockerfile`.
2. Be sure to use the `/repo` work directory. The generator will assume that is the location where the repo is stored when attempting to open a PR.

We've included [an example `Dockerfile`](./Dockerfile) in the `examples` directory, similar to the one being used by the JavaScript SDK.
