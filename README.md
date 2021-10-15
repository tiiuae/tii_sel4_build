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
# Choose a working directory
host% <b>export WORKDIR=~/sel4</b>

host% <b>mkdir ${WORKDIR} && cd ${WORKDIR}</b>
host% <b>repo init -u git@github.com:tiiuae/tii_sel4_manifest.git -b tii/development</b>
host% <b>repo sync</b>
</pre>

## Build docker images
<pre>
host% <b>make docker</b>
</pre>

## Use it!

<pre>
host% <b>cd ${WORKDIR}</b>

# configure for Raspberry Pi 4

host% <b>make rpi4_defconfig</b>

# simple seL4 microkernel test

host% <b>make sel4test</b>
host% <b>ls -l rpi4_sel4test/images</b>
-rwxr-xr-x. 1 build build 5832040 Aug 31 08:31 sel4test-driver-image-arm-bcm2711

# More complex examples with VMs

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

# Rebuilding guest Linux kernel

Use ```tii_sel4_build/scripts/build_guest_linux.sh``` in a similar fashion as you
use the ```make``` command in the Linux source tree:

<pre>
# copy config from projects/camkes-vm-images/${TARGET}/linux-configs
# and run 'make olddefconfig'
host% <b>tii_sel4_build/scripts/build_guest_linux.sh olddefconfig</b>

# optionally you can tweak the config
host% <b>tii_sel4_build/scripts/build_guest_linux.sh menuconfig</b>

# run plain 'make'
host% <b>tii_sel4_build/scripts/build_guest_linux.sh</b>

# run 'make savedefconfig', copy the resulting defconfig, Image and modules
# to projects-camkes-vm-images/${TARGET}, note that you must commit the
# binaries to git yourself.
host% <b>tii_sel4_build/scripts/build_guest_linux.sh install</b>
</pre>
