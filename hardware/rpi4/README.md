# Raspberry Pi 4 board support

Our modus operandi is to load as much as possible over Ethernet. Unfortunately rpi4 does
not support network boot directly, so we must boot VideoCore firmware stages and u-boot
from the SD card. The u-boot script has been modified to try to acquire DHCP lease and to
download a boot script from TFTP server. If this succeeds, it executes the script, which
in turn might download executable from network and execute it. If the script download fails
or the script falls through, the standard `meta-raspberrypi` boot script is used, which
boots Linux from the SD card. The rootfs on the SD card will be `vm-image-driver`.
 
Use Yocto to create a bootable SD card:

<pre>
shell@ <b>cd ${WORKSPACE}</b>
shell@ <b>make linux-image</b>
  ...
Here are your images in /workspace/projects/camkes-vm-images/rpi4: 
total 20
lrwxrwxrwx. 1 build build  76 Mar  7 11:00 bootscripts -> /workspace/vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/bootscripts/
lrwxrwxrwx. 1 build build  69 Feb 28 14:12 linux -> /workspace/vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/Image
lrwxrwxrwx. 1 build build 104 Feb 28 14:12 rootfs.cpio.gz -> /workspace/vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-boot-vm-raspberrypi4-64.cpio.gz
lrwxrwxrwx. 1 build build 108 Mar  4 18:45 vm-image-driver.sdcard -> /workspace/vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-driver-vm-raspberrypi4-64.rpi-sdimg
lrwxrwxrwx. 1 build build 106 Feb 28 14:16 vm-image-driver.tar.bz2 -> /workspace/vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-driver-vm-raspberrypi4-64.tar.bz2
</pre>

Write the image to SD card, using either a tool like [Balena Etcher](https://github.com/balena-io/balena-cli) or commands like these:

<pre>
host@ <b>sudo dd if=projects/camkes-vm-images/rpi4/vm-image-driver.sdcard of=/dev/<i>your-SD-card-device</i> bs=1M</b>
host@ <b>sync</b>
</pre>

Put the SD card into rpi4 and copy the network boot script in place:

<pre>
host@ <b>sudo cp projects/camkes-vm-images/rpi4/bootscripts/tftpboot-bootefi.scr /var/lib/tftpboot/boot.scr.rpi4</b>
</pre>

Now rpi4 tries to load `image.rpi4` from TFTP and execute it with `bootefi`, so copy any CAmkES project image
to TFTP directory:

<pre>
host@ <b>sudo cp rpi4_vm_qemu_virtio/images/capdl-loader-image-arm-bcm2711 /var/lib/tftpboot/image.rpi4</b>
</pre>

Power on rpi4 and you should see `vm_qemu_virtio` example booting up.
