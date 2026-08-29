# -------- Base --------
ARG BASE_IMAGE=osrf/ros:noetic-desktop-full
FROM ${BASE_IMAGE}

# Use bash for all RUN commands
SHELL ["/bin/bash", "-c"]

USER root

# -------- Build arguments --------
ARG DEV_USER=dev
ARG DEV_UID=1000
ARG DEV_GID=1000
ARG DEV_HOME=/home/${DEV_USER}
ARG INSTALL_EXTRA_DEV_TOOLS=true

ENV DEBIAN_FRONTEND=noninteractive

# -------- System + core dev tools --------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        locales \
        sudo \
    ; \
    rm -rf /var/lib/apt/lists/*

# -------- GitHub CLI (not packaged for focal/universe) --------
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    rm -rf /var/lib/apt/lists/*

# -------- Locale (ROS-friendly) --------
RUN set -eux; \
    locale-gen en_US.UTF-8; \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# -------- Optional ROS + dev extras --------
RUN set -eux; \
    if [ "${INSTALL_EXTRA_DEV_TOOLS}" = "true" ]; then \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            clang-tidy \
            cppcheck \
            ros-noetic-rqt \
            ros-noetic-rqt-common-plugins \
            ros-noetic-rviz \
            ros-noetic-tf2-tools \
            ros-noetic-image-view \
            ros-noetic-diagnostic-updater \
            ros-noetic-roslint \
            ros-noetic-xacro \
            ros-noetic-rosbridge-suite \
            ros-noetic-plotjuggler-ros \
            ros-noetic-jsk-visualization \
            python3-rosdep \
            python3-rosinstall \
            python3-rosinstall-generator \
            python3-wstool \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

# -------- Intel RealSense (librealsense2) --------
# The key published at librealsense.intel.com/Debian/librealsense.pgp no longer
# matches the key that signs the repo's InRelease file (Intel rotated it without
# updating that URL), so fetch the current signing key from the Ubuntu keyserver
# over HTTPS instead (avoids needing dirmngr for the keyserver protocol).
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -sSf "https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0xFB0B24895113F120" \
        | gpg --dearmor > /etc/apt/keyrings/librealsense.pgp; \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/librealsense.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        librealsense2-utils \
        librealsense2-dev \
        librealsense2-dbg \
        ros-noetic-realsense2-camera \
    ; \
    rm -rf /var/lib/apt/lists/*

# -------- Python tools (separate for caching) --------
RUN set -eux; \
    python3 -m pip install --no-cache-dir --upgrade pip

# Core Python deps
RUN set -eux; \
    if [ "${INSTALL_EXTRA_DEV_TOOLS}" = "true" ]; then \
        python3 -m pip install --no-cache-dir --ignore-installed \
            numpy \ 
            scipy \
            matplotlib \
            opencv-contrib-python \
            open3d \
            evo \
            ; \
    fi

# Dev-only Python tools
RUN set -eux; \
    if [ "${INSTALL_EXTRA_DEV_TOOLS}" = "true" ]; then \
        python3 -m pip install --no-cache-dir --ignore-installed \
            flake8 \
            flake8-docstrings \
            flake8-import-order \
            flake8-bugbear \
            pre-commit \
            ; \
    fi

# -------- Create non-root user safely --------
RUN set -eux; \
    if id -u ${DEV_USER} >/dev/null 2>&1; then \
        echo "User ${DEV_USER} already exists, reusing"; \
    elif getent passwd ${DEV_UID} >/dev/null; then \
        OLD_USER="$(getent passwd ${DEV_UID} | cut -d: -f1)"; \
        OLD_GROUP="$(getent passwd ${DEV_UID} | cut -d: -f4)"; \
        echo "UID ${DEV_UID} belongs to ${OLD_USER}, renaming to ${DEV_USER}"; \
        groupmod -n ${DEV_USER} "$(getent group ${OLD_GROUP} | cut -d: -f1)"; \
        usermod -l ${DEV_USER} -d /home/${DEV_USER} -m ${OLD_USER}; \
    else \
        echo "Creating new user ${DEV_USER}"; \
        groupadd -g ${DEV_GID} ${DEV_USER}; \
        useradd -m -u ${DEV_UID} -g ${DEV_GID} -s /bin/bash ${DEV_USER}; \
    fi; \
    usermod -aG sudo ${DEV_USER}; \
    echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DEV_USER}; \
    chmod 0440 /etc/sudoers.d/${DEV_USER}

# -------- ROS environment setup --------
RUN set -eux; \
    echo "source /opt/ros/noetic/setup.bash" >> /etc/skel/.bashrc; \
    echo "[ -f ~/catkin_ws/install/setup.bash ] && source ~/catkin_ws/install/setup.bash" >> /etc/skel/.bashrc; \
    echo "[ -f ~/catkin_ws/devel/setup.bash ] && source ~/catkin_ws/devel/setup.bash" >> /etc/skel/.bashrc

# Apply skeleton config to existing user
RUN set -eux; \
    cp /etc/skel/.bashrc ${DEV_HOME}/.bashrc; \
    chown ${DEV_UID}:${DEV_GID} ${DEV_HOME}/.bashrc

# -------- (Optional) rosdep init --------
RUN set -eux; \
    if command -v rosdep >/dev/null 2>&1; then \
        rosdep init || true; \
        rosdep update || true; \
    fi

# -------- Environment --------
ENV HOME=${DEV_HOME}
WORKDIR ${DEV_HOME}

# -------- Switch to non-root --------
USER ${DEV_USER}

CMD ["bash"]