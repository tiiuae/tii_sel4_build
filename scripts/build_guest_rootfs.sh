#!/bin/sh

set -e

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "${SCRIPT_DIR}/utils.sh"
. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i buildroot -w $(pwd) scripts/build_guest_rootfs.sh $@
fi

BASEDIR=""
SRCDIR=""
ACTION=""
OTHER_ARGS=""

SKIP=false
# Parse arguments
for ARG in "$@"; do
  if $SKIP; then
    SKIP=false && continue
  fi
  case "$ARG" in
    -b)
      shift
      if test -n "$BASEDIR"; then
        die "ERROR: Multiple definitions for parameter BASEDIR (-b)!"
      else
        BUILDDIR="$1"
      fi
      SKIP=true
      ;;
    -s)
      shift
      if test -n "$SRCDIR"; then
        die "ERROR: Multiple definitions for parameter SRCDIR (-s)!"
      else
        SRCDIR="$1"
      fi
      SKIP=true
      ;;
    -a)
      shift
      if test -n "$ACTION"; then
        die "ERROR: Multiple definitions for parameter ACTION (-a)!"
      else
        ACTION="$1"
      fi
      SKIP=true
      ;;
    *)
      # Treat everything else as args to init-build
      OTHER_ARGS="$OTHER_ARGS $ARG "
      ;;
  esac
  shift
done

# Validate input arguments.
# All params are optional.
#
if test -z "$BASEDIR"; then
  BASEDIR=/workspace/tii_sel4_build/linux-images
fi

if test -z "$SRCDIR"; then
  SRCDIR=/workspace/projects/buildroot
fi

if test -z "$ACTION"; then
	ACTION=build
fi

BUILDDIR=${BASEDIR}/buildroot-build-${PLATFORM}
PLATDIR=${BASEDIR}/${PLATFORM}
CONFIG=${PLATDIR}/${PLATFORM}-buildroot-config

cd ${SRCDIR}
export ARCH=arm64
export CROSS_COMPILE

case "$ACTION" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp ${CONFIG} ${BUILDDIR}/config
    make O=${BUILDDIR} BR2_DEFCONFIG=${BUILDDIR}/config defconfig ${OTHER_ARGS}
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig ${OTHER_ARGS}
    ;;
  build)
    make O=${BUILDDIR} -j$(nproc) all ${OTHER_ARGS}
    ;;
  install)
    make O=${BUILDDIR} savedefconfig ${OTHER_ARGS}
    cp ${BUILDDIR}/config ${CONFIG}
    cp ${BUILDDIR}/images/rootfs.cpio.gz ${PLATDIR}/${PLATFORM}-rootfs.cpio.gz
    ;;
esac
