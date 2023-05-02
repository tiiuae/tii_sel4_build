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
host$ <b>cd ${WORKSPACE}</b>
host$ <b>make linux-image</b>
</pre>

Write the image to SD card, using either a tool like [Balena Etcher](https://github.com/balena-io/balena-cli) or commands like these:

<pre>
host$ <b>sudo dd if=projects/camkes-vm-images/rpi4/vm-image-driver.sdcard of=/dev/<i>your-SD-card-device</i> bs=1M</b>
host$ <b>sync</b>
</pre>

Put the SD card into rpi4 and copy the network boot files in place:

<pre>
host$ <b>sudo ./tii_sel4_build/hardware/rpi4/prepare_camkes_boot.sh vm_qemu_virtio</b>
</pre>

Power on rpi4 and you should see `vm_qemu_virtio` example booting up.
Alternatively, you can boot Linux natively:

<pre>
host$ <b>sudo ./tii_sel4_build/hardware/rpi4/prepare_linux_boot.sh</b>
</pre>
