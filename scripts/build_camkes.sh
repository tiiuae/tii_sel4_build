#! /bin/sh

set -e

TARGET=${PLATFORM}_${CAMKES_VM_APP}

rm -rf ${TARGET}
./init-build.sh -B ${TARGET} -DAARCH64=1 -DPLATFORM=${PLATFORM} -DNUM_NODES=${NUM_NODES} -DCAMKES_VM_APP=${CAMKES_VM_APP} -DCROSS_COMPILER_PREFIX=${CROSS_COMPILE}
cd ${TARGET}
ninja

echo "Here are your binaries in ${TARGET}/images: "
ls -l ./images

