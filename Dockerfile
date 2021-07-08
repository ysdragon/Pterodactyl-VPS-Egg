FROM quay.io/jitesoft/ubuntu:18.04
RUN apt update
RUN apt install -y wget bash curl ca-certificates nginx iproute2 zip unzip
RUN apt install -y sudo 
RUN adduser --disabled-password --home / container

USER container
ENV  USER container
ENV HOME /
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
