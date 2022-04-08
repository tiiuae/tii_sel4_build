#!/bin/sh

set -e

# Look for these first
# in the environment
# variables.
#
BUILD_DIR="${BUILD_DIR}"
TARGET_DIR="${TARGET_DIR}"
OTHER_ARGS=""

# Then parse args. Passed
# argument value overrides
# the environment variable
# value (if set).
#
while [ $# -gt 0 ]; do
  case "${1}" in
    -b|--builddir)
      BUILD_DIR="${2}"
      shift # past argument
      shift # past value
      ;;
    -t|--targetdir)
      TARGET_DIR="${2}"
      shift # past argument
      shift # past value
      ;;
    *)
      OTHER_ARGS="${OTHER_ARGS:+${OTHER_ARGS}} ${1}" # save positional args
      shift # past argument
      ;;
  esac
done


# Validate input arguments.
# All parameters are required.
#
if test -z "${BUILD_DIR}"; then
	printf "ERROR: Build directory (-b|--builddir) required!\n" >&2;
  exit 1
fi

if test -z "${TARGET_DIR}"; then
	printf "ERROR: Boot script target directory (-t|--targetdir) required!\n" >&2;
  exit 1
fi


# Configure file paths and misc stuff
# for the commands to use
#
BUILD_DIR_ABSPATH="$(realpath "${BUILD_DIR}")"
TARGET_DIR_ABSPATH="${BUILD_DIR_ABSPATH}/${TARGET_DIR}"
LOADER_IMG_ABSPATH="${BUILD_DIR_ABSPATH}/elfloader/elfloader"

BOOT_SCRIPT_NAME="boot.scr"
BOOT_SCRIPT_SRC="${TARGET_DIR_ABSPATH}/${BOOT_SCRIPT_NAME}"
BOOT_SCRIPT_TARGET="${TARGET_DIR_ABSPATH}/${BOOT_SCRIPT_NAME}.uimg"

# Make sure no old scripts remain.
# chmod is needed because touch
# creates the files with 600 perms.
#
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
LOADER_LOADADDR=$(${CROSS_COMPILE}objdump -t ${LOADER_IMG_ABSPATH} | grep _text | cut -d' ' -f1)
LOADER_LOADADDR=$(printf "0x%s" $(echo ${LOADER_LOADADDR} | sed 's/^0*//'))

# Grab the CapDL loader image name.
# It's the last image generated by
# ninja-build, hence it is on the
# last line of .ninja_log.
#
CAPDL_IMG_NAME="$(tail -n1 < "${BUILD_DIR_ABSPATH}/.ninja_log" | cut -f4 | cut -f2 -d'/')"

cat <<- __EOF__ >> "${BOOT_SCRIPT_SRC}"
echo 'Running seL4 bootscript...'
setenv capdl_image_load_addr ${LOADER_LOADADDR}
setenv capdl_load_addr \${kernel_addr_r}
setenv capdl_image ${CAPDL_IMG_NAME}
setenv boot_sel4 'if tftp \${capdl_load_addr} \${capdl_image}; then bootelf \${capdl_load_addr}; fi'
echo 'Starting boot...'
run boot_sel4;
__EOF__

# Generate U-Boot script
#
mkimage -A "${ARCH}" -T script -C none -d "${BOOT_SCRIPT_SRC}" "${BOOT_SCRIPT_TARGET}"

echo "                                                "
echo " seL4 bootscript done                           "
echo "                                                "
ls -la "${BOOT_SCRIPT_SRC}"
ls -la "${BOOT_SCRIPT_TARGET}"