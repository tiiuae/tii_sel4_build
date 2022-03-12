#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh buildroot $(pwd) scripts/build_guest_rootfs.sh $@
fi

if test -n "$1"; then
  COMMAND="$1"
else
  printf "ERROR: COMMAND not defined!" >&2
  exit 1
fi

if test -z "$BR_CONFIG"; then
  printf "ERROR: BR_CONFIG not defined!" >&2
  exit 1
fi

if test -z "$BR_BUILDDIR"; then
  printf "ERROR: BR_BUILDDIR not defined!" >&2
  exit 1
fi

if test -z "$BR_SRCDIR"; then
  printf "ERROR: BR_SRCDIR not defined!" >&2
  exit 1
fi

if test -z "$IMGDIR"; then
  printf "ERROR: IMGDIR not defined!" >&2
  exit 1
fi

if test -z "$KERNELVER"; then
  printf "ERROR: KERNELVER not defined!" >&2
  exit 1
fi

BR_CONFIG_NAME=$(basename ${BR_CONFIG})

cd ${BR_SRCDIR}
export ARCH=${ARCH}
export CROSS_COMPILE=${CROSS_COMPILE}

case "$COMMAND" in
  olddefconfig)
    mkdir -p ${BR_BUILDDIR}
    cp -v ${BR_CONFIG} ${BR_BUILDDIR}/${BR_CONFIG_NAME}
    make O=${BR_BUILDDIR} BR2_DEFCONFIG=${BR_BUILDDIR}/${BR_CONFIG_NAME} defconfig
    ;;
  menuconfig)
    make O=${BR_BUILDDIR} menuconfig
    ;;
  clean)
    make O=${BR_BUILDDIR} clean
    ;;
  dirclean)
    make O=${BR_BUILDDIR} dirclean
    ;;
  build)
    make O=${BR_BUILDDIR} -j$(nproc) all
    ;;
  savedefconfig)
    make O=${BR_BUILDDIR} savedefconfig
    cp -v ${BR_BUILDDIR}/${BR_CONFIG_NAME} ${BR_CONFIG}
    ;;
  install)
    make O=${BR_BUILDDIR} savedefconfig
    cp -v ${BR_BUILDDIR}/${BR_CONFIG_NAME} ${BR_CONFIG}
    cp -v ${BR_BUILDDIR}/${BR_CONFIG_NAME} ${IMGDIR}/${BR_CONFIG_NAME}
    rsync -avP --delete ${BR_BUILDDIR}/images/ ${IMGDIR}/br-images
    ;;
  sdk)
    mkdir -p ${BR_BUILDDIR}
    cp -v ${BR_SDK_CONFIG} ${BR_BUILDDIR}/${BR_CONFIG_NAME}
    make O=${BR_BUILDDIR} BR2_DEFCONFIG=${BR_BUILDDIR}/${BR_CONFIG_NAME} defconfig
    make O=${BR_BUILDDIR} sdk
    ;;
esac
