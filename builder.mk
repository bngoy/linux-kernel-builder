MAKE=make
ECHO=echo
CP=cp
Q=@
J=-j $(shell nproc)

ifeq ($(KERNEL_CONFIG_FILE),)
  $(error $KERNEL_CONFIG_FILE is not defined.)
  $(error Make $KERNEL_CONFIG_FILE point to the kernel configuration file (see make *config).)
endif

all:
	$(Q)$(ECHO) "This Makefile is used inside container"

# commands to run when make rules are called from outside of the container
# TODO: rename import_config
enter: container_config
	$(Q)# import the build configuration that has been mounted in /tmp from outside
	$(Q)# the container (see BUILDER_VOLUMES variable)
	$(Q)$(CP) $(KERNEL_CONFIG_FILE) .config

# export_config
leave:
	$(Q)# export the latest build configuration outside the container
	$(Q)$(CP) .config $(KERNEL_CONFIG_FILE)

menuconfig $(KERNEL_ARCH)_defconfig:
	$(MAKE) $(J) $@

shell:
	$(Q)bash

bzImage:
	$(MAKE) $(J) bzImage
	$(CP) arch/$(KERNEL_ARCH)/boot/bzImage $(DIST_DIR)
	$(CP) vmlinux $(DIST_DIR)

container_config: $(KERNEL_CONFIG_FILE)

$(KERNEL_CONFIG_FILE):
	$(Q)$(ECHO) "Linux kernel config file: '$@' is missing."
	$(Q)$(ECHO) "See $$BUILDER_VOLUMES and check $(KERNEL_CONFIG_FILE) is mounted."
	$(Q)exit 1

hello:
	#@gcc --static building/hello.c building/dl_syscalls.c -o building/init
	# build a rootfs containing init program
	@cd building && (find . | cpio -o -H newc | gzip > root.cpio.gz)

