########################
# kernel configuration #
########################
KERNEL_REPO_URL ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_SRC_PATH ?= $(PWD)/src
KERNEL_NAME     ?= $(lastword $(basename $(subst /, ,$(KERNEL_REPO_URL))))
KERNEL_CONFIG   ?= debug
KERNEL_ARCH     ?= x86_64
KERNEL_VERSION  ?= 4.10.8
KERNEL_FULL     ?= $(KERNEL_NAME)-$(KERNEL_CONFIG)-$(KERNEL_ARCH)-$(KERNEL_VERSION)
KERNEL_DIST		?= $(PWD)/dist/$(KERNEL_FULL)
KERNEL_IMAGE 	?= $(KERNEL_DIST)/bzImage
KERNEL_CONFIG_FILE ?= /tmp/.config
KERNEL_CROSS_COMPILE=ccache x86_64-linux-gnu-
ROOTFS   		?= $(PWD)/root.cpio.gz

#########################
# Builder configuration #
#########################
BUILDER_SRC_PATH_IN_LINUX=/src
BUILDER_DIST_PATH_IN_LINUX=/dist
BUILDER_CCACHE_PATH_IN_LINUX=/ccache
BUILDER_LINUX_CONFIG_FILE=$(BUILDER_CONFIGS_DIR)/$(KERNEL_ARCH)/$(KERNEL_VERSION)-$(KERNEL_CONFIG)/.config

# Export ARCH in builder environment to pre-select architecture for linux make
# commands
BUILDER_ENV=	-e ARCH=$(KERNEL_ARCH) 													\
							-e KERNEL_ARCH=$(KERNEL_ARCH)   								\
							-e CROSS_COMPILE="$(KERNEL_CROSS_COMPILE)"   		  \
							-e SRC_DIR=$(BUILDER_SRC_PATH_IN_LINUX) 				\
							-e DIST_DIR=$(BUILDER_DIST_PATH_IN_LINUX) 			\
							-e CCACHE_DIR=$(BUILDER_CCACHE_PATH_IN_LINUX) 	\
							-e KERNEL_CONFIG_FILE=$(KERNEL_CONFIG_FILE) 		\


BUILDER_VOLUMES= -v $(PWD)/builder.mk:$(BUILDER_SRC_PATH_IN_LINUX)/builder.mk:ro 	\
				 -v $(BUILDER_LINUX_CONFIG_FILE):$(KERNEL_CONFIG_FILE)	  			  			 	\
				 -v $(KERNEL_SRC_PATH):$(BUILDER_SRC_PATH_IN_LINUX) 	     	  						\
				 -v $(KERNEL_DIST):$(BUILDER_DIST_PATH_IN_LINUX)		 		  								\
				 -v $(BUILDER_CCACHE_DIR):$(BUILDER_CCACHE_PATH_IN_LINUX)		 		  		  	\
				 -v $(PWD)/building:$(BUILDER_SRC_PATH_IN_LINUX)/building/


