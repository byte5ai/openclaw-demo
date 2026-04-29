FROM ubuntu:24.04

ARG NODE_MAJOR=24
ARG TZ=Europe/Berlin

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=${TZ} \
    PNPM_HOME=/root/.local/share/pnpm \
    PATH=/root/.local/share/pnpm:/root/.local/bin:/usr/local/bin:/usr/bin:/bin

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg git \
        build-essential python3 pkg-config \
        sudo tzdata locales \
        jq unzip less vim nano tmux htop iputils-ping dnsutils \
        ffmpeg \
 && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
 && dpkg-reconfigure -f noninteractive tzdata \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && corepack enable \
 && corepack prepare pnpm@latest --activate \
 && npm install -g bun

WORKDIR /opt/openclaw

CMD ["/bin/bash", "-l"]
