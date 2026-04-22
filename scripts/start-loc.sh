#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONTAINER="rr-localization-noetic"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.localization.yaml"

# Prepare host-side X11 and compose environment.
bash "${SCRIPT_DIR}/init-host-x11.sh"

# Export vars for this shell as well.
set -a
source "${SCRIPT_DIR}/../.env"
set +a

# Always ensure container exists + running
echo "Starting container..."
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

# Wait until container is ready
echo "Waiting for container..."
until docker exec "$CONTAINER" true 2>/dev/null; do
    sleep 1
done

# Enter container
docker exec -it "$CONTAINER" bash