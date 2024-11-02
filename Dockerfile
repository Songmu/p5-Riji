FROM debian:stable-slim

ENV LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=en_US.UTF-8

COPY . riji

WORKDIR /riji

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -yq \
      perl \
      build-essential \
      curl \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    sh -c 'curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | \
           perl - install --without-test -g .' && \
    rm -rf /root/.perl-cpm /riji

WORKDIR /riji

ENTRYPOINT [ "riji" ]
