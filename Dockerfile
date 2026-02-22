# syntax=docker/dockerfile:1

############################
# 1. Build Proton Bridge
############################
FROM golang:1.25-bookworm AS builder

ARG BRIDGE_VERSION
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    git make gcc \
    libsecret-1-dev libglib2.0-dev libgpgme-dev libgpg-error-dev \
    libfido2-dev libcbor-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone https://github.com/ProtonMail/proton-bridge.git . \
    && git checkout "v${BRIDGE_VERSION}"

ENV CGO_ENABLED=1

# Build correct binary per architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        GOARCH=amd64 make build-nogui && cp build/proton-bridge /tmp/proton-bridge ; \
    else \
        GOARCH=arm64 make build-cli && cp build/proton-bridge /tmp/proton-bridge ; \
    fi

############################
# 2. Runtime Image
############################
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates dumb-init \
    libsecret-1-0 libglib2.0-0 libgpgme11 libgpg-error0 \
    libfido2-1 libcbor0.8 libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/proton-bridge /usr/local/bin/proton-bridge

WORKDIR /app

EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--"]
CMD ["proton-bridge"]
