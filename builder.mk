############
# Binaries #
############
MAKE=make
ECHO=echo
MKDIR=mkdir
CD=cd
CP=cp

ifeq ($(EXTERNAL_KERNEL_CONFIG_FILE),)
  $(error $$EXTERNAL_KERNEL_CONFIG_FILE is not defined.)
  $(error Make $$EXTERNAL_KERNEL_CONFIG_FILE point to the kernel configuration file (see make *config).)
endif

#############
# Constants #
#############
Q=@
J=-j $(shell nproc)
ROOTFS=$(DIST_DIR)/root.cpio.gz
ROOTFS_BUILD_DIR=$(ROOTFS_SRC_DIR)/build
KERNEL_CONFIG_FILE=$(KERNEL_SRC_DIR)/.config

all:
	$(Q)$(ECHO) "This Makefile is used inside container"

# commands to run when make rules are called from outside of the container
# TODO: rename import_config
enter: container_config
	$(Q)# import the build configuration that has been mounted in /tmp from outside
	$(Q)# the container (see BUILDER_VOLUMES variable)
	$(Q)$(CP) $(EXTERNAL_KERNEL_CONFIG_FILE) $(KERNEL_CONFIG_FILE)

# export_config
leave:
	$(Q)# export the latest build configuration outside the container
	$(Q)$(CP) $(KERNEL_CONFIG_FILE) $(EXTERNAL_KERNEL_CONFIG_FILE)

menuconfig $(KERNEL_ARCH)_defconfig:
	$(MAKE) $(J) $@

shell:
	$(Q)bash

bzImage:
	$(MAKE) -C $(KERNEL_SRC_DIR) $(J) bzImage
	$(CP) $(KERNEL_SRC_DIR)/arch/$(KERNEL_ARCH)/boot/bzImage $(DIST_DIR)
	$(CP) $(KERNEL_SRC_DIR)/vmlinux $(DIST_DIR)

container_config: $(EXTERNAL_KERNEL_CONFIG_FILE)

$(EXTERNAL_KERNEL_CONFIG_FILE):
	$(Q)$(ECHO) "Linux kernel config file: '$@' is missing."
	$(Q)$(ECHO) "See $$BUILDER_VOLUMES and check $(EXTERNAL_KERNEL_CONFIG_FILE) is mounted."
	$(Q)exit 1

rootfs: $(ROOTFS)

$(ROOTFS):
	$(Q)$(ROOTFS_SRC_DIR)/make_rootfs.sh $(ROOTFS_BUILD_DIR)
	$(Q)$(CD) $(ROOTFS_BUILD_DIR) && (find . | cpio -o -H newc | gzip > $@)

$(ROOTFS_BUILD_DIR):
	$(Q)$(MKDIR) -p $@


