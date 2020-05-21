# Linux Kernel Builder

**linux-kernel-builder**, *lkb* for short, is a tool, to ease the configuration
and building of Linux kernels. It uses Docker to create 'ready to use' Linux
kernel build environment (a **builder**), and Makefiles to store and build
'ready to use' Linux kernel configurations.

## Dockerfile
*lkb* uses docker container technology to create a *builder* container that
encaspulates a Linux kernel build environment and its dependencies.  See
[Dockerfile](Dockerfile) for the list of installed dependencies.

Note: During the build of a Linux kernel, *lkb* copies the
[Dockerfile](Dockerfile) into a **builder** directories, to avoid sending the
whole source code (giga bytes...) into the container build context.

## TL;TR
Build an already existing configuration:
1. `make help` 
2. `make KCFG=configs/<arch> info` where `<arch>` is a subdirectory of
   [config](config)
3. `make get_source_code` to get Linux source code
3. `make build_builder` to build the containerized Linux build environment
4. `make build_kernel` to build a linux kernel

## Makefile
*lkb* uses `Makefiles` to configure, build and run a Linux kernel. Run `make
help` to see the list of available commands. *lkb* makefiles define a set a
variable that configures the 'containerized' Linux kernel build environment,
and *lkb* it-self.

### lkb configuration
`env.mk` contains *lkb* host environment variables, and *lkb* info.

### builder configuration
The **builder** is the 'containerized' Linux build environment. *builder*
configuration is located in `$KCFG/kernel.mk` file where `$KCFG` is a variable
pointing to a [configs](configs) subdirectory.

In this file, use `BUILDER_ENV` to define specific environment variables in
your builder environment, e.g `ARCH`, `CROSS_COMPILE`...

### Linux configuration
`.config` contains the Linux configuration to build. This file is initially
generated from a `make menuconfig` or `make defconfig` commands. Its location
is defined by `$KERNEL_LINUX_CONFIG_FILE` in `$KCFG/kernel.mk`

### builder makefile
`builder.mk` is used ONLY INSIDE the *builder* container. It includes make
targets to: 
- Log into the *builder*
- import/export Linux kernel configurations (`.config`) inside/outside the
  container
- forward calls to actual Linux makefiles `menuconfig`, `defconfig`...

## Linux Source Code

By default, `make get_source_code` clones the git repository pointed by
`$KERNEL_REPO_URL` into `$KERNEL_SRC_PATH`

But you are free to retreive the whatever linux source code base you want,
wherever you want, as long as you put it in a directory pointed by
`$KERNEL_SRC_PATH` variable in `kernel.mk`.

