FROM ubuntu:22.04

# Set timezone
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update \
    && apt-get install -y wget bash curl ca-certificates nginx iproute2 zip unzip sudo \
    && apt-get install -y --no-install-recommends python3 python3-pip nodejs php \
    && apt-get install -y libjansson4 \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home / container

USER container
ENV USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
