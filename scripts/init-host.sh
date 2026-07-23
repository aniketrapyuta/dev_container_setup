#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

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

# Host directory paths
export HOST_VSCODE_DIR="${ROOT_DIR}/.vscode-server"
export HOST_ROS_LOG_DIR="${ROOT_DIR}/logs/ros"
export HOST_APP_LOG_DIR="${ROOT_DIR}/logs/app"
export HOST_CONFIG_DIR="${ROOT_DIR}/config"
export HOST_CACHE_DIR="${ROOT_DIR}/.cache"

# Ensure a directory exists and is writable by the current user
ensure_writable_dir() {
    local dir="$1"
    mkdir -p "$dir" 2>/dev/null || true
    if [ ! -w "$dir" ]; then
        chown -R "$(id -u):$(id -g)" "$dir" 2>/dev/null || true
    fi
    if [ ! -w "$dir" ]; then
        echo "ERROR: Host directory is not writable: $dir"
        echo "Run: sudo chown -R $(id -u):$(id -g) '$dir'"
        exit 1
    fi
}

ensure_writable_file() {
    local file="$1"
    mkdir -p "$(dirname "$file")" 2>/dev/null || true
    if [ ! -e "$file" ]; then
        touch "$file" 2>/dev/null || true
    fi
    if [ ! -w "$file" ]; then
        chown "$(id -u):$(id -g)" "$file" 2>/dev/null || true
    fi
    if [ ! -f "$file" ] || [ ! -w "$file" ]; then
        echo "ERROR: Host file is missing or not writable: $file"
        echo "Run: sudo chown $(id -u):$(id -g) '$file'"
        exit 1
    fi
}
