#! /bin/sh

set -e

. ${0%/*}/functions.sh

BUILDDIR=/workspace/linux/build-${PLATFORM}
SRCDIR=/workspace/projects/camkes-vm-images/${PLATFORM}
CONFIG=${SRCDIR}/linux_configs/config


cd /workspace/linux

export ARCH=arm64
export CROSS_COMPILE

OP=$1
if test "x$1" = "x"; then
  OP=build
fi

case "${OP}" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp ${CONFIG} ${BUILDDIR}/.config
    make O=${BUILDDIR} olddefconfig
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig
    ;;
  mrproper)
    make O=${BUILDDIR} mrproper
    ;;
  build)
    make O=${BUILDDIR} -j`nproc`
    ;;
  install)
    make O=${BUILDDIR} savedefconfig
    cp ${BUILDDIR}/defconfig ${CONFIG}
    cp ${BUILDDIR}/arch/arm64/boot/Image ${SRCDIR}/linux
    cp ${BUILDDIR}/Module.symvers ${SRCDIR}/linux_configs
    TMPDIR=`mktemp -d`
    make O=${BUILDDIR} INSTALL_MOD_PATH=${TMPDIR} modules_install
    rsync -avP --delete ${TMPDIR}/ ${SRCDIR}/modules
    rm -rf ${TMPDIR}
    ;;
esac
