IMAGE=sel4
WORKSPACEDIR=$(shell pwd)
BASEDIR=/workspace/tii_sel4_build/linux-images
KERNELSRCDIR=/workspace/projects/torvalds/linux
BRSRCDIR=/workspace/projects/buildroot
ACTION=

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

guest_linux: .config
	@scripts/build_guest_linux.sh -b $(BASEDIR) -s $(KERNELSRCDIR) -a $(ACTION)

guest_rootfs: .config
	@scripts/build_guest_rootfs.sh -b $(BASEDIR) -s $(BRSRCDIR) -a $(ACTION)

docker:
	@scripts/build_docker.sh -i $(IMAGE) -w $(WORKSPACEDIR)

shell:
	@docker/enter_container.sh -i $(IMAGE) -w $(WORKSPACEDIR)

.PHONY: docker shell
