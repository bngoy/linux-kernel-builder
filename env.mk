# shell commands
ECHO=echo
RM=rm
CP=cp
MKDIR=mkdir
CAT=cat
TOUCH=touch
SED=sed
AWK=awk
GIT=git
GDB=gdb
DOCKER=docker
INSTALL=install
QEMU_x86_64=qemu-system-x86_64
BUILD_DIR=$(PWD)/build
Q=@

# kernel builder info
BUILDER_NAME=linux-kernel-builder
BUILDER_VERSION=0.0.1
BUILDER_IMAGE=$(BUILDER_NAME):$(BUILDER_VERSION)
BUILDER_DOCKERFILE=Dockerfile
BUILDER_BUILD_DIR=$(BUILD_DIR)/builder
BUILDER_CCACHE_DIR=$(PWD)/ccache
BUILDER_BUILD_DOCKERFILE=$(BUILDER_BUILD_DIR)/Dockerfile
BUILDER_CONFIGS_DIR=$(PWD)/configs
BUILDER_LATEST_CONFIG_FILE=$(PWD)/.kcfg
# variables for share point between a runnning linux and the host
BUILDER_SHARE_NAME=linux-kernel-builder-share
BUILDER_SHARE_DIR=$(PWD)/share
BUILDER_SHARE_FLAGS=-d --name $(BUILDER_SHARE_NAME) --privileged -p 2049:2049
BUILDER_SHARE_ENV=-e SHARED_DIRECTORY=/nfs
BUILDER_SHARE_VOLUMES=-v $(BUILDER_SHARE_DIR):/nfs
BUILDER_SHARE_IMAGE=itsthenetwork/nfs-server-alpine:latest
