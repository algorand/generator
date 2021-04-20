# Algorand SDK Code Generation Templates

Files in this directory are used by the [Algorand code generator](https://github.com/algorand/generator) when generating code and opening PRs.

## Instructions

### Generation script

Since different repositories have different requirements for code generation, we've outsourced the generation commands to each individual SDK repository through the use of a generation script. This file, named `generate.sh` and located in the SDK repository's `templates` directory, should contain every command required to generate code from the model schema. An example generation script is [included here](./generate.sh).

When run from the Docker container, the generation script will include the following environment variables:

- `$TEMPLATE` – A prebuilt `template` command
- `$ALGOD_SPEC` — The absolute path of the Algod spec file
- `$INDEXER_SPEC` — The absolute path of the indexer spec file

### Docker

A Docker environment is necessary for installing a repository's dependencies in order to run post-generation scripts and formatters. The `Dockerfile` is a multi-stage stage build with the following structure:

1. Builder - Takes the `algorand-generator` Docker image, builds the template command, and runs whatever commands are found in the `templates/generate.sh` script. The generated code is available afterwards in the `/repo` directory.
2. Formatter — With a different base image than before, this stage is used to install dependencies and format the code before publishing. For example, the JavaScript SDK uses the `node` base image, installs dependencies, and runs the `Prettier` code formatter. Be sure to copy generated code from the previous stage before preparing files for publishing. We encourage repositories to utilize a `make format` command during this stage to improve consistency across the SDKs.
3. Publisher — Reusing the image from the builder stage, the publish stage will create a new branch and open a pull request based on whatever code is found in the `/repo` directory. Make sure to copy the prepared code from the last stage.

We've included [an example `Dockerfile`](./Dockerfile) in the `examples` directory, similar to the one being used by the JavaScript SDK.
