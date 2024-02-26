FROM debian:bookworm

# Set noninteractive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl ca-certificates iproute2 xz-utils bzip2 \
    && rm -rf /var/lib/apt/lists/*

USER container
ENV USER container
ENV HOME /home/container
WORKDIR /

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
