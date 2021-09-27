#! /bin/sh

set -e

. `pwd`/.config

if test "x`pwd`" != "x/workspace"; then
  exec docker/enter_container.sh `pwd` scripts/build_sel4.sh $@
fi

BUILDDIR=$1
shift

SRCDIR=$1

rm -rf ${BUILDDIR}
mkdir -p ${BUILDDIR}
ln -s ../tools/seL4/cmake-tool/init-build.sh ${BUILDDIR}
ln -s /workspace/${SRCDIR}/easy-settings.cmake ${BUILDDIR}
cd ${BUILDDIR}
./init-build.sh -B . -DAARCH64=1 -DPLATFORM=${PLATFORM} -DCROSS_COMPILER_PREFIX=${CROSS_COMPILE} \
	-DKernelUserStackTraceLength=64 \
	$@
ninja

echo "Here are your binaries in ${BUILDDIR}/images: "
ls -l ./images
