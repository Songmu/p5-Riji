FROM --platform=linux/amd64 debian:stable-slim

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
    curl -fsSLO https://raw.githubusercontent.com/skaji/cpm/main/cpm && \
    perl ./cpm install -g Carton::Snapshot && \
    perl ./cpm install -g \
      --resolver snapshot \
      --no-default-resolvers \
      . && \
    rm -rf ./cpm /root/.perl-cpm /riji

WORKDIR /riji

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
