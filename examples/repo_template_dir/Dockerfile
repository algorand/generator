# Use any base image here
FROM node:latest

# These environment variables will be populated automatically
ENV TEMPLATE ""
ENV ALGOD_SPEC ""
ENV INDEXER_SPEC ""

# Install Java (required by the code generator)
RUN apt-get update && apt-get install -y libasound2 libxtst6
RUN wget https://download.bell-sw.com/java/16+36/bellsoft-jdk16+36-linux-amd64.deb && \
    apt install ./bellsoft-jdk16+36-linux-amd64.deb

# Use the /repo work directory
WORKDIR /repo
COPY package*.json .

# Now you can install dependencies as needed
RUN npm install

# Copy everything else
COPY . .

# And then use any script you'd like here to generate code
CMD templates/generate.sh
