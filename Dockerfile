FROM ubuntu:22.04

# Set noninteractive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y wget bash curl ca-certificates nginx iproute2 zip unzip sudo \
    && apt-get install -y --no-install-recommends python3 python3-pip nodejs php \
    && apt-get install -y libjansson4 \
    && apt-get install -y gnupg2 \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && curl -fsSL https://packages.longsleep.net/key.txt | apt-key add - \
    && echo "deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu jammy main" > /etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-jammy.list \
    && apt-get update \
    && apt-get install -y golang \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home / container

USER container
ENV USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
