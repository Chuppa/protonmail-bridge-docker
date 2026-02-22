# syntax=docker/dockerfile:1

############################
# 1. Build Proton Bridge
############################
FROM golang:1.25-bookworm AS builder

ARG BRIDGE_VERSION
ARG TARGETARCH

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    make \
    gcc \
    libsecret-1-dev \
    libfido2-dev \
    libcbor-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Clone Proton Bridge source at the correct version
RUN git clone https://github.com/ProtonMail/proton-bridge.git . \
    && git checkout "v${BRIDGE_VERSION}"

# Build for the correct architecture
ENV CGO_ENABLED=1
RUN GOARCH=${TARGETARCH} make build-nogui

############################
# 2. Runtime Image
############################
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dumb-init \
    libsecret-1-0 \
    pass \
    gnupg \
    libfido2-1 \
    libcbor0 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binary
COPY --from=builder /src/build/proton-bridge /usr/local/bin/proton-bridge

EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--"]
CMD ["proton-bridge"]
