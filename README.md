# ROS Noetic Docker Dev Environment

This setup provides a persistent, reproducible ROS development environment using Docker.

## Features

- Persistent ROS workspace (`src`, `build`, `devel`, `install`)
- Persistent bash history
- Optional persistent ROS/custom logs (requires extra volume mounts)
- One-command container startup and shell access

## Prerequisites

- Docker
- Docker Compose
- Linux host (tested on Ubuntu)
- ROS workspace location on host: `~/localizationws`

## Host Directory Setup

Run the following on the host machine:

```bash
mkdir -p ~/localizationws/{src,build,devel,install}
mkdir -p ~/docker/rr_localization/.vscode-server
mkdir -p ~/docker/rr_localization/config

# Fix permissions
sudo chown -R $(id -u):$(id -g) ~/localizationws ~/docker/rr_localization
```

## One-Time Container Setup

Start and enter the localization container once:

```bash
docker compose -f ~/docker/docker-compose.localization.yaml up -d
docker exec -it rr-localization-noetic bash
```

## Configure Bash Inside Container

Edit `~/.bashrc` inside the container and add:

```bash
# ROS setup
source /opt/ros/noetic/setup.bash
[ -f ~/catkin_ws/devel/setup.bash ] && source ~/catkin_ws/devel/setup.bash

# Persistent bash history
export HISTFILE=/home/rr/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND="history -a; history -n"
```

## One-Command Startup Script

Make startup script executable:

```bash
chmod +x ~/docker/scripts/start-loc.sh
```

## Usage

Start and enter container:

```bash
~/docker/scripts/start-loc.sh
```

## Build Workspace

Inside container:

```bash
cd ~/catkin_ws
catkin build <package_name>
```

3. Run ROS nodes normally.

## Logs and History

### Bash History

Stored at:

- Host: `~/.bash_history`
- Container: `/home/rr/.bash_history`

### ROS Logs

Stored at:

- Default container path: `/home/rr/.ros/log`
- Host path: `~/docker/ros_logs`

### Custom Application Logs

Write custom logs to:

- Default container path: `/home/rr/logs`
- Host path: `~/docker/logs/app`

## VS Code Dev Container Workflow

This repository includes a ready-to-use Dev Container config at `.devcontainer/devcontainer.json`.

### First-time setup

1. Install the VS Code extension: `Dev Containers` (`ms-vscode-remote.remote-containers`).
2. Open this folder in VS Code (`~/docker`).
3. Run command palette action: `Dev Containers: Reopen in Container`.

VS Code will start the `rr-localization` compose service and attach into the container.

### Workflow

1. Edit source in VS Code.
2. Build and run in container terminal:

```bash
cd /home/rr/catkin_ws
catkin build
```

3. Launch ROS nodes from the same container terminal.

## Common Issues

### UID readonly variable

Do not use:

```bash
export UID=...
```

Use:

```bash
export DOCKER_UID=$(id -u)
export DOCKER_GID=$(id -g)
```

### Permission errors

Fix with:

```bash
sudo chown -R $(id -u):$(id -g) ~/localizationws ~/docker
```

### Workspace not sourced

Make sure `.bashrc` contains:

```bash
source /opt/ros/noetic/setup.bash
source ~/catkin_ws/devel/setup.bash
```

### Orphan containers warning

Use:

```bash
docker compose up -d --remove-orphans
```

## Custom Dev Image Packages

This repository builds a derived image from `quay.io/rapyuta/rr_localization` using `Dockerfile.localization`.

- Default build installs a practical core package set.
- Optional extended build installs additional ROS/debug/lint tooling.

### Build with core toolset (default)

```bash
docker compose -f docker-compose.localization.yaml build rr-localization-noetic
```

### Build with extended toolset

```bash
INSTALL_EXTRA_DEV_TOOLS=true docker compose -f docker-compose.localization.yaml build rr-localization-noetic
```
