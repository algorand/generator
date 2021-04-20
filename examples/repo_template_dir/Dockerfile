# ==============================
# > BUILD AND GENERATE
# ==============================

FROM algorand-generator as generator

# ... generator will build its jar file here and run the SDK repo's generation script ...

# ==============================
# > PER-SDK SECTION (FORMAT)
# ==============================

# Use any base image here
FROM node:latest as formatter

# Copy files from previous build stage
COPY --from=generator /repo /repo
WORKDIR /repo

# Now you can install dependencies as needed
RUN npm install

# And then use any script you'd like here to format code
RUN make format

# ==============================
# > PUBLISH
# ==============================
FROM generator as publisher

# Copy work directory from previous stage to the /repo directory
COPY --from=formatter /repo /repo

# This line is implicitly run by default, but I included it for context:
# -> It will create a new branch and open a PR
CMD /scripts/publish.sh