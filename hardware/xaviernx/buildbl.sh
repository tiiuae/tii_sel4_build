#! /bin/sh

set -e

cd ~/Linux_for_Tegra/cboot
export CROSS_COMPILE=aarch64-linux-gnu-
export TEGRA_TOP=$PWD
export TOP=$PWD

make -C ./bootloader/partner/t18x/cboot PROJECT=t194 TOOLCHAIN_PREFIX="${CROSS_COMPILE}" DEBUG=2 BUILDROOT="${PWD}"/out NV_TARGET_BOARD=t194ref NV_BUILD_SYSTEM_TYPE=l4t

cp out/build-t194/lk.bin ~/Linux_for_Tegra/bootloader/cboot_t194.bin
