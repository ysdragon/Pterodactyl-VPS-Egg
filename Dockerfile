FROM ubuntu:22.04

# Set noninteractive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y wget bash curl ca-certificates nginx iproute2 zip unzip sudo \
    && apt-get install -y --no-install-recommends python3 python3-pip php gnupg2 \
    && apt-get install -y libjansson4 \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:longsleep/golang-backports \
    && apt-get update \
    && apt-get install -y golang \
    && apt-get install -y make git lolcat figlet toilet \
    && rm -rf /var/lib/apt/lists/*


# Build and install Vlang from source
WORKDIR /opt/vlang
RUN git clone https://github.com/vlang/v /opt/vlang && make && ./v symlink

RUN adduser --disabled-password --home / container

# Add the container user to the sudo group and configure sudo
RUN usermod -aG sudo container && \
    echo "container ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER container
ENV USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
