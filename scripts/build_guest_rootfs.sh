#! /bin/sh

set -e

. ${0%/*}/functions.sh

BUILDDIR=/workspace/buildroot/build-${PLATFORM}
SRCDIR=/workspace/projects/camkes-vm-images/${PLATFORM}
CONFIG=${SRCDIR}/buildroot/buildroot-config


cd /workspace/buildroot

export ARCH=arm64
export CROSS_COMPILE

OP=$1
if test "x$1" = "x"; then
  OP=build
fi

case "${OP}" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp ${CONFIG} ${BUILDDIR}/config
    make O=${BUILDDIR} BR2_DEFCONFIG=${BUILDDIR}/config defconfig
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig
    ;;
  build)
    make O=${BUILDDIR} -j`nproc` all
    ;;
  install)
    make O=${BUILDDIR} savedefconfig
    cp ${BUILDDIR}/config ${CONFIG}
    cp ${BUILDDIR}/images/rootfs.cpio.gz ${SRCDIR}/rootfs.cpio.gz
    ;;
esac
