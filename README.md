# Development Docker Environment

This repository provides a reproducible development container with persistent workspace data, logs, VS Code server state, and also copilot state.
I am currently using this to develop over with ROS Noetic packages on ubuntu 24.04

## What You Get

- Containerized ROS Noetic workflow
- Persistent catkin workspace from host
- Persistent ROS logs and custom app logs
- Persistent shell history
- One command to build, start, and attach

## Prerequisites

- Docker
- Docker Compose
- Linux host (tested on Ubuntu)

## Host Setup

`scripts/init-host.sh` auto-creates and fixes ownership of the 
repo-local dirs (`.vscode-server`, `config`, `logs/ros`, `logs/app`)
and the `HOST_WORKSPACE` subdirs (`src`, `build`, `devel`, `logs`,
`.catkin_tools`) on every run, whether you start via
`./scripts/start-container.sh` or VS Code's "Reopen in Container".

If ownership ever drifts (e.g. a dir got created as root some other way):

```bash
sudo chown -R "$(id -u):$(id -g)" .vscode-server config logs "$HOST_WORKSPACE" "$HOST_DATA_DIR"
```

Note: the script only fixes the top-level dir automatically on each run — a
root-owned *subdirectory* inside (e.g. left over from a container that once
ran as root) won't be auto-detected, since that would require a full
recursive scan on every startup. Run the command above if you hit
`Permission denied` on a specific path.

## Environment Config

Create `.env` in repository root (gitignored), for example:

```bash
BASE_IMAGE=<your image name> # ex: osrf/ros:noetic-desktop-full # to develop over this image in docker
DEV_USER=dev # username inside docker container
DEV_HOME=/home/dev # home directory inside docker container
HOST_WORKSPACE=/home/aniket/localizationws # your local catkin workspace
HOST_DATA_DIR=/home/aniket/data # your local data dir, mounted at ${DEV_HOME}/data
IMAGE_NAME=my-dev-image # your custom image name
CONTAINER_NAME=my-dev-container # your custom container name
INSTALL_EXTRA_DEV_TOOLS=true # install additional ros tooling like ros-noetic-tf2-ros, etc
DOCKER_UID=1000
DOCKER_GID=1000
DISPLAY=:0
HOST_XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.M9W8N3 # for ubuntu24.04 wayland
```

Notes:

- `BASE_IMAGE` is the parent image used by `Dockerfile`.
- `HOST_WORKSPACE` subdirs (`src`, `build`, `devel`) are auto-created by `scripts/init-host.sh`.
- `scripts/init-host.sh` refreshes runtime keys inside `.env`.

## Start Workflow

```bash
chmod +x ./scripts/start-container.sh
./scripts/start-container.sh
```

The startup script will:

- prepare host X11 access, currently tested with ubuntu 24.04
- validate writable mounted directories
- build image
- start container
- attach shell at

## Build Inside Container

```bash
cd /home/dev/catkin_ws
source install/setup.bash # build over previously installed packages, assuming installed packages are here
catkin init
catkin build <package_name>
```

## Persistence Map

- Host `~/.bash_history` -> Container `/home/dev/.bash_history`
- Host `./logs/ros` -> Container `/home/dev/.ros/log`
- Host `./logs/app` -> Container `/home/dev/logs`
- Host `./.cache` -> Container `/home/dev/.cache`
- Host `./config` -> Container `/home/dev/.config`
- Host `./.vscode-server` -> Container `/home/dev/.vscode-server`
- Host `${HOST_WORKSPACE}/src` -> Container `/home/dev/catkin_ws/src`
- Host `${HOST_WORKSPACE}/build` -> Container `/home/dev/catkin_ws/build`
- Host `${HOST_WORKSPACE}/devel` -> Container `/home/dev/catkin_ws/devel`

Note: bash only writes history to `~/.bash_history` on a clean shell exit. Since containers are often killed/rebooted without one, the host `~/.bashrc` needs:

```bash
export PROMPT_COMMAND="history -a; history -n"
```

This flushes and reloads history after every command instead of waiting for shell exit, so the mounted `~/.bash_history` stays up to date.

## VS Code Dev Container

This repository includes `.devcontainer/devcontainer.json`.

1. Install VS Code extension `Dev Containers`.
2. Open this repository folder in VS Code.
3. Run `Dev Containers: Reopen in Container`.

## Useful Commands

Build image only:

```bash
docker compose -f docker-compose.yaml build <container_name>
```

Start without attaching:

```bash
docker compose -f docker-compose.yaml up -d --remove-orphans
```

Open shell in running container:

```bash
docker exec -it -w /home/dev/catkin_ws <container_name> bash
```

## Troubleshooting

Container exits at startup:

- check logs: `docker logs container_name`

Permission denied under `/home/dev/.config`:

- ensure host `./config` is writable by your user
- rerun: `sudo chown -R "$(id -u):$(id -g)" config`

Compose tries to pull `<container_name>`:

- use `./scripts/start-container.sh` so image is built before `up`

Dev Containers fails with unset compose vars (`IMAGE_NAME`, `CONTAINER_NAME`, `HOST_WORKSPACE`):

- run `bash scripts/init-host.sh` once, then retry `Dev Containers: Reopen in Container`
