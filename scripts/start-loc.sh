#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SERVICE_NAME="development-noetic"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yaml"
PRIVATE_ENV_FILE="${SCRIPT_DIR}/../.private/.env"
RUNTIME_ENV_FILE="${SCRIPT_DIR}/../.env"

HOST_VSCODE_DIR="${SCRIPT_DIR}/../.vscode-server"
HOST_ROS_LOG_DIR="${SCRIPT_DIR}/../logs/ros"
HOST_APP_LOG_DIR="${SCRIPT_DIR}/../logs/app"
HOST_CONFIG_DIR="${SCRIPT_DIR}/../config"

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

# Prepare host-side X11 and compose environment.
bash "${SCRIPT_DIR}/init-host-x11.sh"

# Export vars for this shell as well.
set -a
[ -f "$PRIVATE_ENV_FILE" ] && source "$PRIVATE_ENV_FILE"
source "$RUNTIME_ENV_FILE"
set +a

DEFAULT_WORKDIR="${DEV_HOME:-/home/dev}/catkin_ws"

# Ensure mounted host dirs are writable by current user.
ensure_writable_dir "$HOST_CONFIG_DIR"
ensure_writable_dir "$HOST_VSCODE_DIR"
ensure_writable_dir "$HOST_ROS_LOG_DIR"
ensure_writable_dir "$HOST_APP_LOG_DIR"
ensure_writable_dir "$HOST_WORKSPACE"

# Build local dev image (pulls BASE_IMAGE as needed).
echo "Building image..."
docker compose -f "$COMPOSE_FILE" build "$SERVICE_NAME"

# Always ensure container exists + running
echo "Starting container..."
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans "$SERVICE_NAME"

# Wait until container is ready (bail out if it exits)
echo "Waiting for container..."
for i in $(seq 1 15); do
    STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)
    if [ "$STATUS" = "running" ]; then break; fi
    if [ "$STATUS" = "exited" ] || [ "$STATUS" = "dead" ]; then
        echo "Container exited unexpectedly. Logs:"
        docker logs "$CONTAINER_NAME" 2>&1 | tail -20
        exit 1
    fi
    sleep 1
done

# Enter container
docker exec -it -w "$DEFAULT_WORKDIR" "$CONTAINER_NAME" bash