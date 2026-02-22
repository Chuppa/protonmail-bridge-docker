# ProtonMail Bridge (ARM64 Docker build)

This repository contains a Dockerfile and GitHub Actions workflow to build an ARM64 headless ProtonMail Bridge binary from source (uses `cmd/cli` available in v3.23.0+).

## Files created
- `Dockerfile` — multi-stage build (builds `./cmd/cli` for ARM64).
- `.github/workflows/docker-build.yml` — CI that resolves a suitable ProtonMail Bridge tag (v3.23.0+), builds and pushes an ARM64 image to GHCR.
- `.dockerignore`, `.gitignore`
- `docker-compose.yml` — local compose for testing.
- `entrypoint.sh` — runtime entrypoint wrapper.
- `.env.example` — example environment variables.
- `LICENSE` — MIT license.

## Local test (optional)
1. Build locally (requires buildx/qemu for ARM emulation):
   ```bash
   docker buildx build --platform linux/arm64 -t proton-bridge:local --load --build-arg BRIDGE_VERSION=3.23.0 .

