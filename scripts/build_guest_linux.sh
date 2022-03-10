#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh kernel $(pwd) scripts/build_guest_linux.sh $@
fi

if test -n "$1"; then
  COMMAND="$1"
else
  printf "ERROR: COMMAND not defined!" >&2
  exit 1
fi

if test -z "$LINUX_CONFIG"; then
  printf "ERROR: LINUX_CONFIG not defined!" >&2
  exit 1
fi

if test -z "$LINUX_BUILDDIR"; then
  printf "ERROR: LINUX_BUILDDIR not defined!" >&2
  exit 1
fi

if test -z "$LINUX_SRCDIR"; then
  printf "ERROR: LINUX_SRCDIR not defined!" >&2
  exit 1
fi

if test -z "$IMGDIR"; then
  printf "ERROR: IMGDIR not defined!" >&2
  exit 1
fi

LINUX_CONFIG_NAME=$(basename ${LINUX_CONFIG})

cd ${LINUX_SRCDIR}
export ARCH=${ARCH}
export CROSS_COMPILE=${CROSS_COMPILE}

case "$COMMAND" in
  olddefconfig)
    mkdir -p ${LINUX_BUILDDIR}
    cp -v ${LINUX_CONFIG} ${LINUX_BUILDDIR}/.config
    make O=${LINUX_BUILDDIR} olddefconfig
    ;;
  menuconfig)
    make O=${LINUX_BUILDDIR} menuconfig
    ;;
  clean)
    make O=${LINUX_BUILDDIR} clean
    ;;
  distclean)
    make O=${LINUX_BUILDDIR} distclean
    ;;
  mrproper)
    make O=${LINUX_BUILDDIR} mrproper
    ;;
  dtbs)
    make O=${LINUX_BUILDDIR} dtbs
    ;;
  build)
    make O=${LINUX_BUILDDIR} -j$(nproc)
    ;;
  install)
    make O=${LINUX_BUILDDIR} savedefconfig
    cp -v ${LINUX_BUILDDIR}/defconfig ${LINUX_CONFIG}
    cp -v ${LINUX_BUILDDIR}/defconfig ${IMGDIR}/${LINUX_CONFIG_NAME}
    cp -v ${LINUX_BUILDDIR}/arch/arm64/boot/Image ${IMGDIR}/linux
    cp -v ${LINUX_BUILDDIR}/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb ${IMGDIR}/linux.dtb
    cp -v ${LINUX_BUILDDIR}/Module.symvers ${IMGDIR}/linux-symvers
    TMPDIR=$(mktemp -d)
    make O=${LINUX_BUILDDIR} INSTALL_MOD_PATH=${TMPDIR} modules_install
    rsync -avP --delete --no-links ${TMPDIR}/ ${IMGDIR}/linux-modules
    rm -rf ${TMPDIR}
    ;;
esac
