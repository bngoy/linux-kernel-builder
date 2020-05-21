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
    binutils-arm-linux-gnueabihf \
    gcc-arm-linux-gnueabihf      \
    cpio                         \
 && apt-get clean                \
 && rm -rf /var/lib/apt/lists/*

# Fetch the kernel
ENV CCACHE_DIR=/ccache        \
    SRC_DIR=/src              \
    DIST_DIR=/dist

RUN mkdir -p ${CCACHE_DIR}

WORKDIR ${SRC_DIR}

