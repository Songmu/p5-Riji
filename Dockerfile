FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -yq \
      perl \
      build-essential \
      git \
      cpanminus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cpanm -qn Riji && \
    rm -rf /root/.cpanm

WORKDIR /app

ENTRYPOINT [ "riji" ]
