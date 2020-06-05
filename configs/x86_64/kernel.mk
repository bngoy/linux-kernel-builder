########################
# kernel configuration #
########################
KERNEL_REPO_URL ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_SRC_PATH ?= $(PWD)/src/kernel
KERNEL_NAME     ?= $(lastword $(basename $(subst /, ,$(KERNEL_REPO_URL))))
KERNEL_CONFIG   ?= debug
KERNEL_ARCH     ?= x86_64
KERNEL_VERSION  ?= 4.10.8
KERNEL_FULL     ?= $(KERNEL_NAME)-$(KERNEL_CONFIG)-$(KERNEL_ARCH)-$(KERNEL_VERSION)
KERNEL_DIST		?= $(PWD)/dist/$(KERNEL_FULL)
KERNEL_IMAGE 	?= $(KERNEL_DIST)/bzImage
ROOTFS_SRC_PATH ?= $(PWD)/src/rootfs
ROOTFS   		?= $(KERNEL_DIST)/root.cpio.gz

KERNEL_CONFIG_FILE 		?= /tmp/.config
KERNEL_CROSS_COMPILE 	?= x86_64-linux-gnu-

#########################
# Builder configuration #
#########################
BUILDER_SRC_PATH_IN_LINUX=/src
BUILDER_KERNEL_SRC_PATH_IN_LINUX=/src/kernel
BUILDER_ROOTFS_SRC_PATH_IN_LINUX=/src/rootfs
BUILDER_DIST_PATH_IN_LINUX=/dist
BUILDER_CCACHE_PATH_IN_LINUX=/ccache
BUILDER_LINUX_CONFIG_FILE=$(BUILDER_CONFIGS_DIR)/$(KERNEL_ARCH)/$(KERNEL_VERSION)-$(KERNEL_CONFIG)/.config

# Export ARCH in builder environment to pre-select architecture for linux make
# commands
BUILDER_ENV=	-e ARCH=$(KERNEL_ARCH) 									\
				-e KERNEL_ARCH=$(KERNEL_ARCH)   						\
				-e CROSS_COMPILE="$(KERNEL_CROSS_COMPILE)"   			\
				-e SRC_DIR=$(BUILDER_SRC_PATH_IN_LINUX) 				\
				-e KERNEL_SRC_DIR=$(BUILDER_KERNEL_SRC_PATH_IN_LINUX) 	\
				-e ROOTFS_SRC_DIR=$(BUILDER_ROOTFS_SRC_PATH_IN_LINUX) 	\
				-e DIST_DIR=$(BUILDER_DIST_PATH_IN_LINUX) 				\
				-e CCACHE_DIR=$(BUILDER_CCACHE_PATH_IN_LINUX) 			\
				-e EXTERNAL_KERNEL_CONFIG_FILE=$(KERNEL_CONFIG_FILE)


BUILDER_VOLUMES= -v $(PWD)/builder.mk:$(BUILDER_SRC_PATH_IN_LINUX)/builder.mk:ro 	\
				 -v $(BUILDER_LINUX_CONFIG_FILE):$(KERNEL_CONFIG_FILE)	  			\
				 -v $(KERNEL_SRC_PATH):$(BUILDER_KERNEL_SRC_PATH_IN_LINUX) 			\
				 -v $(KERNEL_DIST):$(BUILDER_DIST_PATH_IN_LINUX)					\
				 -v $(BUILDER_CCACHE_DIR):$(BUILDER_CCACHE_PATH_IN_LINUX) 			\
				 -v $(ROOTFS_SRC_PATH):$(BUILDER_ROOTFS_SRC_PATH_IN_LINUX)

# -nographic : no 'pop-up' window, run qemu inside terminal
# -no-reboot : exit qemu on guest system reboot
# -kernel : kernel image to boot
# -initrd : initramfs to load
# -append : give linux kernel cli arguments
# -m: 	  : memory size in megabytes
# 'panic=1' : reboot on kernel panic
# 'console=ttyS0' : use qemu's ttyS0 device as console
RUN=$(QEMU_x86_64) -nographic -no-reboot -kernel $(KERNEL_DIST)/bzImage \
		-initrd $(KERNEL_DIST)/root.cpio.gz -append "panic=1 console=ttyS0"

# TODO -s ?
# TODO -S ?
DEBUG=$(QEMU_x86_64) -s -S -nographic -no-reboot -kernel $(KERNEL_DIST)/bzImage \
		-initrd $(KERNEL_DIST)/root.cpio.gz -append "panic=1 console=ttyS0 nokaslr" &
