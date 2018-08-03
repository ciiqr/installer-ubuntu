FROM ubuntu:18.04
WORKDIR /app

# install dependencies
RUN apt-get update
RUN apt-get install -y xorriso rsync wget

# Copy files
COPY . ./

# `docker run` calls generate.sh
ENTRYPOINT ["/app/generate.sh"]
