WORKSPACEDIR=$(shell pwd)
ACTION=

all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config
	@echo 'BASEDIR=/workspace/tii_sel4_build/linux-images' >> .config
	@echo 'KERNELSRCDIR=/workspace/projects/torvalds/linux' >> .config
	@echo 'BRSRCDIR=/workspace/projects/buildroot' >> .config

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

guest_rootfs: .config
	@scripts/build_guest_rootfs.sh $(ACTION)

guest_linux: .config
	@scripts/build_guest_linux.sh $(ACTION)

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
