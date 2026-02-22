# syntax=docker/dockerfile:1

############################
# Build stage
############################
FROM golang:1.25-bookworm AS builder

ARG BRIDGE_VERSION=3.23.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git gcc ca-certificates \
    libsecret-1-dev libglib2.0-dev libgpgme-dev libgpg-error-dev \
    libfido2-dev libcbor-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Clone the repo and checkout the requested tag
RUN git clone --depth 1 https://github.com/ProtonMail/proton-bridge.git . \
    && git fetch --tags --depth=1 origin "v${BRIDGE_VERSION}" || true \
    && git checkout "v${BRIDGE_VERSION}" || true

ENV CGO_ENABLED=1 GOOS=linux GOARCH=arm64

# Ensure modules are downloaded and build the CLI entrypoint (exists in v3.23.0+)
RUN go mod download
RUN go build -ldflags="-s -w" -o /tmp/proton-bridge ./cmd/cli

############################
# Runtime stage
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
