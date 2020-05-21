include env.mk

# Let make help work even if KCFG is not set
ifneq (help, $(firstword $(MAKECMDGOALS)))
ifeq ($(KCFG),)
  # Read latest config
  ifeq ($(wildcard $(BUILDER_LATEST_CONFIG_FILE)),$(BUILDER_LATEST_CONFIG_FILE))
    KCFG=$(shell $(CAT) $(BUILDER_LATEST_CONFIG_FILE))
  else
    $(error "Kernel config name is missing, undefined KCFG variable.")
  endif
else
  # if no latest config file exists
  ifeq (,$(wildcard $(BUILDER_LATEST_CONFIG_FILE)))
    $(shell $(ECHO) $(KCFG) > $(BUILDER_LATEST_CONFIG_FILE))
    $(info '$(KCFG)' saved as default config in '$(BUILDER_LATEST_CONFIG_FILE)'.)
  else
    # Write new default config if required
    ifneq ($(KCFG), $(shell $(CAT) $(BUILDER_LATEST_CONFIG_FILE)))
      $(shell $(ECHO) $(KCFG) > $(BUILDER_LATEST_CONFIG_FILE))
      $(info '$(KCFG)' saved as default config in '$(BUILDER_LATEST_CONFIG_FILE)'.)
    else
      $(info Default config: '$(KCFG)'.)
    endif
  endif
endif
include $(KCFG)/kernel.mk
endif


all: help

help:
	$(Q)$(ECHO) "General commands:"
	$(Q)$(ECHO) " - info 		Print all configuration variables"
	$(Q)$(ECHO) " - print-<VAR>		Print the content of <VAR> variable"
	$(Q)$(ECHO) " - build_builder 	Build the kernel builder image"
	$(Q)$(ECHO) " - shell 		Open a shell in a kernel builder container"
	$(Q)$(ECHO) " - serve 		Run in background a kernel builder container"
	$(Q)$(ECHO) " - shell_exec 		Execute $$SHELL_EXEC_CMD shell command in the kernel builder previously served"

info:
	$(Q)$(ECHO) "KERNEL_REPO_URL:   $(KERNEL_REPO_URL)"
	$(Q)$(ECHO) "KERNEL_SRC_PATH:   $(KERNEL_SRC_PATH)"
	$(Q)$(ECHO) "KERNEL_NAME:       $(KERNEL_NAME)"
	$(Q)$(ECHO) "KERNEL_CONFIG:     $(KERNEL_NAME)"
	$(Q)$(ECHO) "KERNEL_ARCH:       $(KERNEL_ARCH)"
	$(Q)$(ECHO) "KERNEL_VERSION:    $(KERNEL_VERSION)"
	$(Q)$(ECHO) "KERNEL_FULL:       $(KERNEL_FULL)"
	$(Q)$(ECHO) "KERNEL_IMAGE:      $(KERNEL_IMAGE)"
	$(Q)$(ECHO) "BUILDER_ENV:       $(BUILDER_ENV)"
	$(Q)$(ECHO) "BUILDER_VOLUMES:   $(BUILDER_VOLUMES)"

print-%:
	$(ECHO) $* = $($*)

get_source_code: $(KERNEL_SRC_PATH)

$(KERNEL_SRC_PATH):
	$(GIT) clone $(KERNEL_REPO_URL) $@

build_builder: $(BUILDER_BUILD_DIR) $(BUILDER_BUILD_DOCKERFILE)
	$(DOCKER) build -t $(BUILDER_IMAGE) $(BUILDER_BUILD_DIR)

$(BUILDER_BUILD_DIR):
	$(MKDIR) -p $@

# Move Dockerfile into a dedicated build directory to avoid sending giga bytes
# of contextual data during the 'docker build' command
$(BUILDER_BUILD_DOCKERFILE): $(BUILDER_BUILD_DIR) $(BUILDER_DOCKERFILE)
	$(CP) $(BUILDER_DOCKERFILE) $(BUILDER_BUILD_DOCKERFILE)

# Run container in background and keep it alive for further remote call
serve:
	$(DOCKER) run -d $(BUILDER_ENV) $(BUILDER_VOLUMES) $(BUILDER_IMAGE) \
		'while true; do sleep 1; done'

# '::' force call
shell_exec::
	$(DOCKER) exec -it `$(DOCKER) ps -f ancestor=$(BUILDER_IMAGE) \
		-f status=running -lq` $(SHELL_EXEC_CMD)

defconfig: $(KERNEL_ARCH)_defconfig

# '::' force call
shell menuconfig $(KERNEL_ARCH)_defconfig:: local_config
	$(DOCKER) run -it -h $(BUILDER_IMAGE) $(BUILDER_ENV) $(BUILDER_VOLUMES) \
		$(BUILDER_IMAGE) 'make -f builder.mk enter $@ leave'

build_kernel: build_$(KERNEL_ARCH)

build_$(KERNEL_ARCH): local_config
	$(DOCKER) run -it -h $(BUILDER_IMAGE) $(BUILDER_ENV) $(BUILDER_VOLUMES) \
		$(BUILDER_IMAGE) 'make -f builder.mk enter bzImage leave'

local_config: $(BUILDER_LINUX_CONFIG_FILE)

$(KERNEL_CONFIG_FILE):
	$(Q)$(ECHO) "Linux kernel config file: '$@' is missing."
	$(Q)exit 1

hello::
	$(DOCKER) run -it $(BUILDER_ENV) $(BUILDER_VOLUMES) $(BUILDER_IMAGE) \
		'make -f builder.mk enter $@ leave'
	$(Q)# -nographic : no 'pop-up' window, run qemu inside terminal
	$(Q)# -no-reboot : exit qemu on guest system reboot
	$(Q)# -kernel : kernel image to boot
	$(Q)# -initrd : initramfs to load
	$(Q)# -append : give linux kernel cli arguments
	$(Q)# 'panic=1' : reboot on kernel panic
	$(Q)# 'console=ttyS0' : use qemu's ttyS0 device as console
	$(QEMU_x86_64) -nographic -no-reboot -kernel $(KERNEL_DIST)/bzImage \
		-initrd building/root.cpio.gz -append "panic=1 console=ttyS0"

hello_debug::
	$(QEMU_x86_64) -s -S -nographic -no-reboot -kernel $(KERNEL_DIST)/bzImage \
		-initrd building/root.cpio.gz -append "panic=1 console=ttyS0 nokaslr" &

distclean:
	$(RM) -rf $(KERNEL_SRC_PATH) $(KERNEL_DIST) $(BUILDER_LATEST_CONFIG_FILE)

