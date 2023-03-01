# TII seL4 build system

These instructions have been tested with Ubuntu 20.10 desktop and Fedora 33.

# Setting up the build environment

## Update your computer and install prerequisites

### Ubuntu
<pre>
host% <b>sudo apt-get -y update</b>
host% <b>sudo apt-get -y upgrade</b>
host% <b>sudo apt -y install git repo</b>
</pre>

### Fedora
<pre>
host% <b>sudo dnf update</b>
host% <b>sudo dnf install -y git</b>
host% <b>mkdir -p ~/.local/bin</b>
host% <b>curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo</b>
host% <b>chmod u+x ~/.local/bin/repo</b>
</pre>

## Configure git

Only linear git history allowed, no merge commits.

<pre>
host% <b>git config --global user.email "you@example.com"</b>
host% <b>git config --global user.name "Your Name"</b>
host% <b>git config --global merge.ff only</b>
</pre>

## Set up github access

Unless you have an existing SSH public/private key pair, generate one with ```ssh-keygen```. You may want to supply an empty password
or git cloning process will be quite cumbersome. In your github account, go to “Settings” → “SSH and GPG keys” and upload your
```${HOME}/.ssh/id_rsa.pub``` there. Make sure you upload the public key, not the private key. Make sure the latter is secure!


## Install and configure docker

### Ubuntu
<pre>
host% <b>sudo apt -y install docker docker.io</b>
</pre>

### Fedora
<pre>
host% <b>sudo dnf install -y dnf-plugins-core</b>
host% <b>sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo</b>
host% <b>sudo dnf install -y docker-ce docker-ce-cli containerd.io</b>
host% <b>sudo systemctl enable docker</b>
host% <b>sudo systemctl start docker</b>
</pre>

Add yourself to ```docker``` group:

<pre>
host% <b>sudo usermod -aG docker $USER</b>
</pre>

In order to supplementary group change take effect, either reboot your computer or log out and back in (the most lazy ones can
use the ```newgrp``` command). In any case verify with the ```groups``` command.

## Check out sources
<pre>
# Choose a working directory, this will be visible in the container at /workspace
# (the WORKSPACE variable will point to /workspace as well inside the container)
host% <b>export WORKSPACE=~/sel4</b>

host% <b>mkdir ${WORKSPACE} && cd ${WORKSPACE}</b>
host% <b>repo init -u git@github.com:tiiuae/tii_sel4_manifest.git -b tii/development</b>
host% <b>repo sync</b>
</pre>

## Build docker images
<pre>
host% <b>make docker</b>
</pre>

## Use it!

<pre>
host% <b>cd ${WORKSPACE}</b>

# configure for Raspberry Pi 4

host% <b>make rpi4_defconfig</b>

# simple seL4 microkernel test

host% <b>make sel4test</b>
host% <b>ls -l rpi4_sel4test/images</b>
-rwxr-xr-x. 1 build build 5832040 Aug 31 08:31 sel4test-driver-image-arm-bcm2711

# More complex examples with VMs (you need to build the Yocto
# images first, see below)

host% <b>make vm_minimal</b>
host% <b>ls -l rpi4_vm_minimal/images</b>
-rwxr-xr-x. 1 build build 37641488 Aug 28 02:50 capdl-loader-image-arm-bcm2711

host% <b>make vm_multi</b>
host% <b>ls -l rpi4_vm_multi/images</b>
-rwxr-xr-x. 1 build build 51656592 Aug 28 02:52 capdl-loader-image-arm-bcm2711

# Enter build container interactively -- you get all tools
# (for example, aarch64-linux-gnu toolchain) without having
# to install them onto host.

host% <b>make shell</b>

container% <b>aarch64-linux-gnu-objdump -D rpi4_sel4test/kernel/kernel.elf</b>
</pre>

## Network booting

This seL4 playground boots from network.

### Setting up NFS root

Create a directory on the NFS server:

<pre>
host% <b>sudo mkdir -p /srv/nfs/rpi4</b>
</pre>

Add this directory to NFS exports:

<pre>
host% <b>cat /etc/exports</b>
/srv/nfs/rpi4 192.168.5.0/24(rw,no_root_squash)
host% <b>sudo exportfs -a</b>
</pre>

### Pass NFS server info via DHCP

<pre>
host% <b>cat /etc/dhcp/dhcpd.conf</b>
option domain-name     "local.domain";
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.5.0 netmask 255.255.255.0 {
    range dynamic-bootp 192.168.5.200 192.168.5.254;
    option broadcast-address 192.168.5.255;
    option routers 192.168.5.1;
    next-server 192.168.5.1;

    option root-path "192.168.5.1:/srv/nfs/rpi4,vers=3,proto=tcp,nolock";
}
</pre>

It is the most convenient to use TCP since the Fedora firewall will block UDP
by default.

### Setup Raspberry Pi 4 for network booting

| TODO: AFAIK, Yocto currently builds a SD-card image which can be directly flashed to the SD-card with dd. Add instructions for that. |
| --- |


First, take a suitable micro SD-card to use for U-Boot.
Something like 2GB card will work just fine. Insert it to your PC, 
using an external SD-card adapter if necessary. 

### Prepare SD-card partitions

Find out the block device name using `lsblk`. In this example,
the card is allocated a descriptor of `/dev/sda`. Format the card using `fdisk`:

<pre>
host% <b>sudo fdisk /dev/sda</b>
[sudo] password for XXX: 

Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

# Print existing partition table with p
# Delete any existing partitions with d
Command (m for help): p
Disk /dev/sda: 14,87 GiB, 15962472448 bytes, 31176704 sectors
Disk model: Transcend       
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xcb4c447f

Device     Boot  Start     End Sectors  Size Id Type
/dev/sda1  *      2048  526335  524288  256M  b W95 FAT32
/dev/sda2       526336 2623487 2097152    1G 83 Linux

Command (m for help): d
Partition number (1,2, default 2): 1

Partition 1 has been deleted.

Command (m for help): d
Selected partition 2
Partition 2 has been deleted.

# Create 2 new partitions on the card with n
# First is a boot partition of type W95 FAT32, size 256MB
# Second is a root partiton of type Linux, using rest of the
# available space
ommand (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-31176703, default 2048): 2048
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-31176703, default 31176703): +256M

Created a new partition 1 of type 'Linux' and of size 256 MiB.
Partition #1 contains a vfat signature.

Do you want to remove the signature? [Y]es/[N]o: y

The signature will be removed by a write command.

Command (m for help): t
Selected partition 1
Hex code or alias (type L to list all): 0b
Changed type of partition 'Linux' to 'W95 FAT32'.

Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (2-4, default 2): 2
First sector (526336-31176703, default 526336): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (526336-31176703, default 31176703): 

Created a new partition 2 of type 'Linux' and of size 14,6 GiB.
Partition #2 contains a ext3 signature.

Do you want to remove the signature? [Y]es/[N]o: y

The signature will be removed by a write command.

Command (m for help): t
Partition number (1,2, default 2): 2
Hex code or alias (type L to list all): 83

Changed type of partition 'Linux' to 'Linux'.

# Set bootable flag to the first partition
Command (m for help): a
Partition number (1,2, default 2): 1

The bootable flag on partition 1 is enabled now.

# Check the partition layout
Command (m for help): p
Disk /dev/sda: 14,87 GiB, 15962472448 bytes, 31176704 sectors
Disk model: Transcend       
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xcb4c447f

Device     Boot  Start      End  Sectors  Size Id Type
/dev/sda1  *      2048   526335   524288  256M  b W95 FAT32
/dev/sda2       526336 31176703 30650368 14,6G 83 Linux

Filesystem/RAID signature on partition 1 will be wiped.
Filesystem/RAID signature on partition 2 will be wiped.

# Write changes to the card
Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
</pre>


Now you should have 2 partitions on the SD-card:
<pre>
host% <b>lsblk /dev/sda</b>
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    1 14,9G  0 disk 
├─sda1   8:1    1  256M  0 part 
└─sda2   8:2    1 14,6G  0 part 
</pre>

### Format the SD-card partitions

Format the boot partition to FAT32:
<pre>
host% <b>sudo mkdosfs -F 32 -n BOOT /dev/sda1</b>
[sudo] password for XXX: 
mkfs.fat 4.2 (2021-01-31)
</pre>

Format the root partition to ext3:
<pre>
host% <b>udo mkfs -t ext3 -L ROOT /dev/sda2</b>
[sudo] password for XXX: 
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 3831296 4k blocks and 958464 inodes
Filesystem UUID: 8789de92-b900-4b87-9a04-87483d7d4e79
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
</pre>


### Mount the partitions for copying files

Use the GUI mounting options on your OS, or
create mount directories where to mount the partitions.
In this example, `/mnt` directory is used.

<pre>
host% <b>sudo mkdir /mnt/sd_boot</b>
host% <b>sudo mkdir /mnt/sd_root</b>
</pre>

Mount the partitions:
<pre>
host% <b>sudo mount /dev/sda1 /mnt/sd_boot</b>
host% <b>sudo mount /dev/sda2 /mnt/sd_root</b>
</pre>

Copy the boot partition files from `hardware/rpi4` directory
to the boot partition:

<pre>
host% <b>sudo cp -vR tii_sel4_build/hardware/rpi4/* /mnt/sd_boot/</b>
'tii_sel4_build/hardware/rpi4/bcm2711-rpi-4-b.dtb' -> '/mnt/sd_boot/bcm2711-rpi-4-b.dtb'
'tii_sel4_build/hardware/rpi4/bootcode.bin' -> '/mnt/sd_boot/bootcode.bin'
'tii_sel4_build/hardware/rpi4/config.txt' -> '/mnt/sd_boot/config.txt'
'tii_sel4_build/hardware/rpi4/fixup4.dat' -> '/mnt/sd_boot/fixup4.dat'
'tii_sel4_build/hardware/rpi4/fixup.dat' -> '/mnt/sd_boot/fixup.dat'
'tii_sel4_build/hardware/rpi4/start4.elf' -> '/mnt/sd_boot/start4.elf'
'tii_sel4_build/hardware/rpi4/start.elf' -> '/mnt/sd_boot/start.elf'
'tii_sel4_build/hardware/rpi4/u-boot.bin' -> '/mnt/sd_boot/u-boot.bin'
'tii_sel4_build/hardware/rpi4/uboot.env' -> '/mnt/sd_boot/uboot.env'
host% <b>sync</b>
</pre>

| TODO: add instructions to copy RootFS files! |
|---|

Now the partitions can be unmounted, and the SD-card attached to the RPi.

<pre>
host% <b>sudo umount /mnt/sd_boot/</b>
host% <b>sudo umount /mnt/sd_root/</b>
</pre>


### Setup U-Boot for TFTP boot

Insert the SD-card to the RPi, and connect a serial cable 
between RPi and PC. Open a serial console emulator of your choice,
here `minicom` is used.

>**Note**
>Note that on most Linux distros, `/dev/ttyUSBx` devices have a
group membership of `dialout`. In order to connect to the serial port,
you need to be a member of said group or use sudo to connect.

>**Note**
>The default image type configured for RPi4 is now EFI. This means that
you have to use `bootefi` command for starting the image instead of the
traditional `bootelf`!

Now the U-Boot environment must be configured to load
the boot image via TFTP. Power on the RPi, and be prepared to 
hit any button to stop U-Boot from autobooting when it starts. 

<pre>
host% <b>minicom -b 115200 -D /dev/ttyUSB0/</b>

Welcome to minicom 2.8

OPTIONS: I18n 
Port /dev/ttyUSB0, 16:30:32

Press CTRL-A Z for help on special keys

U-Boot 2022.10 (Nov 23 2022 - 02:23:58 +0200)

DRAM:  7.9 GiB
RPI 4 Model B (0xd03114)
Core:  210 devices, 16 uclasses, devicetree: board
MMC:   mmcnr@7e300000: 1, mmc@7e340000: 0
Loading Environment from FAT... OK
In:    serial
Out:   serial
Err:   serial
Net:   eth0: ethernet@7d580000
PCIe BRCM: link up, 5.0 Gbps x1 (SSC)
starting USB...
Bus xhci_pci: Register 5000420 NbrPorts 5
Starting the controller
USB XHCI 1.00
scanning bus xhci_pci for devices... 2 USB Device(s) found
       scanning usb for storage devices... 0 Storage Device(s) found
Hit any key to stop autoboot:  0 
U-Boot> 
</pre>

Edit the environment value `bootcmd_capdl`,
and set its contents to:

<pre>
run boot_net_usb_start; run boot_pci_enum; setenv autoload no; if dhcp; then echo "TFTP boot..."; if tftp ${loadaddr} capdl-loader-image-arm-bcm2711; then bootefi ${loadaddr} {fdt_addr}; fi; fi;
</pre>

<pre>
U-Boot> <b>editenv bootcmd_capdl</b>
edit: ...
U-Boot> <b>saveenv</b>
Saving Environment to FAT... OK
U-Boot> <b>editenv bootcmd</b>
edit: run bootcmd_capdl;
U-Boot> <b>saveenv</b>
Saving Environment to FAT... OK
</pre>


Now if everything is configured correctly, RPi should start
the image simply with:
<pre>
U-Boot> <b>boot</b>
BOOTP broadcast 1
BOOTP broadcast 2
BOOTP broadcast 3
DHCP client bound to address 192.168.5.200 (1034 ms)
TFTP boot...
Using ethernet@7d580000 device
TFTP from server 192.168.5.1; our IP address is 192.168.5.200
Filename 'capdl-loader-image-arm-bcm2711'.
Load address: 0x1000000
Loading: T T ##################################################  38.8 MiB
         1.4 MiB/s
done
Bytes transferred = 40665224 (26c8088 hex)
Card did not respond to voltage select! : -110
No EFI system partition
Booting /capdl-loader-image-arm-bcm2711

ELF-loader started on CPU: ARM Ltd. Cortex-A72 r0p3
  paddr=[37846000..ffffffffffffffff]
  dtb=7f00000
Looking for DTB in CPIO archive...found at 37a4ffb0.
Loaded DTB from 37a4ffb0.
   paddr=[127c000..1288fff]
ELF-loading image 'kernel' to 1000000
  paddr=[1000000..127bfff]
  vaddr=[8001000000..800127bfff]
  virt_entry=8001000000
ELF-loading image 'capdl-loader' to 1289000
  paddr=[1289000..3921fff]
  vaddr=[400000..2a98fff]
  virt_entry=4092f0
Core 1 is up with logic ID 1
Core 2 is up with logic ID 2
Core 3 is up with logic ID 3
Enabling hypervisor MMU and paging
Jumping to kernel-image entry point...
...
</pre>



# QEMU, virtio and seL4

The ```vm_qemu_virtio``` example demonstrates TII's experimental work to bring QEMU-backed
virtio devices into guest VMs. An instance of QEMU is running in driver-VM and it provides
virtio-blk, virtio-console, virtio-net and virtfs to the user-VM guest. This demo abandons
Buildroot and uses Yocto to build the guest VM images.

<pre>
host$ <b>repo init -u git@github.com:tiiuae/tii_sel4_manifest.git -b tii/development</b>
host$ <b>repo sync</b>
host$ <b>make docker</b>

# build driver-VM and user-VM images
host$ <b>make shell</b>
container$ <b>cd vm-images</b>
container$ <b>. setup.sh</b>
container$ <b>bitbake vm-image-driver</b>
container$ <b>bitbake vm-image-boot</b>

# copy kernel and initramfs image in place, and build qemu seL4 vm_qemu_virtio
container$ <b>cp vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/Image projects/camkes-vm-images/rpi4/linux</b>
container$ <b>cp vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-boot-vm-raspberrypi4-64.cpio.gz projects/camkes-vm-images/rpi4/rootfs.cpio.gz</b>
container$ <b>make rpi4_defconfig</b>
container$ <b>make vm_qemu_virtio</b>
# exit container
container$ <b>exit</b>

# copy seL4 image to TFTP directory
host$ <b>cp rpi4_vm_qemu_virtio/images/capdl-loader-image-arm-bcm2711 /var/lib/tftpboot</b>

# expose driver-VM image via NFS (update your directory to command)
host$ <b>tar -C /srv/nfs/rpi4 -xjpvf vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-driver-raspberrypi4-64.tar.bz2</b>

# create host/guest shared directory
host$ <b>mkdir /srv/nfs/rpi4/host</b>
</pre>

# Using QEMU demo

After the driver-VM has booted, log in (empty root password) and start the user-VM:

<pre>
driver-vm$ <b>screen -c screenrc-drivervm</b>
</pre>

This will start a ```screen``` session, with one shell for interactive use and the another one is QEMU's stdout, works also
as a console for user-VM. You can switch between the windows using ^A<number>. In case you are using ```minicom```, you need to press
^A twice.

When the user-VM has booted, log in. There is ```screenrc-uservm```, which starts an interactive shell and stress tests for virtio-blk,
virtio-net and virtio-console. To launch it, just type:

<pre>
user-vm$ <b>screen -c screenrc-uservm</b>
</pre>

Within user-VM, the ```screen``` control character has been mapped to ^B.

# Rebuilding guest VM components

We have migrated over to Yocto build system, which builds both the kernel and the
root filesystem for the guest VM. As such the old helper scripts
```tii_sel4_build/scripts/build_guest_linux.sh``` and
```tii_sel4_build/scripts/build_guest_rootfs.sh``` are deleted and you need to
use the Yocto build system directly.

<pre>
host% <b>make shell</b>
container% <b>cd vm-images</b>
# This command will set up your environment for Yocto builds, so remember
# to execute it every time you enter the container.
container% <b>source setup.sh</b>
container% <b>bitbake vm-image-driver</b>
</pre>

Yocto will download and build toolchains and then uses those to build all
packages (including our seL4 related driver-VM guest extensions). On a first run
it will take several hours and you need at least 100 GB disk space for the build.
After the build finishes, you will find the kernel at
```/workspace/vm-images/build/tmp/deploy/images/raspberrypi4-64/Image-raspberrypi4-64.bin```.

**_NOTE:_** You must copy this kernel image to
```${WORKSPACE}/projects/camkes-vm-examples/rpi4/linux``` manually until we get
the build system automation for this.  The guest kernel image is (as of writing
this) embedded into seL4 boot image, therefore you must build the driver VM
image and copy the image before compiling the seL4 image.

The root filesystem will be located at
```/workspace/vm-images/build/tmp/deploy/images/raspberrypi4-64/vm-image-driver-raspberrypi4-64.tar.bz2```.
The root is mounted over NFS and as such you do not need to copy it to ```camkes-vm-examples```. See instructions
below on how to make this root filesystem available to NFS clients.

# Customizing Yocto packages

To customize the guest Linux kernel, use facilities Yocto provides:

<pre>
# Use this to modify just the configs
container% <b>bitbake -c do_menuconfig linux-raspberrypi</b>
container% <b>bitbake linux-raspberrypi</b>

# With devtool you can edit the sources after Yocto has patched them
container% <b>devtool modify kernel-module-sel4-virtio</b>
INFO: Source tree extracted to /workspace/vm-images/build/workspace/sources/kernel-module-sel4-virtio
INFO: Using source tree as build directory since that would be the default for this recipe
INFO: Recipe kernel-module-sel4-virtio now set up to build from /workspace/vm-images/build/workspace/sources/kernel-module-sel4-virtio
</pre>

The module sources are now visible on the host at ```${WORKSPACE}/vm-images/build/workspace/sources/kernel-module-sel4-virtio```,
use your favorite editor to play with them.

<pre>
# To rebuild the rootfs with changes made to kernel module:
container% <b>bitbake vm-image-driver</b>

# Commit your changes to temporary git repo devtool made for you
host% <b>cd ${WORKSPACE}/vm-images/build/workspace/sources/kernel-module-sel4-virtio</b>
host% <b>git commit -a --signoff</b>

# Use devtool to embed the change commits into meta-sel4 layer as patches:
container% <b>devtool update-recipe kernel-module-sel4-virtio</b>
INFO: Adding new patch 0001-Say-hello.patch
INFO: Updating recipe kernel-module-sel4-virtio_git.bb
</pre>

You will find patch you made in ```${WORKSPACE}/vm-images/meta-sel4/recipes-kernel/sel4-virtio/kernel-module-sel4-virtio```
and the patch added to ```SRC_URI``` field in the recipe. To get rid of the working copy:

<pre>
container% <b>devtool reset kernel-module-sel4-virtio</b>
</pre>

# Building Yocto SDK package

TODO: should building/installing the SDK be automated?
Yocto system can build an SDK package installer. The package is primarily
meant for application developers, so that they can have a SDK toolchain
separate from the Yocto build system. We mainly use it to provide GDB debugger,
because the Ubuntus' multiarch GDB seems to have some oddities.

<pre>
host% <b>make shell</b>
container% <b>cd vm-images</b>
# This command will set up your environment for Yocto builds, so remember
# to execute it every time you enter the container.
container% <b>source setup.sh</b>
container% <b>bitbake vm-image-driver -c populate-sdk</b>
</pre>

Yocto will download and build toolchains.
After the build finishes, you will find the SDK at
```/workspace/vm-images/build/tmp/deploy/sdk/```.

# Installing the SDK after build:

<pre>
container% <b>./tmp/deploy/sdk/poky-glibc-x86_64-vm-image-driver-cortexa72-raspberrypi4-64-toolchain-3.4.sh</b>
Poky (Yocto Project Reference Distro) SDK installer version 3.4
===============================================================
Enter target directory for SDK (default: /opt/poky/3.4): 
You are about to install the SDK to "/opt/poky/3.4". Proceed [Y/n]? y
[sudo] password for build: 
Extracting SDK.....................................................................done
Setting it up...done
SDK has been successfully set up and is ready to be used.
Each time you wish to use the SDK in a new shell session, you need to source the environment setup script e.g.
 $ . /opt/poky/3.4/environment-setup-cortexa72-poky-linux
container% <b>ll /opt/poky/3.4/</b>
total 24
drwxr-xr-x. 3 root root   144 Dec 10 11:50 ./
drwxr-xr-x. 3 root root    17 Dec 10 11:49 ../
-rw-r--r--. 1 root root  3848 Dec 10 11:50 environment-setup-cortexa72-poky-linux
-rw-r--r--. 1 root root 14027 Dec 10 11:50 site-config-cortexa72-poky-linux
drwxr-xr-x. 4 root root    62 Dec 10 11:49 sysroots/
-rw-r--r--. 1 root root   119 Dec 10 11:50 version-cortexa72-poky-linux
</pre>

All tools and libraries can now be found from ```/opt/poky/3.4/sysroots/```
