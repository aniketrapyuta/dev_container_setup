#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

host_uid="$(id -u)"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

display="${DISPLAY:-:0}"
export DISPLAY="${display}"

if [[ -n "${HOST_XAUTHORITY:-}" && -f "${HOST_XAUTHORITY}" ]]; then
  host_xauthority="${HOST_XAUTHORITY}"
elif [[ -n "${XAUTHORITY:-}" && -f "${XAUTHORITY}" ]]; then
  host_xauthority="${XAUTHORITY}"
elif [[ -f "${HOME}/.Xauthority" ]]; then
  host_xauthority="${HOME}/.Xauthority"
elif [[ -f "/run/user/${host_uid}/gdm/Xauthority" ]]; then
  host_xauthority="/run/user/${host_uid}/gdm/Xauthority"
else
  echo "Could not find an Xauthority file on host. GUI apps like rviz may fail."
  host_xauthority="${HOME}/.Xauthority"
fi

export XAUTHORITY="${host_xauthority}"

# Permit local docker clients to connect to host X server.
if command -v xhost >/dev/null 2>&1; then
  xhost +SI:localuser:"$(id -un)" >/dev/null 2>&1 || true
  xhost +local:docker >/dev/null 2>&1 || true
fi
