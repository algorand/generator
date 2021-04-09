# Automation Environment Requirements

There are several environment variables listed in the [generator base image's `Dockerfile`](./Dockerfile) that are required when publishing using the generator base image.

The environment variables are not necessary when building the generator automation image nor when building an SDK's `Dockerfile`, only when running the SDK Docker image, because that is when publishing occurs.

Additionally, each SDK's `templates/Dockerfile` expects to be run in the context of the entire repo. This will almost always be the case, but it's worth noting that running the `Dockerfile` separately from the repository directory is not supported.
