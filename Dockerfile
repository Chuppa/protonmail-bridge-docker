# syntax=docker/dockerfile:1

ARG DEBIAN_VERSION=bookworm-slim
FROM debian:${DEBIAN_VERSION}

ARG TARGETARCH
ARG BRIDGE_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    dumb-init \
    libsecret-1-0 \
    pass \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN wget -O bridge.deb \
      "https://proton.me/download/bridge/protonmail-bridge_${BRIDGE_VERSION}_linux_${TARGETARCH}.deb" \
    && apt-get update \
    && apt-get install -y ./bridge.deb \
    && rm -f bridge.deb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--"]
CMD ["protonmail-bridge"]
