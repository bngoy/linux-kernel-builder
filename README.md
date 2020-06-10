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
`kconfig` file contains the Linux configuration to build. *lkb* uses this file
to run `make allnoconfig KCONFIG_ALLCONFIG=<kconfig>`. The resulting `.config`
file is located near the `kconfig` file. In `$KCFG/kernel.mk`, see 
`$BUILDER_LINUX_KCONFIG_FILE` and `$BUILDER_LINUX_GENCONFIG_FILE` variables
for location definitions.

### builder makefile
`builder.mk` is used ONLY INSIDE the *builder* container. It includes make
targets to: 
- log into the *builder*
- import/export generated Linux kernel configurations (`.config`)
  inside/outside the container
- forward calls to actual Linux makefiles `menuconfig`, `defconfig`...

## Linux Source Code
By default, `make get_source_code` clones the git repository pointed by
`$KERNEL_REPO_URL` into `$KERNEL_SRC_PATH`.

But you are free to retreive the whatever linux source code base you want,
wherever you want, as long as you put it in a directory pointed by
`$KERNEL_SRC_PATH` variable in `kernel.mk`.

## macOS Host
Since macOS default filesystem is not case-sensitive and the kernel repository
requires that, the easiest way is to create a dmg file with the right format:

- Open Disk Utility
- File > New Image > Blank Image
- Select Mac OS Extended (Case-sensitive, Journaled)
- Mount the dmg in macOS

By default in Docker, the directory /Volumes is shared with the virtual
machines, so normally there is nothing to do for that. To check, on the Docker
icon, select Preferences, File Sharing, and /Volumes should be in the list.

## Host/Target Sharing
A `make run_share` target exists to share a directory between the host and the
target Linux using NFS. It starts a [docker
container](https://hub.docker.com/r/itsthenetwork/nfs-server-alpine) on host
side that serve an NFS server. If your target Linux is compiled with NFS
modules then you will be able to mount the NFS share using:

`mkdir /nfs && mount -overs=4 <HOST_ID>:/ /nfs`

Note: On macOS you need to stop the nfsd service first: `sudo nfsd stop`.
Note: If the NFS server is already running, run `make stop_share` to stop it.

