# syntax=docker/dockerfile:1

ARG DEBIAN_VERSION=bookworm-slim
FROM debian:${DEBIAN_VERSION}

ARG TARGETARCH
ARG BRIDGE_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    dumb-init \
    libsecret-1-0 \
    pass \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Download tar.gz from GitHub Releases
RUN wget -O bridge.tar.gz \
      "https://github.com/ProtonMail/proton-bridge/releases/download/v${BRIDGE_VERSION}/protonmail-bridge-${BRIDGE_VERSION}.tar.gz" \
    && tar -xzf bridge.tar.gz \
    && rm bridge.tar.gz

# The extracted folder contains the binary
RUN install -m 755 protonmail-bridge*/protonmail-bridge /usr/local/bin/protonmail-bridge

WORKDIR /root

EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--"]
CMD ["protonmail-bridge"]
