WORKSPACEDIR=$(shell pwd)
ACTION=

WORKSPACE_PATH := /workspace/
PLATFORM := rpi4
PLAT_BASEDIR := tii_sel4_build/images/$(PLATFORM)

BR_CONFIG := $(PLAT_BASEDIR)/buildroot-config
KERNEL_CONFIG := $(PLAT_BASEDIR)/linux-config
UBOOT_CONFIG := $(PLAT_BASEDIR)/uboot-config

BR_BUILDDIR := $(PLAT_BASEDIR)/br-build
KERNEL_BUILDDIR := $(PLAT_BASEDIR)/linux-build
UBOOT_BUILDDIR := $(PLAT_BASEDIR)/uboot-build

BR_SRCDIR := projects/buildroot
KERNEL_SRCDIR := projects/torvalds/linux
UBOOT_SRCDIR := projects/uboot

KERNEL_VER := $(shell make -C $(KERNEL_SRCDIR) -s kernelversion)
DEST_IMGDIR := projects/camkes-vm-images/$(PLATFORM)

all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config
	@echo 'ARCH=arm64' >> .config
	@echo 'WORKSPACE_PATH=$(WORKSPACE_PATH)' >> .config
	@echo 'BR_CONFIG=$(addprefix $(WORKSPACE_PATH), $(BR_CONFIG))' >> .config
	@echo 'BR_BUILDDIR=$(addprefix $(WORKSPACE_PATH), $(BR_BUILDDIR))' >> .config
	@echo 'BR_SRCDIR=$(addprefix $(WORKSPACE_PATH), $(BR_SRCDIR))' >> .config
	@echo 'LINUX_CONFIG=$(addprefix $(WORKSPACE_PATH), $(KERNEL_CONFIG))' >> .config
	@echo 'LINUX_BUILDDIR=$(addprefix $(WORKSPACE_PATH), $(KERNEL_BUILDDIR))' >> .config
	@echo 'LINUX_SRCDIR=$(addprefix $(WORKSPACE_PATH), $(KERNEL_SRCDIR))' >> .config
	@echo 'UBOOT_CONFIG=$(addprefix $(WORKSPACE_PATH), $(UBOOT_CONFIG))' >> .config
	@echo 'UBOOT_BUILDDIR=$(addprefix $(WORKSPACE_PATH), $(UBOOT_BUILDDIR))' >> .config
	@echo 'UBOOT_SRCDIR=$(addprefix $(WORKSPACE_PATH), $(UBOOT_SRCDIR))' >> .config
	@echo 'IMGDIR=$(addprefix $(WORKSPACE_PATH), $(DEST_IMGDIR))' >> .config
	@echo 'KERNELVER=$(KERNEL_VER)' >> .config

build_camkes: .config
	@scripts/build_camkes.sh

build_sel4test: .config
	@scripts/build_sel4test.sh

include $(wildcard projects/*/Makefile.tii_sel4_build)

vm_minimal:
	CAMKES_VM_APP=vm_minimal make build_camkes

vm_multi:
	CAMKES_VM_APP=vm_multi make build_camkes

vm_cross_connector:
	CAMKES_VM_APP=vm_cross_connector make build_camkes

sel4test:
	make build_sel4test

build_guest_rootfs: .config
	@scripts/build_guest_rootfs.sh olddefconfig
	@scripts/build_guest_rootfs.sh build
	@scripts/build_guest_rootfs.sh install

build_guest_linux: .config
	@scripts/build_guest_linux.sh olddefconfig
	@scripts/build_guest_linux.sh build
	@scripts/build_guest_linux.sh install

build_uboot: .config
	@scripts/build_uboot.sh olddefconfig
	@scripts/build_uboot.sh build
	@scripts/build_uboot.sh install

guest_rootfs: .config
	@scripts/build_guest_rootfs.sh $(ACTION)

guest_linux: .config
	@scripts/build_guest_linux.sh $(ACTION)

uboot: .config
	@scripts/build_uboot.sh $(ACTION)

docker: docker_sel4

docker_sel4:
	@scripts/build_docker.sh sel4 $(WORKSPACEDIR)

docker_yocto:
	@scripts/build_docker.sh yocto $(WORKSPACEDIR)

docker_br:
	@scripts/build_docker.sh buildroot $(WORKSPACEDIR)

docker_uboot:
	@scripts/build_docker.sh uboot $(WORKSPACEDIR)

docker_kernel:
	@scripts/build_docker.sh kernel $(WORKSPACEDIR)

shell: shell_sel4

shell_sel4:
	@docker/enter_container.sh sel4 $(WORKSPACEDIR)

shell_yocto:
	@docker/enter_container.sh yocto $(WORKSPACEDIR)

shell_br:
	@docker/enter_container.sh buildroot $(WORKSPACEDIR)

shell_uboot:
	@docker/enter_container.sh uboot $(WORKSPACEDIR)

shell_kernel:
	@docker/enter_container.sh kernel $(WORKSPACEDIR)

.PHONY: docker shell
