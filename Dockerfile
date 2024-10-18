# Use ubuntu 24.04 (noble) as the base image
FROM ubuntu:noble

# Install necessary packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        ca-certificates \
        iproute2 \
        xz-utils \
        bzip2 \
        sudo \
        adduser && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN adduser --disabled-password --home /container container

# Switch to the new user
USER container
ENV USER=container
ENV HOME=/container
WORKDIR /container

# Copy scripts into the container
COPY ./entrypoint.sh /entrypoint.sh
COPY ./install.sh /install.sh
COPY ./run.sh /run.sh

# Set the default command
CMD ["/bin/bash", "/entrypoint.sh"]