#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh kernel $(pwd) scripts/build_guest_linux.sh $@
fi

ACTION="$1"

if test -z "$BASEDIR"; then
  BASEDIR=/workspace/tii_sel4_build/linux-images
fi

if test -z "$KERNELSRCDIR"; then
  KERNELSRCDIR=/workspace/projects/torvalds/linux
fi

if test -z "$ACTION"; then
	ACTION=build
fi

BUILDDIR=${BASEDIR}/${PLATFORM}/linux-build
PLATDIR=${BASEDIR}/${PLATFORM}
KERN_CONFIG=${PLATDIR}/linux-config
KERN_CONFIG_DEST=${BUILDDIR}/.config

cd ${KERNELSRCDIR}
export ARCH=arm64
export CROSS_COMPILE

case "$ACTION" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp -v ${KERN_CONFIG} ${KERN_CONFIG_DEST}
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
  mrproper)
    make O=${BUILDDIR} mrproper
    ;;
  dtb)
    make O=${BUILDDIR} bcm2711-rpi-4-b.dtb
    ;;
  build)
    make O=${BUILDDIR} -j$(nproc)
    ;;
  install)
    make O=${BUILDDIR} savedefconfig
    cp -v ${BUILDDIR}/defconfig ${KERN_CONFIG}
    cp -v ${BUILDDIR}/arch/arm64/boot/Image ${PLATDIR}/linux-image
    cp -v ${BUILDDIR}/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb \
        ${PLATDIR}/bcm2711-rpi-4-b.dtb
    cp -v ${BUILDDIR}/Module.symvers ${PLATDIR}/linux-symvers
    TMPDIR=$(mktemp -d)
    make O=${BUILDDIR} INSTALL_MOD_PATH=${TMPDIR} modules_install
    rsync -avP --delete --no-links ${TMPDIR}/ ${PLATDIR}/linux-modules
    rm -rf ${TMPDIR}
    ;;
esac
