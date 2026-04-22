ARG BASE_IMAGE=osrf/ros:noetic-desktop-full
FROM ${BASE_IMAGE}

ARG DEV_USER=dev
ARG DEV_HOME=/home/dev

USER root

# Set to true at build time to install extra tools:
# docker compose build --build-arg INSTALL_EXTRA_DEV_TOOLS=true development-noetic
ARG INSTALL_EXTRA_DEV_TOOLS=false

# Install core developer utilities by default and optional extended tooling.
RUN set -eux; \
        base_packages="\
            bash-completion \
            git \
            curl \
            wget \
            ca-certificates \
            gnupg2 \
            lsb-release \
            build-essential \
            cmake \
            pkg-config \
            ninja-build \
            ccache \
            gdb \
            valgrind \
            strace \
            lsof \
            htop \
            tmux \
            python3-pip \
            python3-venv \
            python3-dev \
            python3-setuptools \
            python3-wheel \
            python3-catkin-tools \
            clang-format \
            shellcheck \
            jq \
            iputils-ping \
            net-tools \
            iproute2 \
            dnsutils \
            openssh-client \
        "; \
        extra_packages="\
            clang-tidy \
            cppcheck \
            ros-noetic-rqt \
            ros-noetic-rqt-common-plugins \
            ros-noetic-rviz \
            ros-noetic-tf2-tools \
            ros-noetic-tf2-ros \
            ros-noetic-image-view \
            ros-noetic-diagnostic-updater \
            ros-noetic-roslint \
            ros-noetic-xacro \
            python3-rosdep \
            python3-rosinstall \
            python3-rosinstall-generator \
            python3-wstool \
        "; \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${base_packages}; \
        if [ "${INSTALL_EXTRA_DEV_TOOLS}" = "true" ]; then \
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${extra_packages}; \
        fi; \
        apt-get clean; \
        rm -rf /var/lib/apt/lists/*

    # Rename the existing UID-1000 user to DEV_USER and relocate home to DEV_HOME.
    RUN set -eux; \
        OLD_USER="$(getent passwd 1000 | cut -d: -f1)"; \
        OLD_GROUP="$(getent group 1000 | cut -d: -f1)"; \
        if [ -n "$OLD_USER" ] && [ "$OLD_USER" != "${DEV_USER}" ]; then \
            groupmod -n "${DEV_USER}" "$OLD_GROUP"; \
            usermod -l "${DEV_USER}" -d "${DEV_HOME}" -m "$OLD_USER"; \
        else \
            useradd -m -u 1000 -d "${DEV_HOME}" -s /bin/bash "${DEV_USER}"; \
        fi; \
        chown -R "${DEV_USER}:${DEV_USER}" "${DEV_HOME}"

    # Auto-source ROS and catkin workspace setup for interactive bash shells.
    RUN printf '\n# ROS workspace environment\nsource /opt/ros/noetic/setup.bash\n[ -f ${DEV_HOME}/catkin_ws/devel/setup.bash ] && source ${DEV_HOME}/catkin_ws/devel/setup.bash\n' >> /etc/bash.bashrc

    ENV HOME=${DEV_HOME}

# Return to the default non-root user used by this project.
    USER ${DEV_USER}
