FROM ubuntu:22.04

RUN apt update
RUN apt install -y wget bash curl ca-certificates iproute2 zip unzip
RUN apt update && \
    apt install -y python3 python3-pip && \
    apt install -y nodejs && \
    apt install -y php
RUN apt install -y sudo
RUN adduser --disabled-password --home / container

USER container
ENV USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
