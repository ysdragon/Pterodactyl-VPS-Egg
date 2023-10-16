FROM ubuntu:22.04

# Set noninteractive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y wget bash curl ca-certificates nginx iproute2 zip unzip sudo \
    && apt-get install -y --no-install-recommends python3 python3-pip php gnupg2 \
    && apt-get install -y libjansson4 \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:longsleep/golang-backports \
    && apt-get update \
    && apt-get install -y golang \
    && apt-get install -y make git lolcat figlet toilet \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home / container

# Add 'container' user to the sudo group
RUN usermod -aG sudo container

USER container
ENV USER container
ENV HOME /home/container
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
