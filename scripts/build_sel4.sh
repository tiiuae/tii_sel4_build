#! /bin/sh

set -e

BUILDDIR=$1
shift

SRCDIR=$1

rm -rf ${BUILDDIR}
mkdir -p ${BUILDDIR}
ln -s ../tools/seL4/cmake-tool/init-build.sh ${BUILDDIR}
ln -s /workspace/${SRCDIR}/easy-settings.cmake ${BUILDDIR}
cd ${BUILDDIR}
./init-build.sh -B . -DAARCH64=1 -DPLATFORM=${PLATFORM} -DCROSS_COMPILER_PREFIX=${CROSS_COMPILE} $@
ninja

echo "Here are your binaries in ${BUILDDIR}/images: "
ls -l ./images
