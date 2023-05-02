#! /bin/sh

TFTPBOOT="${TFTPBOOT:-/var/lib/tftpboot}"
DEPLOYDIR="${DEPLOYDIR:-vm-images/build/tmp/deploy/images/vm-raspberrypi4-64}"

cp "${DEPLOYDIR}/Image" "${TFTPBOOT}/image.rpi4"
cp "${DEPLOYDIR}/vm-image-boot-vm-raspberrypi4-64.cpio.gz.u-boot" "${TFTPBOOT}/uRamdisk.rpi4"
cp "${DEPLOYDIR}/bcm2711-rpi-4-b.dtb" "${TFTPBOOT}/dtb.rpi4"
cp "${DEPLOYDIR}/bootscripts/tftpboot-linux.scr" "${TFTPBOOT}/boot.scr.rpi4"
