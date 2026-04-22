# Development Docker Environment

This repository provides a reproducible development container with persistent workspace data, logs, and VS Code server state.
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

Create local directories in this repository(gitignored):

```bash
mkdir -p .vscode-server config logs/ros logs/app
```

Create your host catkin workspace directory (set as `HOST_WORKSPACE` in `.private/env`):

```bash
mkdir -p /home/aniket/localizationws/{src,build,devel,install}
```

Fix ownership if needed:

```bash
sudo chown -R "$(id -u):$(id -g)" \
	.vscode-server config logs /home/aniket/localizationws
```

## Private Overrides

Create `.private/.env` (gitignored):

```bash
BASE_IMAGE=<your image name> # ex: osrf/ros:noetic-desktop-full # to develop over this image in docker
DEV_USER=dev # username inside docker container
DEV_HOME=/home/dev # home directory inside docker container
HOST_WORKSPACE=/home/aniket/localizationws # your local catkin workspace
INSTALL_EXTRA_DEV_TOOLS=true # install additional ros tooling like ros-noetic-tf2-ros, etc
```

Notes:

- `BASE_IMAGE` is the parent image used by `Dockerfile`.
- `HOST_WORKSPACE` must contain `src`, `build`, and `devel` directories.
- `scripts/start-loc.sh` loads `.private/.env` automatically.

## Start Workflow

```bash
chmod +x ./scripts/start-loc.sh
./scripts/start-loc.sh
```

The startup script will:

- prepare host X11 access, currently tested with ubuntu 24.04
- load `.private/.env` and runtime `.env`
- validate writable mounted directories
- build image
- start container
- attach shell at

## Build Inside Container

```bash
cd /home/dev/catkin_ws
catkin build
```

To build one package:

```bash
catkin build <package_name>
```

## Persistence Map

- Host `~/.bash_history` -> Container `/home/dev/.bash_history`
- Host `./logs/ros` -> Container `/home/dev/.ros/log`
- Host `./logs/app` -> Container `/home/dev/logs`
- Host `./config` -> Container `/home/dev/.config`
- Host `./.vscode-server` -> Container `/home/dev/.vscode-server`
- Host `${HOST_WORKSPACE}/src` -> Container `/home/dev/catkin_ws/src`
- Host `${HOST_WORKSPACE}/build` -> Container `/home/dev/catkin_ws/build`
- Host `${HOST_WORKSPACE}/devel` -> Container `/home/dev/catkin_ws/devel`

## VS Code Dev Container

This repository includes `.devcontainer/devcontainer.json`.

1. Install VS Code extension `Dev Containers`.
2. Open this repository folder in VS Code.
3. Run `Dev Containers: Reopen in Container`.

## Useful Commands

Build image only:

```bash
docker compose -f docker-compose.localization.yaml build <container_name>
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

- use `./scripts/start-loc.sh` so image is built before `up`
