#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i uboot -d "$(pwd)" scripts/build_uboot.sh $@
fi

if test -n "$1"; then
  COMMAND="$1"
else
  printf "ERROR: COMMAND not defined!" >&2
  exit 1
fi

if test -z "$UBOOT_CONFIG"; then
  printf "ERROR: UBOOT_CONFIG not defined!" >&2
  exit 1
fi

if test -z "$UBOOT_BUILDDIR"; then
  printf "ERROR: UBOOT_BUILDDIR not defined!" >&2
  exit 1
fi

if test -z "$UBOOT_SRCDIR"; then
  printf "ERROR: UBOOT_SRCDIR not defined!" >&2
  exit 1
fi

if test -z "$IMGDIR"; then
  printf "ERROR: IMGDIR not defined!" >&2
  exit 1
fi

UBOOT_CONFIG_NAME=$(basename "${UBOOT_CONFIG}")

cd "${UBOOT_SRCDIR}"
export ARCH=arm
export CROSS_COMPILE="${CROSS_COMPILE}"

case "$COMMAND" in
  olddefconfig)
    mkdir -p "${UBOOT_BUILDDIR}"
    cp -v "${UBOOT_CONFIG}" "${UBOOT_BUILDDIR}"/.config
    make O="${UBOOT_BUILDDIR}" olddefconfig
    ;;
  menuconfig)
    make O="${UBOOT_BUILDDIR}" menuconfig
    ;;
  clean)
    make O="${UBOOT_BUILDDIR}" clean
    ;;
  distclean)
    make O="${UBOOT_BUILDDIR}" distclean
    ;;
  build)
    make O="${UBOOT_BUILDDIR}" -j"$(nproc)"
    ;;
  install)
    make O="${UBOOT_BUILDDIR}" savedefconfig
    cp -v "${UBOOT_BUILDDIR}"/defconfig "${UBOOT_CONFIG}"
    cp -v "${UBOOT_BUILDDIR}"/defconfig "${IMGDIR}"/uboot-config
    cp -v "${UBOOT_BUILDDIR}"/u-boot.bin "${IMGDIR}"/u-boot.bin
    ;;
esac
