#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh buildroot $(pwd) scripts/build_guest_rootfs.sh $@
fi

ACTION="$1"

if test -z "$BASEDIR"; then
  BASEDIR=/workspace/tii_sel4_build/linux-images
fi

if test -z "$BRSRCDIR"; then
  BRSRCDIR=/workspace/projects/buildroot
fi

if test -z "$KERNELSRCDIR"; then
  KERNELSRCDIR=/workspace/projects/torvalds/linux
fi

if test -z "$ACTION"; then
	ACTION=build
fi

BUILDDIR=${BASEDIR}/${PLATFORM}/buildroot-build
PLATDIR=${BASEDIR}/${PLATFORM}
BR_CONFIG=${PLATDIR}/buildroot-config
BR_CONFIG_DEST=${BUILDDIR}/br-config
SDKPREFIX=aarch64-buildroot-linux-uclibc-sdk
GUEST_KERNEL_VERSION=$(make -C ${KERNELSRCDIR} -s kernelversion)

cd ${BRSRCDIR}
export ARCH=arm64
export CROSS_COMPILE
export GUEST_KERNEL_VERSION=${GUEST_KERNEL_VERSION}

case "$ACTION" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp -v ${BR_CONFIG} ${BR_CONFIG_DEST}
    make O=${BUILDDIR} \
        BR2_DEFCONFIG=${BR_CONFIG_DEST} \
        defconfig
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig
    ;;
  clean)
    make O=${BUILDDIR} clean
    ;;
  dirclean)
    make O=${BUILDDIR} dirclean
    ;;
  build)
    make O=${BUILDDIR} -j$(nproc) all
    ;;
  savedefconfig)
    make O=${BUILDDIR} savedefconfig
    cp -v ${BR_CONFIG_DEST} ${BR_CONFIG}
    ;;
  install)
    make O=${BUILDDIR} savedefconfig
    cp -v ${BR_CONFIG_DEST} ${BR_CONFIG}
    mkdir -p ${PLATDIR}/images
    rsync -avP --delete ${BUILDDIR}/images/ ${PLATDIR}/images
    ;;
  sdk)
    make O=${BUILDDIR} BR2_SDK_PREFIX=${SDKPREFIX} sdk
    ;;
  extractsdk)
    mkdir -p ${BUILDDIR}/sdk
    tar -xvf ${PLATDIR}/${SDKPREFIX}.tar.gz -C ${BUILDDIR}/sdk
    ;;
  installsdk)
    make O=${BUILDDIR} savedefconfig
    cp -v ${BR_CONFIG_DEST} ${BR_CONFIG}
    cp -v ${BUILDDIR}/images/${SDKPREFIX}.tar.gz ${PLATDIR}/${SDKPREFIX}.tar.gz
    ;;
  shell)
    export BASEDIR=${BASEDIR}
    export BRSRCDIR=${BRSRCDIR}
    export BUILDDIR=${BUILDDIR}
    export PLATDIR=${PLATDIR}
    export BR_CONFIG=${BR_CONFIG}
    export BR_CONFIG_DEST=${BR_CONFIG_DEST}
    export SDKPREFIX=${SDKPREFIX}
    /bin/bash
    ;;
esac
