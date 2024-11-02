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
      git \
      cpanminus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cpanm -qn Carmel && \
    carmel install && \
    carmel package && \
    cpanm --from $(pwd)/vendor/cache --quiet --notest . && \
    rm -rf /root/.cpanm /root/.carmel /riji

WORKDIR /riji

ENTRYPOINT [ "riji" ]
