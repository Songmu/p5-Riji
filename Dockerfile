FROM debian:stable-slim AS runtime-base

ENV LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -yq \
      perl \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM runtime-base AS build-base

RUN apt-get update && \
    apt-get install -yq \
      build-essential \
      curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM build-base AS snapshot

RUN curl -fsSLO https://raw.githubusercontent.com/skaji/cpm/main/cpm && \
    perl ./cpm install -g Carmel && \
    rm -rf ./cpm /root/.perl-cpm

WORKDIR /app

FROM build-base AS builder

COPY . riji

WORKDIR /riji

RUN curl -fsSLO https://raw.githubusercontent.com/skaji/cpm/main/cpm && \
    perl ./cpm install -g Carton::Snapshot && \
    perl ./cpm install -L /opt/riji \
      --resolver snapshot \
      --no-default-resolvers \
      . && \
    rm -rf ./cpm /root/.perl-cpm /riji

FROM runtime-base AS runtime

ENV PATH="/opt/riji/bin:${PATH}" \
    PERL5LIB="/opt/riji/lib/perl5"

COPY --from=builder /opt/riji /opt/riji

WORKDIR /riji

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
