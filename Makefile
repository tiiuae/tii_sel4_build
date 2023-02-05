all: vm_minimal vm_multi .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

rpi4_trace_defconfig: rpi4_defconfig
	@echo 'SEL4_TRACE=ON' >> .config

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

sel4cp_sdk:
	@cd sel4cp/sel4cp && python build_sdk.py --sel4=/workspace/sel4cp/sel4

sel4cp_hello: .config
	@scripts/build_sel4cp.sh hello

.PHONY: \
	rpi4_defconfig \
	rpi4_trace_defconfig \
	sel4cp_sdk \
	sel4cp_hello \
	docker

docker:
	@docker/build.sh

linux-image:
	@scripts/build_yocto.sh

shell:
	@docker/enter_container.sh

