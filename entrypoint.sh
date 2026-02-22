#!/usr/bin/env bash
set -euo pipefail

cd /protonmail

# Default: run bridge in daemon mode
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec ./proton-bridge
fi
