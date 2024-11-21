# Use Ubuntu 24.04 (noble) as the base image
FROM ubuntu:noble

# Set the environment variable to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

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
        locales \
        adduser && \
    rm -rf /var/lib/apt/lists/*

# Configure locale
RUN update-locale lang=en_US.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales

# Create a non-root user
RUN useradd -m -d /home/container -s /bin/bash container

# Switch to the new user
USER container
ENV USER=container
ENV HOME=/home/container

# Set the working directory
WORKDIR /home/container

# Copy scripts into the container
COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./install.sh /install.sh
COPY --chown=container:container ./run.sh /run.sh

# Make the copied scripts executable
RUN chmod +x /entrypoint.sh /install.sh /run.sh

# Set the default command
CMD ["/bin/bash", "/entrypoint.sh"]