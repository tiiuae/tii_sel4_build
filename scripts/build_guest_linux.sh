#!/bin/sh

set -e

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "${SCRIPT_DIR}/utils.sh"
. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i kernel -w $(pwd) scripts/build_guest_linux.sh $@
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
  SRCDIR=/workspace/projects/torvalds/linux
fi

if test -z "$ACTION"; then
	ACTION=build
fi

BUILDDIR=${BASEDIR}/linux-build-${PLATFORM}
PLATDIR=${BASEDIR}/${PLATFORM}
CONFIG=${PLATDIR}/${PLATFORM}-linux-config

cd ${SRCDIR}
export ARCH=arm64
export CROSS_COMPILE

case "$ACTION" in
  olddefconfig)
    mkdir -p ${BUILDDIR}
    cp ${CONFIG} ${BUILDDIR}/.config
    make O=${BUILDDIR} olddefconfig ${OTHER_ARGS}
    ;;
  menuconfig)
    make O=${BUILDDIR} menuconfig ${OTHER_ARGS}
    ;;
  mrproper)
    make O=${BUILDDIR} mrproper ${OTHER_ARGS}
    ;;
  build)
    make O=${BUILDDIR} -j$(nproc) ${OTHER_ARGS}
    ;;
  install)
    make O=${BUILDDIR} savedefconfig ${OTHER_ARGS}
    cp ${BUILDDIR}/defconfig ${CONFIG}
    cp ${BUILDDIR}/arch/arm64/boot/Image ${PLATDIR}/${PLATFORM}-linux-image
    cp ${BUILDDIR}/Module.symvers ${PLATDIR}/${PLATFORM}-linux-symvers
    TMPDIR=$(mktemp -d)
    make O=${BUILDDIR} INSTALL_MOD_PATH=${TMPDIR} modules_install ${OTHER_ARGS}
    rsync -avP --delete ${TMPDIR}/ ${PLATDIR}/${PLATFORM}-linux-modules
    rm -rf ${TMPDIR}
    ;;
esac
