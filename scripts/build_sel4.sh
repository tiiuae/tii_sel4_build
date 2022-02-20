#!/bin/sh

set -e

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "${SCRIPT_DIR}/utils.sh"
. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i sel4 -w $(pwd) scripts/build_sel4.sh $@
fi

BUILDDIR=""
SRCDIR=""
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
      if test -n "$BUILDDIR"; then
        die "ERROR: Multiple definitions for parameter BUILDDIR (-b)!"
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
    *)
      # Treat everything else as args to init-build
      OTHER_ARGS="$OTHER_ARGS $ARG "
      ;;
  esac
  shift
done

# Validate input arguments.
# Build and source directories
# are required.
#
if test -z "$BUILDDIR"; then
	die "ERROR: Parameter BUILDDIR (-b) is required!"
fi

if test -z "$SRCDIR"; then
	die "ERROR: Parameter SRCDIR (-s) is required!"
fi

set -- "$OTHER_ARGS"

rm -rf ${BUILDDIR}
mkdir -p ${BUILDDIR}
ln -s ../tools/seL4/cmake-tool/init-build.sh ${BUILDDIR}
ln -s /workspace/${SRCDIR}/easy-settings.cmake ${BUILDDIR}
cd ${BUILDDIR}
./init-build.sh -B . -DAARCH64=1 -DPLATFORM=${PLATFORM} -DCROSS_COMPILER_PREFIX=${CROSS_COMPILE} $@
ninja

echo "----------------------------------------------"
echo "----------------------------------------------"
echo "----------------------------------------------"
echo "                                              "
echo "Here are your binaries in ${BUILDDIR}/images: "
ls -la ./images
