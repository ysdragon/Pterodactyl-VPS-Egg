# Use Ubuntu noble (24.04) as the base image
FROM ubuntu:noble

# Set the environment variable to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set the PRoot version
ENV PROOT_VERSION=5.4.0

# Install necessary packages
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

# Install PRoot
RUN ARCH=$(uname -m) && \
    mkdir -p /usr/local/bin && \
    proot_url="https://github.com/ysdragon/proot-static/releases/download/v${PROOT_VERSION}/proot-${ARCH}-static" && \
    curl -Ls "$proot_url" -o /usr/local/bin/proot && \
    chmod 755 /usr/local/bin/proot

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
COPY --chown=container:container ./helper.sh /helper.sh
COPY --chown=container:container ./run.sh /run.sh

# Make the copied scripts executable
RUN chmod +x /entrypoint.sh /install.sh /helper.sh /run.sh

# Set the default command
CMD ["/bin/bash", "/entrypoint.sh"]
