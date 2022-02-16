#! /bin/sh

set -e

. `pwd`/.config

if test "x`pwd`" != "x/workspace"; then
  exec docker/enter_container.sh `pwd` buildroot_build scripts/build_guest_rootfs.sh $@
fi

BASEDIR=/workspace/linux-images
SRCDIR=/workspace/projects/buildroot
BUILDDIR=${BASEDIR}/buildroot-build-${PLATFORM}
PLATDIR=${BASEDIR}/${PLATFORM}
CONFIG=${PLATDIR}/${PLATFORM}-buildroot-config

cd ${BASEDIR}
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
    cp ${BUILDDIR}/images/rootfs.cpio.gz ${PLATDIR}/${PLATFORM}-rootfs.cpio.gz
    ;;
esac
