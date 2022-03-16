#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i sel4 -d "$(pwd)" scripts/build_sel4.sh $@
fi

BUILDDIR="$1"
shift
SRCDIR="$1"
shift

# Validate input arguments.
# Build and source directories
# are required.
#
if test -z "$BUILDDIR"; then
	printf "ERROR: Build directory required!" >&2;
  exit 1
fi

if test -z "$SRCDIR"; then
	printf "ERROR: Source directory required!" >&2;
  exit 1
fi

rm -rf "${BUILDDIR}"
mkdir -p "${BUILDDIR}"
ln -s ../tools/seL4/cmake-tool/init-build.sh "${BUILDDIR}"
ln -s "/workspace/${SRCDIR}/easy-settings.cmake" "${BUILDDIR}"
cd "${BUILDDIR}"
./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" $@
ninja

# Generate U-Boot script
TEMPFILE=$(mktemp -q)
IMAGE_START_ADDR=$("${CROSS_COMPILE}objdump" -t ./elfloader/elfloader | grep _text | cut -d' ' -f1)
IMAGE_START_ADDR="0x"$(echo "$IMAGE_START_ADDR" | sed 's/^0*//')
IMAGE_NAME=$(basename $(ls ./images/capdl-loader-*))

cat <<- EOF >> "$TEMPFILE"
setenv capdl_addr ${IMAGE_START_ADDR}
setenv capdl_image ${IMAGE_NAME}
tftp \${capdl_addr} \${capdl_image}
bootelf \${capdl_addr}
EOF

mkimage -A arm64 -O linux -T script -C none -n "${TEMPFILE}" -d "${TEMPFILE}" ./images/boot.scr.uimg
rm "${TEMPFILE}"

echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "                                                "
echo "Here are your binaries in "${BUILDDIR}/images": "
echo "                                                "
ls -la ./images
