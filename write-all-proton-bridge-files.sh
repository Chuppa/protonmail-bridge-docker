#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_DIR="$ROOT/.github/workflows"
WORKFLOW_PATH="$WORKFLOW_DIR/docker-build.yml"
DOCKERFILE_PATH="$ROOT/Dockerfile"
DOCKERIGNORE_PATH="$ROOT/.dockerignore"
README_PATH="$ROOT/README.md"
GITIGNORE_PATH="$ROOT/.gitignore"
COMPOSE_PATH="$ROOT/docker-compose.yml"
ENTRYPOINT_PATH="$ROOT/entrypoint.sh"
LICENSE_PATH="$ROOT/LICENSE"
ENV_EXAMPLE_PATH="$ROOT/.env.example"

mkdir -p "$WORKFLOW_DIR"

cat > "$DOCKERFILE_PATH" <<'DOCKERFILE'
# syntax=docker/dockerfile:1

############################
# Build stage
############################
FROM golang:1.25-bookworm AS builder

ARG BRIDGE_VERSION=3.22.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git gcc ca-certificates \
    libsecret-1-dev libglib2.0-dev libgpgme-dev libgpg-error-dev \
    libfido2-dev libcbor-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Clone the repo and ensure the requested tag exists; fail fast if not present
RUN git clone https://github.com/ProtonMail/proton-bridge.git . \
 && if git rev-parse --verify "refs/tags/v${BRIDGE_VERSION}" >/dev/null 2>&1; then \
      git checkout "v${BRIDGE_VERSION}"; \
    else \
      echo "Tag v${BRIDGE_VERSION} not found; aborting build" >&2; exit 1; \
    fi

ENV CGO_ENABLED=1 GOOS=linux GOARCH=arm64

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
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /app

EXPOSE 25 143

ENTRYPOINT ["dumb-init", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["proton-bridge"]
DOCKERFILE

cat > "$WORKFLOW_PATH" <<'YML'
name: Build and publish ARM64 ProtonMail Bridge

on:
  push:
    branches: ["main"]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Lowercase repo
        id: repo
        run: echo "repo=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')" >> "$GITHUB_OUTPUT"

      - uses: docker/setup-qemu-action@v3
      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push ARM64 image (pinned to 3.22.0)
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/arm64
          push: true
          tags: ghcr.io/${{ steps.repo.outputs.repo }}:3.22.0
          build-args: |
            BRIDGE_VERSION=3.22.0
YML

cat > "$DOCKERIGNORE_PATH" <<'DOCKERIGNORE'
.git
.gitignore
.github
node_modules
vendor
bin
tmp
*.log
*.tmp
.DS_Store
.env
DOCKERIGNORE

cat > "$GITIGNORE_PATH" <<'GITIGNORE'
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp

# Build
bin/
tmp/
*.log

# Secrets
.env
GITIGNORE

cat > "$README_PATH" <<'README'
# ProtonMail Bridge (ARM64 Docker build)

This repository contains a Dockerfile and GitHub Actions workflow to build an ARM64 headless ProtonMail Bridge binary from source (builds `./cmd/cli`).

This setup is pinned to **v3.22.0** to match available releases.

## Files created
- `Dockerfile` — multi-stage build (builds `./cmd/cli` for ARM64).
- `.github/workflows/docker-build.yml` — CI that builds and pushes an ARM64 image to GHCR.
- `.dockerignore`, `.gitignore`
- `docker-compose.yml` — local compose for testing.
- `entrypoint.sh` — runtime entrypoint wrapper.
- `.env.example` — example environment variables.
- `LICENSE` — MIT license.

## Local test
1. Build locally (requires buildx/qemu for ARM emulation):
   ```bash
   docker buildx build --platform linux/arm64 -t proton-bridge:local --load --build-arg BRIDGE_VERSION=3.22.0 .
