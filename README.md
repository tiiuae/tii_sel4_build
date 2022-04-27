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

| NOTE: If you are external (not part of TII organization), you must use ```-m external.xml``` also. This is because TII has internal R&D and as of time being, some of the repositories cannot be shared. |
| --- |

<pre>
# repo commands for externals
host% <b>repo init -u git@github.com:tiiuae/tii_sel4_manifest.git -b tii/development -m external.xml</b>
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

    option root-path "192.168.5.1:/srv/nfs/rpi4,vers=3,proto=tcp";
}
</pre>

It is the most convenient to use TCP since the Fedora firewall will block UDP
by default.

### Extract root filesystem to NFS share

<pre>
host% <b>sudo tar -C /srv/nfs/rpi4 -xjpvf ${WORKSPACE}/vm-images/build/tmp/deploy/images/raspberrypi4-64/vm-image-driver-raspberrypi4-64.tar.bz2</b>
</pre>

### Setup Raspberry Pi 4 for network booting

| TBD: add Raspberry Pi 4 DHCP+TFTP+NFS booting instructions! |
| --- |

# QEMU, virtio and seL4

The ```vm_qemu_virtio``` example demonstrates TII's experimental work to bring QEMU-backed
virtio devices into guest VMs. An instance of QEMU is running in driver-VM and it provides
virtio-blk, virtio-console, virtio-net and virtfs to the user-VM guest. This demo abandons
Buildroot and uses Yocto to build the guest VM images.

<pre>
host$ <b>repo init -u git@github.com:tiiuae/tii_sel4_manifest.git -b wip/hlyytine-virtio-blk -m virtio-qemu.xml</b>
host$ <b>repo sync</b>
host$ <b>make docker</b>

# build driver-VM and user-VM images
host$ <b>make shell</b>
container$ <b>cd vm-images</b>
container$ <b>. setup.sh</b>
container$ <b>bitbake vm-image-driver</b>
container$ <b>bitbake vm-image-user</b>

# copy kernel image in place, and build qemu seL4 vm_qemu_virtio
container$ <b>cp vm-images/build/tmp/deploy/images/raspberrypi4-64/Image projects/camkes-vm-images/rpi4/linux</b>
container$ <b>make rpi4_defconfig</b>
container$ <b>make vm_qemu_virtio</b>
# exit container
container$ <b>exit</b>

# copy seL4 image to TFTP directory
host$ <b>cp rpi4_vm_qemu_virtio/images/capdl-loader-image-arm-bcm2711 /var/lib/tftpboot</b>

# expose driver-VM image via NFS (update your directory to command)
host$ <b>tar -C /srv/nfs/rpi4 -xjpvf vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-driver-raspberrypi4-64.tar.bz2</b>

# copy user-VM image to NFS
host$ <b>cp vm-images/build/tmp/deploy/images/vm-raspberrypi4-64/vm-image-user-vm-raspberrypi4-64.wic.qcow2 /srv/nfs/rpi4/myimg.qcow2</b>

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
