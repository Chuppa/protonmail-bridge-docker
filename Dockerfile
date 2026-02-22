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

WORKDIR /tmp

# GitHub Releases naming pattern:
# protonmail-bridge_<VERSION>-1_<ARCH>.deb
RUN wget -O bridge.deb \
      "https://github.com/ProtonMail/proton-bridge/releases/download/v${BRIDGE_VERSION}/protonmail-bridge_${BRIDGE_VERSION}-1_${TARGETARCH}.deb" \
    && apt-get update \
    && apt-get install -y ./bridge.deb \
    && rm -f bridge.deb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# SMTP + IMAP
EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--"]
CMD ["protonmail-bridge"]
