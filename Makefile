
DOCKER_IMAGE :=
ifeq ($(strip $(WORKSPACE_DIR)),)
WORKSPACE_DIR := $(shell pwd)
endif
DOCKER_ARGS :=
COMMAND :=

PLATFORM := rpi4
NUM_NODES := 4
CROSS_COMPILE := aarch64-linux-gnu-
ifeq ($(strip $(WORKSPACE_PATH)),)
WORKSPACE_PATH := /workspace
endif
ifeq ($(strip $(ENV_ROOTDIR)),)
ENV_ROOTDIR := $(shell pwd)
endif

PLATFORM_BASEDIR := tii_sel4_build/images/$(PLATFORM)

BR_CONFIG := projects/camkes-vm-images/rpi4/buildroot/buildroot-config
BR_SDK_CONFIG := projects/camkes-vm-images/rpi4/buildroot/buildroot-sdk-config
LINUX_CONFIG := projects/camkes-vm-images/rpi4/linux_configs/config
UBOOT_CONFIG := projects/camkes-vm-images/rpi4/uboot/uboot-config

BUILD_BASEDIR := guest_component_builds

BR_BUILDDIR := $(BUILD_BASEDIR)/buildroot-build
LINUX_BUILDDIR := $(BUILD_BASEDIR)/linux-build
UBOOT_BUILDDIR := $(BUILD_BASEDIR)/uboot-build

BR_SRCDIR := projects/buildroot
LINUX_SRCDIR := projects/torvalds/linux
UBOOT_SRCDIR := projects/uboot

#KERNEL_VERSION := $(shell make -C $(LINUX_SRCDIR) -s kernelversion)
DEST_IMAGEDIR := projects/camkes-vm-images/$(PLATFORM)

.PHONY: docker shell build_uboot build_rootfs build_linux

all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=$(PLATFORM)' > .config
	@echo 'NUM_NODES=$(NUM_NODES)' >> .config
	@echo 'CROSS_COMPILE=$(CROSS_COMPILE)' >> .config

build_camkes: .config
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	ARCH=aarch64 \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	PLATFORM="$(PLATFORM)" \
	NUM_NODES="$(NUM_NODES)" \
	CAMKES_VM_APP="$(CAMKES_VM_APP)" \
	./scripts/build_camkes.sh

build_sel4test: .config
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	ARCH=aarch64 \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	PLATFORM="$(PLATFORM)" \
	NUM_NODES="$(NUM_NODES)" \
	./scripts/build_sel4test.sh

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
ifeq ($(strip $(DOCKER_ARGS)),)
	DOCKER_IMAGE="$(DOCKER_IMAGE)" \
	WORKSPACE_DIR="$(WORKSPACE_DIR)" \
	DOCKER_ARGS="--build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g)" \
	./scripts/build_docker.sh
else
	DOCKER_IMAGE="$(DOCKER_IMAGE)" \
	WORKSPACE_DIR="$(WORKSPACE_DIR)" \
	DOCKER_ARGS="$(DOCKER_ARGS)" \
	./scripts/build_docker.sh
endif

shell: .config
	DOCKER_IMAGE="$(DOCKER_IMAGE)" \
	WORKSPACE_DIR="$(WORKSPACE_DIR)" \
	DOCKER_ARGS="$(DOCKER_ARGS)" \
	./docker/enter_container.sh

build_uboot: .config
	ARCH=arm \
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	DEST_IMGDIR="$(DEST_IMAGEDIR)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	UBOOT_CONFIG="$(UBOOT_CONFIG)" \
	UBOOT_BUILDDIR="$(UBOOT_BUILDDIR)" \
	UBOOT_SRCDIR="$(UBOOT_SRCDIR)" \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	./scripts/build_uboot.sh "$(COMMAND)"

build_rootfs: .config
	ARCH=arm64 \
	BR_BUILDDIR="$(BR_BUILDDIR)" \
	BR_CONFIG="$(BR_CONFIG)" \
	BR_SRCDIR="$(BR_SRCDIR)" \
	BR_SDK_CONFIG="$(BR_SDK_CONFIG)" \
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	DEST_IMGDIR="$(DEST_IMAGEDIR)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	./scripts/build_rootfs.sh "$(COMMAND)"

build_linux: .config
	ARCH=arm64 \
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	DEST_IMGDIR="$(DEST_IMAGEDIR)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	LINUX_CONFIG="$(LINUX_CONFIG)" \
	LINUX_BUILDDIR="$(LINUX_BUILDDIR)" \
	LINUX_SRCDIR="$(LINUX_SRCDIR)" \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	./scripts/build_linux.sh "$(COMMAND)"

build_modules: .config
	ARCH=arm64 \
	CROSS_COMPILE="$(CROSS_COMPILE)" \
	DEST_IMGDIR="$(DEST_IMAGEDIR)" \
	ENV_ROOTDIR="$(ENV_ROOTDIR)" \
	LINUX_BUILDDIR="$(LINUX_BUILDDIR)" \
	MODULE_MAKEFILE="projects/camkes-vm-images/rpi4/modules/Makefile.connection" \
	MODULE_SRCDIR="projects/vm-linux/camkes-linux-artifacts/camkes-linux-modules/camkes-connector-modules/connection" \
	WORKSPACE_PATH="$(WORKSPACE_PATH)" \
	./scripts/build_linux_modules.sh "$(COMMAND)"
