FROM debian:bullseye
LABEL maintainer=heywoodlh

# Set some variables
ENV GID 1000
ENV UID 1000

# Install coreutils, and other potentially useful log parsing tools
RUN apt-get update && apt-get install -y coreutils ripgrep jq \
    && rm -rf /var/lib/apt/lists/*

# copy resources to /app
COPY . /app

# Remove examples directory from /app
RUN rm -rf /app/examples

# Add unprivileged user
RUN groupadd -g $GID user \
    && useradd -h /app -u $UID -g $GID -s /bin/bash logbash \
    && chown -R $UID:$GID /app

VOLUME /app/modules
VOLUME /app/config.sh

USER logbash

ENTRYPOINT ["/app/logbash.sh"]
