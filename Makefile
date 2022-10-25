all: vm_minimal vm_multi .config

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

sel4test:
	make build_sel4test

.PHONY: docker

docker:
	docker build docker -t tiiuae/build:latest

linux-image:
	@scripts/build_yocto.sh

shell:
	@docker/enter_container.sh

