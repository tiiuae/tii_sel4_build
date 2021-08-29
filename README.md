# TII seL4 build system

These instructions have been tested with Ubuntu 20.10 desktop and Fedora 33.

## Setting up the build environment

## Update your computer and install prerequisites

### Ubuntu
```
host% sudo apt-get -y update
host% sudo apt-get -y upgrade
host% sudo apt -y install git
host% sudo apt -y install docker docker.io
host% sudo apt -y install repo
```

### Fedora
```
host$ sudo dnf update
host$ sudo dnf install git
host$ mkdir ~/bin
host$ curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
host$ chmod a+rx ~/bin/repo
```

Follow instructions at <https://docs.docker.com/engine/install/fedora/> to install Docker.

## Configure git
```
host% git config --global user.email "you@example.com"
host% git config --global user.name "Your Name"
```

## Configure docker
```
host% sudo usermod -aG docker $USER
```

Make sure the supplementary group is in use, so log out and back in or reboot your computer.

## Build docker images
```
host% cd ~
host% git clone git@github.com:tiiuae/dockerized_sel4_compile.git
host% cd dockerized_sel4_compile/docker
host% make
```

You might want to add this directory to your PATH in order to use ```enter_container.sh```
without specifying the whole path every time. On both Ubuntu and Fedora this can be done with:
```
host% ln -sf `pwd`/enter_container.sh ~/.local/bin
```

## Test the Docker container
```
host% enter_container.sh
```

The current directory should appear at ```/workspace``` in the container.

## Use it!

### Simple seL4 test

This one builds the seL4 microkernel and a test application that runs a number of
pressure tests.

```
host% repo init -u git@github.com:tiiuae/sel4test-manifest.git -b rpi4
host% repo sync
host% enter_container.sh

guest% export CROSS_COMPILE="aarch64-linux-gnu-"
guest% mkdir rpi4_build
guest% cd rpi4_build
guest% ../init-build.sh -DPLATFORM=rpi4 -DAARCH64=1 -DCROSS_COMPILER_PREFIX=$CROSS_COMPILE
guest% ninja
guest% ls -l images
-rw-r--r--. 1 build build 5656480 Aug 28 02:37 images/sel4test-driver-image-arm-bcm2711
```

### More complex examples with VMs

These examples have Linux guests running on top of seL4 hypervisor. The ```dockerized_sel4_compile``` git
repository contains some helper scripts to help select the proper compilation parameters. Obviously
their location at that repository is an unfortunate choice, so these might be moved to other repository
in the future. Meanwhile, you need to copy them manually to your source tree.

```
host% repo init -u git@github.com:tiiuae/camkes-vm-examples-manifest.git -b rpi4
host% repo sync
host% cp ~/dockerized_sel4_compile/build*.sh .
host% enter_container.sh

guest% make rpi4_defconfig

guest% make vm_minimal
guest% ls -l rpi4_vm_minimal/images
-rwxr-xr-x. 1 build build 37641488 Aug 28 02:50 capdl-loader-image-arm-bcm2711

guest% make vm_multi
guest% ls -l rpi4_vm_multi/images
-rwxr-xr-x. 1 build build 51656592 Aug 28 02:52 capdl-loader-image-arm-bcm2711
```

guest% make vm_cross_connections
guest% ls -l rpi4_vm_cross_connector/images
-rwxr-xr-x. 1 build build 51656608 Aug 28 02:54 capdl-loader-image-arm-bcm2711
```
