cat > entrypoint.sh <<'ENTRY'
#!/usr/bin/env bash
set -euo pipefail

# If arguments are provided, run them; otherwise run proton-bridge
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec proton-bridge
fi
ENTRY

chmod +x entrypoint.sh
