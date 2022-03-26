WORKSPACEDIR=$(shell pwd)
ACTION=
WORKSPACE_PATH := /workspace/

PLATFORM := rpi4
PLAT_BASEDIR := tii_sel4_build/images/$(PLATFORM)

all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config
	@echo 'ARCH=arm64' >> .config

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

docker: docker_sel4

docker_sel4:
	@scripts/build_docker.sh sel4 $(WORKSPACEDIR)

shell: shell_sel4

shell_sel4:
	@docker/enter_container.sh sel4 $(WORKSPACEDIR)

.PHONY: docker shell
