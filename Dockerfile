# syntax=docker/dockerfile:1

############################
# Build (ARM64 only)
############################
FROM --platform=linux/arm64 golang:1.25-bookworm AS builder

ARG BRIDGE_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    git make gcc \
    libsecret-1-dev libglib2.0-dev libgpgme-dev libgpg-error-dev \
    libfido2-dev libcbor-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone https://github.com/ProtonMail/proton-bridge.git . \
    && git checkout "v${BRIDGE_VERSION}"

ENV CGO_ENABLED=1 GOARCH=arm64

# Build CLI directly (Makefile does NOT support ARM64)
RUN go build -o /tmp/proton-bridge ./cmd/cli

############################
# Runtime (ARM64 only)
############################
FROM --platform=linux/arm64 debian:bookworm-slim

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
