#!/bin/sh

set -e

BUILDDIR=""
TARGETDIR=""
SRCIMGNAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--builddir)
      BUILDDIR="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--targetdir)
      TARGETDIR="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--srcimagename)
      SRCIMGNAME="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      shift # past argument
      ;;
  esac
done

# Validate input arguments.
# All parameters are required.
#
if test -z "$BUILDDIR"; then
	printf "ERROR: Build directory (-b|--builddir) required!\n" >&2;
  exit 1
fi

if test -z "$TARGETDIR"; then
	printf "ERROR: Boot script target directory (-t|--targetdir) required!\n" >&2;
  exit 1
fi

if test -z "$SRCIMGNAME"; then
	printf "ERROR: Source image for load address (-s|--srcimagename) required! (Usually \"elfloader/elfloader\")\n" >&2;
  exit 1
fi

# Setup parameters
BUILDDIR_PATH="$(realpath ${BUILDDIR})"
TARGETDIR_PATH="${BUILDDIR_PATH}/${TARGETDIR}"
SRCIMG_PATH="${BUILDDIR_PATH}/${SRCIMGNAME}"

# Generate U-Boot script
SCRIPTNAME="boot.scr"
BOOT_SCRIPT_SRC="${TARGETDIR_PATH}/${SCRIPTNAME}"
BOOT_SCRIPT_TARGET="${TARGETDIR_PATH}/${SCRIPTNAME}.uimg"
rm -f "${BOOT_SCRIPT_SRC}"
rm -f "${BOOT_SCRIPT_TARGET}"
touch "${BOOT_SCRIPT_SRC}"
touch "${BOOT_SCRIPT_TARGET}"
chmod 644 "${BOOT_SCRIPT_SRC}"
chmod 644 "${BOOT_SCRIPT_TARGET}"

# Parse elfloader start address, 
# this is based on elfloaders' README.
# Also strip leading zeroes from the address,
# and add 0x to the beginning.
#
IMAGE_START_ADDR=$(${CROSS_COMPILE}objdump -t ${SRCIMG_PATH} | grep _text | cut -d' ' -f1)
IMAGE_START_ADDR=$(printf "0x%s" $(echo ${IMAGE_START_ADDR} | sed 's/^0*//'))
IMAGE_NAME="capdl-loader-image-arm-bcm2711"

cat <<- __EOF__ >> "${BOOT_SCRIPT_SRC}"
echo 'Running seL4 bootscript...'
setenv capdl_image_load_addr ${IMAGE_START_ADDR}
setenv capdl_load_addr \${kernel_addr_r}
setenv capdl_image ${IMAGE_NAME}
setenv boot_tftp 'if tftp \${capdl_load_addr} \${capdl_image}; then go \${capdl_load_addr}; fi'
setenv bootcmd 'run boot_tftp'
saveenv
echo 'Starting boot...'
boot
__EOF__

mkimage -A "${ARCH}" -T script -C none -d "${BOOT_SCRIPT_SRC}" "${BOOT_SCRIPT_TARGET}"

echo "                                                "
echo " seL4 bootscript done                           "
echo "                                                "
ls -la "${BOOT_SCRIPT_SRC}"
ls -la "${BOOT_SCRIPT_TARGET}"
