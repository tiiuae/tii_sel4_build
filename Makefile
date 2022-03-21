WORKSPACE=$(shell pwd)
IMAGE=
COMMAND=

PLATFORM := rpi4
NUM_NODES := 4
CROSS_COMPILE := aarch64-linux-gnu-
WORKSPACE_PATH := /workspace
ENV_ROOTDIR := $(shell pwd)

PLATFORM_BASEDIR := tii_sel4_build/images/$(PLATFORM)

BUILDROOT_CONFIG := $(PLATFORM_BASEDIR)/buildroot-config
BUILDROOT_SDK_CONFIG := $(PLATFORM_BASEDIR)/buildroot-sdk-config
KERNEL_CONFIG := $(PLATFORM_BASEDIR)/linux-config
UBOOT_CONFIG := $(PLATFORM_BASEDIR)/uboot-config

BUILDROOT_BUILDDIR := buildroot-build
KERNEL_BUILDDIR := linux-build
UBOOT_BUILDDIR := uboot-build

BUILDROOT_SRCDIR := projects/buildroot
KERNEL_SRCDIR := projects/torvalds/linux
UBOOT_SRCDIR := projects/uboot

KERNEL_VERSION := $(shell make -C $(KERNEL_SRCDIR) -s kernelversion)
DEST_IMAGEDIR := projects/camkes-vm-images/$(PLATFORM)

all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=$(PLATFORM)' > .config
	@echo 'NUM_NODES=$(NUM_NODES)' >> .config
	@echo 'CROSS_COMPILE=$(CROSS_COMPILE)' >> .config
	@echo 'ARCH=arm64' >> .config
	@echo 'WORKSPACE_PATH=$(WORKSPACE_PATH)' >> .config

build_camkes: .config
	CROSS_COMPILE=$(CROSS_COMPILE) \
	ARCH=aarch64 \
	WORKSPACE_PATH=$(WORKSPACE_PATH) \
	ENV_ROOTDIR=$(ENV_ROOTDIR) \
	PLATFORM=$(PLATFORM) \
	NUM_NODES=$(NUM_NODES) \
	CAMKES_VM_APP=$(CAMKES_VM_APP) \
	./scripts/build_camkes.sh

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

docker: .config
	@scripts/build_docker.sh --image $(IMAGE) --workspacedir $(WORKSPACE)

shell: .config
	@docker/enter_container.sh --image $(IMAGE) --workspacedir $(WORKSPACE)

build_uboot: .config
	CROSS_COMPILE=$(CROSS_COMPILE) \
	ARCH=arm \
	WORKSPACE_PATH=$(WORKSPACE_PATH) \
	ENV_ROOTDIR=$(ENV_ROOTDIR) \
	CONFIG=$(UBOOT_CONFIG) \
	BUILDDIR=$(UBOOT_BUILDDIR) \
	SRCDIR=$(UBOOT_SRCDIR) \
	IMGDIR=$(DEST_IMAGEDIR) \
	./scripts/build_uboot.sh $(COMMAND)

build_rootfs: .config
	CROSS_COMPILE=$(CROSS_COMPILE) \
	ARCH=arm64 \
	WORKSPACE_PATH=$(WORKSPACE_PATH) \
	ENV_ROOTDIR=$(ENV_ROOTDIR) \
	CONFIG=$(BUILDROOT_CONFIG) \
	SDK_CONFIG=$(BUILDROOT_SDK_CONFIG) \
	BUILDDIR=$(BUILDROOT_BUILDDIR) \
	SRCDIR=$(BUILDROOT_SRCDIR) \
	IMGDIR=$(DEST_IMAGEDIR) \
	LINUX_KERNEL_VERSION=$(KERNEL_VERSION) \
	./scripts/build_rootfs.sh $(COMMAND)

build_linux: .config
	CROSS_COMPILE=$(CROSS_COMPILE) \
	ARCH=arm64 \
	WORKSPACE_PATH=$(WORKSPACE_PATH) \
	ENV_ROOTDIR=$(ENV_ROOTDIR) \
	CONFIG=$(KERNEL_CONFIG) \
	BUILDDIR=$(KERNEL_BUILDDIR) \
	SRCDIR=$(KERNEL_SRCDIR) \
	IMGDIR=$(DEST_IMAGEDIR) \
	./scripts/build_linux.sh $(COMMAND)
