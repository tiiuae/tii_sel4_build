#! /bin/sh

set -e

. `pwd`/.config

if test "x`pwd`" != "x/workspace"; then
  exec docker/enter_container.sh `pwd` buildroot_build scripts/build_guest_linux.sh $@
fi

BASEDIR=/workspace/linux-images
BUILDDIR=${BASEDIR}/build-${PLATFORM}
SRCDIR=${BASEDIR}/${PLATFORM}
CONFIG=${SRCDIR}/${PLATFORM}-linux-config

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
    cp ${BUILDDIR}/arch/arm64/boot/Image ${SRCDIR}/${PLATFORM}-linux-image
    cp ${BUILDDIR}/Module.symvers ${SRCDIR}/${PLATFORM}-linux-configs
    TMPDIR=`mktemp -d`
    make O=${BUILDDIR} INSTALL_MOD_PATH=${TMPDIR} modules_install
    rsync -avP --delete ${TMPDIR}/ ${SRCDIR}/${PLATFORM}-linux-modules
    rm -rf ${TMPDIR}
    ;;
esac
