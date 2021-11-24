# TII seL4 build system

These instructions have been tested with Ubuntu 20.10 desktop and Fedora 33.

## Setting up the build environment

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

host% <b>make vm_cross_connector</b>
host% <b>ls -l rpi4_vm_cross_connector/images</b>
-rwxr-xr-x. 1 build build 51656608 Aug 28 02:54 capdl-loader-image-arm-bcm2711

# Enter build container interactively -- you get all tools
# (for example, aarch64-linux-gnu toolchain) without having
# to install them onto host.

host% <b>make shell</b>

container% <b>aarch64-linux-gnu-objdump -D rpi4_sel4test/kernel/kernel.elf</b>
</pre>

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

# Network booting

This seL4 playground boots from network.

## Setting up NFS root

Create a directory on the NFS server:

<pre>
host% <b>sudo mkdir -p /exports/rpi4</b>
</pre>

Add this directory to NFS exports:

<pre>
host% <b>cat /etc/exports</b>
/exports/rpi4 192.168.5.0/24(rw,no_root_squash)
host% <b>sudo exportfs -a</b>
</pre>

## Pass NFS server info via DHCP

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

    option root-path "192.168.5.1:/exports/rpi4,vers=3,proto=tcp";
}
</pre>

It is the most convenient to use TCP since the Fedora firewall will block UDP
by default.

## Extract root filesystem to NFS share

<pre>
host% <b>sudo tar -C /exports/rpi4 -xjpvf ${WORKSPACE}/vm-images/build/tmp/deploy/images/raspberrypi4-64/vm-image-driver-raspberrypi4-64.tar.bz2</b>
</pre>
