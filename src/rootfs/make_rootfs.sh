#!/bin/bash

#
# This script create a minimal root filesystem. It is called from 'builder.mk'
# inside the build environment container.
#
# See from: https://github.com/landley/mkroot/blob/master/mkroot.sh
#

############
# Binaries #
############
ECHO=echo
RM=rm
MKDIR=mkdir
LN=ln
CHMOD=chmod
CAT=cat
CP=cp
WGET=wget
TAR=tar

##############
# Exit codes #
##############
USAGE_ERROR_CODE=1

##########
# Colors #
##########
STD="[m"
RED="[0;31m"
GREEN="[0;32m"
YELLOW="[0;33m"
BLUE="[0;34m"
PURPLE="[0;35m"
CYAN="[0;36m"
GREY="[0;37m"
WHITE="[0;38m"
LRED="[1;31m"
LGREEN="[1;32m"
LYELLOW="[1;33m"
LBLUE="[1;34m"
LPURPLE="[1;35m"
LCYAN="[1;36m"
LGREY="[1;37m"
LWHITE="[1;38m"
WARN="${STD}[${YELLOW}!${STD}]"
FAIL="${STD}[${RED}x${STD}]"
IFAIL="${STD}[${RED}X${STD}]"
OK="${STD}[${GREEN}-${STD}]"

usage()
{
  $ECHO "usage: $0 OUTPUTDIR"
  $ECHO
  $ECHO "Create a root filesystem in 'OUTPUTDIR'"
  $ECHO
  $ECHO "OUTPUTDIR     The directory where to store rootfs"
}

#############################
# Write a message on stderr #
#                           #
# Arguments:                #
#   $* the message to write #
#############################
echo_stderr()
{
  (>&2 echo $*)
}

#########################################################
# Write a fail prefixed message on stderr and return    #
#                                                       #
# Arguments:                                            #
#   $* the message to write                             #
#########################################################
failure()
{
  echo_stderr ${FAIL} $*${STD}
  return 1
}

#############################################################
# Write a success prefixed message on stderr and return     #
#                                                           #
# Arguments:                                                #
#   $* the message to write                                 #
#############################################################
success()
{
  echo_stderr ${OK} $*${STD}
  return 0
}

#############################################################
# Write a warning prefixed message on stderr and return     #
#                                                           #
# Arguments:                                                #
#   $* the message to write                                 #
#############################################################
warning()
{
  echo_stderr ${WARN} $*${STD}
  return 0
}

#################################################
# Write a message on stderr and exit program    #
#                                               #
# Arguments:                                    #
#   $1 the error code to exit                   #
#   $* the message to write                     #
#################################################
die()
{
  error_code=$1
  shift

  failure $*
  exit $error_code
}

if [ $# -lt 1 ]; then
  usage 
  die $USAGE_ERROR_CODE ""
fi

ROOTDIR=$1
DOWNLOADDIR="$ROOTDIR"/downloads


### Create files and directories

$RM -rf "$ROOTDIR" &&
$MKDIR -p "$ROOTDIR"/{etc,tmp,proc,sys,dev,home,mnt,root,usr/{bin,sbin,lib},var} &&
$CHMOD a+rwxt "$ROOTDIR"/tmp &&
$LN -s usr/bin "$ROOTDIR/bin" &&
$LN -s usr/sbin "$ROOTDIR/sbin" &&
$LN -s usr/lib "$ROOTDIR/lib" &&

# TODO: understand and comment init script
$CAT > "$ROOTDIR"/init << 'EOF' &&
#!/bin/sh

export HOME=/home
export PATH=/bin:/sbin
mountpoint -q proc || mount -t proc proc proc
mountpoint -q sys || mount -t sysfs sys sys
if ! mountpoint -q dev
then
  mount -t devtmpfs dev dev || mdev -s
  mkdir -p dev/pts
  mountpoint -q dev/pts || mount -t devpts dev/pts dev/pts
fi
if [ $$ -eq 1 ]
then
  # Don't allow deferred initialization to crap messages over the shell prompt
  echo 3 3 > /proc/sys/kernel/printk
  # Setup networking for QEMU (needs /proc)
  # No DHCP client need to set address manually
  ifconfig eth0 10.0.2.15
  route add default gw 10.0.2.2
  [ "$(date +%s)" -lt 1000 ] && rdate 10.0.2.2 # or time-b.nist.gov
  [ "$(date +%s)" -lt 10000000 ] && ntpd -nq -p north-america.pool.ntp.org
  [ -z "$CONSOLE" ] &&
    CONSOLE="$(sed -rn 's@(.* |^)console=(/dev/)*([[:alnum:]]*).*@\3@p' /proc/cmdline)"
  [ -z "$HANDOFF" ] && HANDOFF=/bin/sh && echo Type exit when done.
  [ -z "$CONSOLE" ] && CONSOLE=console
  # oneit = init ?
  exec /sbin/oneit -c /dev/"$CONSOLE" $HANDOFF
else
  /bin/sh
  umount /dev/pts /dev /sys /proc
fi
EOF
$CHMOD +x "$ROOTDIR"/init &&

$CAT > "$ROOTDIR"/etc/passwd << 'EOF' &&
root::0:0:root:/root:/bin/sh
guest:x:500:500:guest:/home/guest:/bin/sh
nobody:x:65534:65534:nobody:/proc/self:/dev/null
EOF

$CAT > "$ROOTDIR"/etc/group << 'EOF' &&
root:x:0:
guest:x:500:
EOF


BACK=$(pwd)

### Build root filesystem binaries

# toybox

$MKDIR -p $DOWNLOADDIR
[ -f $DOWNLOADDIR/toybox-$ARCH ] || $WGET -O $DOWNLOADDIR/toybox-$ARCH https://landley.net/toybox/downloads/binaries/0.8.3/toybox-$ARCH 
$CP $DOWNLOADDIR/toybox-$ARCH "$ROOTDIR"/usr/sbin
$CHMOD +x "$ROOTDIR"/usr/sbin/toybox-$ARCH
$LN -s toybox-$ARCH "$ROOTDIR"/usr/sbin/toybox
cd "$ROOTDIR"/usr/sbin
$LN -s /usr/sbin/toybox oneit
cd $BACK

[ -f $DOWNLOADDIR/busybox-$ARCH ] || $WGET -O $DOWNLOADDIR/busybox-$ARCH https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-$ARCH
$CP $DOWNLOADDIR/busybox-$ARCH "$ROOTDIR"/usr/bin
$CHMOD +x "$ROOTDIR"/usr/bin/busybox-$ARCH
$LN -s busybox-$ARCH "$ROOTDIR"/usr/bin/busybox
cd "$ROOTDIR"/usr/bin
$LN -s /usr/bin/busybox sh
$LN -s /usr/bin/busybox sed
$LN -s /usr/bin/busybox cat
$LN -s /usr/bin/busybox ls
$LN -s /usr/bin/busybox echo
$LN -s /usr/bin/busybox mount
$LN -s /usr/bin/busybox mountpoint
$LN -s /usr/bin/busybox mkdir
$LN -s /usr/bin/busybox mdev
$LN -s /usr/bin/busybox ifconfig
$LN -s /usr/bin/busybox ping
$LN -s /usr/bin/busybox route
$LN -s /usr/bin/busybox date
$LN -s /usr/bin/busybox rdate
cd $BACK

#apt-get update && apt-get install -y libtirpc-dev  libblkid-dev
#[ -f $DOWNLOADDIR/nfs-utils-2.4.3.tar.xz ] || $WGET -O $DOWNLOADDIR/nfs-utils-2.4.3.tar.xz https://www.kernel.org/pub/linux/utils/nfs-utils/2.4.3/nfs-utils-2.4.3.tar.xz
#cd $DOWNLOADDIR
#$TAR xf nfs-utils-2.4.3.tar.xz
#cd nfs-utils-2.4.3

#./configure --prefix="$ROOTDIR"/usr/bin          \
            #--sysconfdir="$ROOTDIR"/etc      \
            #--sbindir="$ROOTDIR"/sbin        \
            #--disable-nfsv4        \
            #--disable-gss &&
#make
#make install

#gcc rootfs/hello.c rootfs/dl_syscalls.c -static -o "$ROOTDIR"/init 

$ECHO "nameserver 8.8.8.8" > "$ROOT"/etc/resolv.conf || exit 1

