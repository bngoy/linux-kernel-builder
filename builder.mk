MAKE=make
ECHO=echo
CP=cp
Q=@
J=-j $(shell nproc)
BUILDER_LINUX_CONFIG_FILE=/tmp/.config

all:
	$(Q)$(ECHO) "This Makefile is used inside container"

# commands to run when make rules are called from outside of the container
enter: container_config
	$(Q)# import the build configuration that has been mounted in /tmp from outside
	$(Q)# the container (see BUILDER_VOLUMES variable)
	$(Q)$(CP) $(BUILDER_LINUX_CONFIG_FILE) .config

leave:
	$(Q)# export the latest build configuration outside the container
	$(Q)$(CP) .config $(BUILDER_LINUX_CONFIG_FILE)

menuconfig $(KERNEL_ARCH)_defconfig:
	$(MAKE) $(J) $@

shell:
	$(Q)bash

bzImage:
	$(MAKE) $(J) bzImage
	$(CP) arch/$(KERNEL_ARCH)/boot/bzImage $(DIST_DIR)
	$(CP) vmlinux $(DIST_DIR)

container_config: $(BUILDER_LINUX_CONFIG_FILE)

$(BUILDER_LINUX_CONFIG_FILE):
	$(Q)$(ECHO) "Linux kernel config file: '$@' is missing."
	$(Q)$(ECHO) "See $$BUILDER_VOLUMES and check $(BUILDER_LINUX_CONFIG_FILE) is mounted."
	$(Q)exit 1

hello:
	@gcc --static building/hello.c -o building/init
	@cd building && (find . | cpio -o -H newc | gzip > root.cpio.gz)

