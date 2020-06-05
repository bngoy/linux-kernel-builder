FROM debian:buster-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENTRYPOINT ["/bin/bash", "-c"]

# Install dependencies
RUN apt-get update               \
 && apt-get -y -q upgrade        \
 && apt-get -y -q install        \
    git                          \
    vim                          \
    build-essential              \
    bc                           \
    bison                        \
    flex                         \
    libssl-dev                   \
    libncurses-dev               \
    libelf-dev                   \
    cpio                         \
    ccache                       \
    wget                         \
 && apt-get clean                \
 && rm -rf /var/lib/apt/lists/*

# Default environment variable that should have already been be set in kernel.mk
ENV CCACHE_DIR=/ccache          \
    SRC_DIR=/src                \
    KERNEL_SRC_DIR=/src/kernel  \
    ROOTFS_SRC_DIR=/src/rootfs  \
    DIST_DIR=/dist              \
    EXTERNAL_KERNEL_CONFIG_FILE=/tmp/.config

RUN mkdir -p ${CCACHE_DIR}

WORKDIR ${SRC_DIR}

