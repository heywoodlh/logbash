FROM ubuntu:24.04
LABEL maintainer=heywoodlh

# Set some variables
ENV GID=1000
ENV UID=1000

# Install coreutils, and other potentially useful log parsing tools
RUN apt-get update && apt-get install -y coreutils ripgrep jq \
    && rm -rf /var/lib/apt/lists/*

# copy resources to /app
COPY . /app

# Remove examples directory from /app
RUN rm -rf /app/examples \
    && ln -s /app/logbash.sh /usr/local/bin/logbash

# Add unprivileged user
RUN userdel --remove ubuntu \
    && groupadd --gid $GID logbash \
    && useradd --home-dir /logbash --uid $UID --gid $GID --password "" --shell /bin/bash logbash \
    && chown -R $UID:$GID /app

USER logbash

ENTRYPOINT ["/app/logbash.sh"]
