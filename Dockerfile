FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y wget bash curl ca-certificates nginx iproute2 zip unzip sudo && \
    apt-get install -y --no-install-recommends python3 python3-pip nodejs php && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home / container

USER container
ENV USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
