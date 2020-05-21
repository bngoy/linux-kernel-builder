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
ROOTFS   		?= $(PWD)/root.cpio.gz

#########################
# Builder configuration #
#########################
BUILDER_LINUX_SRC_PATH=/src
BUILDER_LINUX_DIST_PATH=/dist
BUILDER_LINUX_CONFIG_FILE=$(BUILDER_CONFIGS_DIR)/$(KERNEL_ARCH)/$(KERNEL_VERSION)-$(KERNEL_CONFIG)/.config

# Export ARCH in builder environment to pre-select architecture for linux make
# commands
BUILDER_ENV=	-e ARCH=$(KERNEL_ARCH) 					\
				-e KERNEL_ARCH=$(KERNEL_ARCH) 			\

BUILDER_VOLUMES= -v $(PWD)/builder.mk:$(BUILDER_LINUX_SRC_PATH)/builder.mk:ro \
				 -v $(BUILDER_LINUX_CONFIG_FILE):/tmp/.config	  			  \
				 -v $(KERNEL_SRC_PATH):$(BUILDER_LINUX_SRC_PATH) 	     	  \
				 -v $(KERNEL_DIST):$(BUILDER_LINUX_DIST_PATH)		 		  \
				 -v $(PWD)/building:$(BUILDER_LINUX_SRC_PATH)/building/


