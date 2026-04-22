#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

uid="$(id -u)"
gid="$(id -g)"
display="${DISPLAY:-:0}"

if [[ -n "${XAUTHORITY:-}" && -f "${XAUTHORITY}" ]]; then
  host_xauthority="${XAUTHORITY}"
elif [[ -f "${HOME}/.Xauthority" ]]; then
  host_xauthority="${HOME}/.Xauthority"
elif [[ -f "/run/user/${uid}/gdm/Xauthority" ]]; then
  host_xauthority="/run/user/${uid}/gdm/Xauthority"
else
  echo "Could not find an Xauthority file on host. GUI apps like rviz may fail."
  host_xauthority="${HOME}/.Xauthority"
fi

cat > "${ROOT_DIR}/.env" <<EOF
DOCKER_UID=${uid}
DOCKER_GID=${gid}
DISPLAY=${display}
HOST_XAUTHORITY=${host_xauthority}
EOF

# Permit local docker clients to connect to host X server.
if command -v xhost >/dev/null 2>&1; then
  xhost +SI:localuser:"$(id -un)" >/dev/null 2>&1 || true
  xhost +local:docker >/dev/null 2>&1 || true
fi
