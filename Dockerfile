# syntax=docker/dockerfile:1

# Build stage: use Debian sid so riscv/arm deps are available upstream;
# we only target arm64 in CI, but this matches the proven build env.
FROM debian:sid-slim AS build

ARG version=3.22.0

# Install build deps
RUN apt-get update \
 && apt-get install -y golang build-essential libsecret-1-dev ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# Fetch source at the given tag
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build

# Build headless bridge + vault-editor (same as shenxn)
RUN make build-nogui vault-editor

# Runtime stage
FROM debian:sid-slim

LABEL maintainer="Steve"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Runtime deps
RUN apt-get update \
 && apt-get install -y --no-install-recommends socat pass libsecret-1-0 ca-certificates dumb-init \
 && rm -rf /var/lib/apt/lists/*

# Copy scripts and binaries (same layout as shenxn)
COPY gpgparams entrypoint.sh /protonmail/
COPY --from=build /build/bridge /protonmail/
COPY --from=build /build/proton-bridge /protonmail/
COPY --from=build /build/vault-editor /protonmail/

ENTRYPOINT ["dumb-init", "--", "bash", "/protonmail/entrypoint.sh"]
