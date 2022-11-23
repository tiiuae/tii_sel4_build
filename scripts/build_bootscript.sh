#! /bin/bash

set -e

# Crude logging functions
log_stdout()
{
  printf "%s: %s\n" "$0" "$*" >&1;
}
log_stderr()
{
  printf "%s: %s\n" "$0" "$*" >&2;
}

die()
{ 
  log_stderr "$*"; exit 111
}


BUILDDIR=$1
if ! [[ -e "${BUILDDIR}" ]]; then
  die "Invalid build directory!"
fi

BOOT_SCRIPT_SRC="${BUILDDIR}/images/boot.scr"
BOOT_SCRIPT_DEST="${BUILDDIR}/images/boot.scr.uimg"

BOOT_IMG_NAME="$(cat "${BUILDDIR}/rootserver_image_name")"
if [[ $? -ne 0 ]] || [[ -z "${BOOT_IMG_NAME}" ]]; then
  die "Couldn't parse rootserver image name"
fi

BOOT_IMAGE="${BUILDDIR}/images/${BOOT_IMG_NAME}"
if ! [[ -e "${BOOT_IMAGE}" ]]; then
  die "\"${BOOT_IMG_NAME}\" does not exist!"
fi

cat <<- __EOF__ > "${BOOT_SCRIPT_SRC}"
echo 'Running CapDL bootscript...'
setenv boot_capdl 'if tftp \${loadaddr} ${BOOT_IMG_NAME}; then bootefi \${loadaddr} \${fdt_addr}; fi'
echo 'Starting boot...'
run boot_capdl;
__EOF__

mkimage -A arm64 -T script -C none -d "${BOOT_SCRIPT_SRC}" "${BOOT_SCRIPT_DEST}"