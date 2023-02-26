#! /bin/sh

set -e

. ${0%/*}/functions.sh

BUILDDIR=$1
shift

SRCDIR=$1

rm -rf "${BUILDDIR}"
mkdir -p "${BUILDDIR}"

ln -rs tools/seL4/cmake-tool/init-build.sh "${BUILDDIR}"
ln -rs "${SRCDIR}/easy-settings.cmake" "${BUILDDIR}"

cd "${BUILDDIR}" || exit 2

# shellcheck disable=SC2068
./init-build.sh \
  -B . \
  ${CMAKE_FLAGS} \
  $@

ninja

echo "Here are your binaries in ${BUILDDIR}/images: "
ls -l ./images
