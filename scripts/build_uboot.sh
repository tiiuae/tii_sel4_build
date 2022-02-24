#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh uboot $(pwd) scripts/build_uboot.sh $@
fi

ACTION="$1"

if test -z "$BASEDIR"; then
  BASEDIR=/workspace/tii_sel4_build/linux-images
fi

if test -z "$UBOOTSRCDIR"; then
  UBOOTSRCDIR=/workspace/projects/uboot
fi

if test -z "$ACTION"; then
	ACTION=build
fi

BUILDDIR=${BASEDIR}/${PLATFORM}/uboot-build
PLATDIR=${BASEDIR}/${PLATFORM}
UBOOT_CONFIG=${PLATDIR}/uboot-config
UBOOT_CONFIG_DEST=${BUILDDIR}/.config

cd ${UBOOTSRCDIR}
#export ARCH=arm64
export CROSS_COMPILE

case "$ACTION" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp -v ${UBOOT_CONFIG} ${UBOOT_CONFIG_DEST}
    make O=${BUILDDIR} olddefconfig
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig
    ;;
  clean)
    make O=${BUILDDIR} clean
    ;;
  distclean)
    make O=${BUILDDIR} distclean
    ;;
  build)
    make O=${BUILDDIR} -j$(nproc)
    ;;
  install)
    make O=${BUILDDIR} savedefconfig
    cp -v ${BUILDDIR}/defconfig ${UBOOT_CONFIG}
    cp -v ${BUILDDIR}/u-boot.bin ${PLATDIR}/u-boot.bin
    ;;
esac
