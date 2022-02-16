all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

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

build_guest_linux: .config
	@scripts/build_guest_linux.sh

build_guest_rootfs: .config
	@scripts/build_guest_rootfs.sh

.PHONY: docker

docker:
	make sel4_docker

WORKFOLDER=
DOCKERIMG=sel4_build
DOCKERFILE=sel4.Dockerfile

_build_docker:
	docker build docker -t tiiuae/$(DOCKERIMG):latest -f docker/$(DOCKERFILE)

sel4_docker: DOCKERIMG=sel4_build
sel4_docker: DOCKERFILE=sel4.Dockerfile
sel4_docker: _build_docker

yocto_docker: DOCKERIMG=yocto_build
yocto_docker: DOCKERFILE=yocto.Dockerfile
yocto_docker: _build_docker

buildroot_docker: DOCKERIMG=buildroot_build
buildroot_docker: DOCKERFILE=buildroot.Dockerfile
buildroot_docker: _build_docker

_enter_docker:
	@docker/enter_container.sh $(WORKFOLDER) $(DOCKERIMG)

sel4_shell: WORKFOLDER=$(shell pwd)
sel4_shell: DOCKERIMG=sel4_build
sel4_shell: _enter_docker

yocto_shell: WORKFOLDER=$(shell pwd)
yocto_shell: DOCKERIMG=yocto_build
yocto_shell: _enter_docker

buildroot_shell: WORKFOLDER=$(shell pwd)
buildroot_shell: DOCKERIMG=buildroot_build
buildroot_shell: _enter_docker

shell:
	make sel4_shell
