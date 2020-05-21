# Simplest Linux

This document is a synthesis of the subjects dealt with in the conference
[Building the Simplest Possible Linux System](https://www.youtube.com/watch?v=Sk9TatW9ino&t=668s)
by Rob Landley.

The objective is to describe concepts and mechanics to understand how the Linux
system is working from building, to booting (system init and running are not
covered). The document is punctuated by **Practical** sections presenting
tutorials to illustrate explainations.

## Definitions

* **System**: a set of interconnected hardware components, software components
  or both, dedicated to achieve specific objectives.
* **Tool**: a piece of software that allow to perform development activities
    such as maintenance, debugging or administration of a system. Tools does
    not directly contribute to the system objective.
* **Micro-kernel**: a minimal piece of software that initializes hardware
  resources and provides mechanisms to run other "user-software" e.g processes,
  tasks, thread... The micro-kernel also ensures that temporal (scheduling) and
  spatial (memory management) partitioning between those software processes.
* **Kernel**: a piece of software including or implementing micro-kernel
    functions, that additionally provides drivers and API to access hardware
    devices.
* **Operating System**: a piece of software that includes a kernel and a set
  of services that facilitates user-software development e.g file system,
  network library...
* **Package**: a container that allows to install a piece of software along
  and all its dependencies on a specific OS.
* **Distribution**: an OS and a pre-installed set of packages
* **Application**: a user-software that run on top of an OS.
* **Linux/Linux kernel**: a monolithic kernel including device driver (no OS layer).
* **Linux system** : a sub-system composed of: hw + kernel + OS + distribution
* **system**: Linux system + applications

## Host vs Target Dependencies

The **host** is the computer environment used to build a Linux system. The
**target** is the resulting Linux system built from the host environment that
runs on a hardware target. Host computer and hardware target may be 2
differents CPU architecture.

Building a target Linux system requires to build host packages to which
actual target Linux system packages are built against.

```
This creates a host-target build dependency. A Linux system is build from a
host to a specific target. So there is a circular depencendy: it requires a
host Linux system to build a target Linux system.
```

## Environments
There are 3 environments:

* **Development**: The set of host tools that helps in the development of our
    system, e.g: IDE, source code version control, terminals, shells,
    debuggers...
* **Buildtime**: The set of host tools that helps to build a target Linux
  system, e.g: compiler, linker, make, binutils...
* **Runtime**: The target tools installed in the target Linux distribution, and
    the target hardware that actually run the Linux system. 


## Build Environment
A *Build Environment* is "a linux system capable of rebuilding it-self under
it-self from source code".

Note: the resulting target system is not necesarily a *Build Environment*.

### Pre-requisites
Building a Linux system requires the following components:

1. a host operating system
2. a Linux kernel
3. a C library, e.g uClibc, libc.
4. command line utilities, e.g busybox
5. compiler toolchain, e.g gcc, make, bash.

### Practical
Along the document we will be using **linux-kernel-builder** to build a linux
system. Linux-kernel-builder uses [docker container](../Dockerfile) technology
to encapsulate the build environment and its dependencies. It also uses
[Makefiles](../Makefile) to configure and run the build of a Linux system:
- `Dockerfile` the description of the docker container image used as build
  environement 
- `env.mk` contains host environment variables, and linux-kernel-builder info.
- `configs/<arch>/kernel.mk` includes target linux kernel configuration, and
  docker container configuration to run the build environment.

Linux-kernel-builder mounts a volume to get the resulting linux kernel out of
the container.

First run `make build` to build the linux-kernel-builder container, then `make
KCFG=configs/<arch>/ shell` to log into the container. `<arch>` is the target
architecture for which you want to build your Linux kernel. The latest built
target is saved in `.latest`, and the next `make` calls will look in this file
to get `KCFG`.

You are now is a Linux system build environment. Environment variables that
configure the Linux system build, for instance `ARCH` or `CROSS_COMPILE` are
located in `configs/<arch>/kernel.mk`.  You are free to play in this environment
and run your own commands, but the main commands are located in the
`builder.mk` file, which is mounted from linux-kernel-builder into the builder
container.

## Runtime Environment

### Pre-requisites
Running a Linux system requires the followig components:

1. a hardware target: we will be using **QEMU** as (emulated) target hardware.
2. a Linux kernel: the one we previously built
3. a user **init** program (PID=0) to initialize the system. 

### QEMU
QEMU is an hardware target emulator that runs target code by translating target
instructions into host instructions.

### Practical
Install QEMU on your host operating system, and perform this [bare metal
tutorial](https://balau82.wordpress.com/2010/02/28/hello-world-for-bare-metal-arm-using-qemu/)
to make sure everything work fine with QEMU.

## System Boot

### BIOS
The BIOS is the first program that starts when hardware is powered on. It is
a firmware that initializes and performs 'Power On Self Tests' on basic devices
such as the processor, the memory, graphic card... It enables more complex
software to run afterwards by selecting a **boot medium** (hard disk, floppy
unit, USB, CD-ROMs, Network...), loading the program from the boot medium's
boot sector (or Master Boot Record) into the computer RAM memory, and executes
it.

### Bootloader
The bootloader is the program loaded from boot medium's boot sector by the
BIOS. It is in charge of loading the operating system into memory.
In our case this operating system is Linux. Linux is composed of several layers:
the kernel, the modules, the user packages. The Bootloader loads into memory
the kernel and, if configured so, the **initramfs** filesystem. The kernel
it-self is responsible to load the remaining layer.

### Linux Kernel Start-up
The Linux kernel is the first lowest level layer of a Linux system. It starts
by initializing and configuring hardware resources (CPU, Memory management,
I/O, Floating point, storage device, IRQ...) to prepare partitioned processes
execution, and I/O accesses. This initialization is based on the [device tree
information](#Device Tree) and [ACPI tables](#ACPI Tables).
(TODO: compiled within kernel binary ? dynamical update ??)

### Init
Once the kernel is ready to execute processes, and provide I/O accesses, it
extracts the *initramfs* filesystem into the root filesystem (**rootfs**). The
*initramfs* is a filesystem that includes the **init** program. "This
*init* process is responsible for bringing the system the rest of the way up,
including locating and mounting the real root device (if any)"([R1](#References)).

The *initramfs* filesystem is loaded into memory by the bootloader, either with
the kernel binary because it has been statically linked into, or separately
with a bootloader parameter (usually **initrd**).

Once *initramfs* is extracted, the kernel looks for an *init* program at
various location of the rootfs (/init, /sbin/init...), and executes it as the
first process (PID=1) of the system.

The Linux kernel build process always creates an *initramfs*, even empty, this
way there is always a rootfs loaded when the Linux kernel starts-up.

### initrd vs initramfs
*initrd* is the old way of loading the current *initramfs*. *rd* stands for
'ram disk' that is block based filesystem whereas **initramfs** is a ram
filesystem.
*ramfs* filesystem is more memory efficient than *ramdisk* filesystem, because
file are not duplicated in a backup ram storage.  See **[R1]: What is ramfs ?**
for more details.

During init, Linux kernel read the signature at the start of initramfs, if it
is a 'cpio' signature, then it loads it as an *initramfs*, otherwise (e.g ext2
signature) it loads it as an *initrd*.

### Practical
In our runtime environment, BIOS and Bootloader are covered by QEMU that has
an internal bootloader that loads the target program into the virtual memory of
the host, and jumps to the target program entry point (See '-kernel' and
'-initrd' options). 

See **[R2]:** or `Makefile:hello` for more details.

### Device Tree
TODO: Hardware layout loading


### ACPI Tables
TODO:

### Kernel Parameters
Kernel parameters allows to configure the Linux kernel. They are given by the
bootloader to the Linux kernel. See **[R3]** for more details.

The Linux kernel requires at least the `console=/dev/<some_device>` parameter
to specify which serial device shall be used by the Linux kernel to standard
I/O (in, out, err).

### Device Driver
The buses scanning, load device driver. The latest phase part can be statically
linked in the linux
kernel.

### Rootfs
During system boot, the bootloader loads an init filesystem archive (initramfs)
into the target hardware memory, and then the Linux kernel extracts it into
memory as a **root filesystem** (rootfs). This rootfs contains all the system
files relative to the OS and distribution part of the Linux system. 

### Practical

1. `make defconfig` generate the default configuration for your selected
   `KCFG`.
2.  `make hello` build a rootfs with an 'Hello world' init program (See
    'hello.c').  As it is the init process and that nothing else is loaded in
    the system, Hello program has to be statically linked.

## Filesystem

### blockfs
TODO

### ramfs
TODO

### tmpfs
TODO

### sysfs
TODO

## Bibliography

- https://developer.ibm.com/technologies/linux/tutorials/l-boot-rootfs/#how-linux-booting-works
- https://opensource.com/article/18/1/analyzing-linux-boot-process

## References
- **[R1]** https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt
- **[R2]** https://www.youtube.com/watch?v=Sk9TatW9ino&t=668s
- **[R3]** https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt
