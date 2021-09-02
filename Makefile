all: vm_minimal vm_multi .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

rpi4_trace_defconfig: rpi4_defconfig
	@echo 'SEL4_TRACE=ON' >> .config

xaviernx_defconfig:
	@echo 'PLATFORM=xaviernx' > .config
	@echo 'NUM_NODES=1' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

xaviernx_disable_l2d_defconfig: xaviernx_defconfig
	@echo 'OPTS="-DKernelDebugDisableL2Cache=ON"' >> .config

xaviernx_disable_l1i_defconfig: xaviernx_defconfig
	@echo 'OPTS="-DKernelDebugDisableL1ICache=ON"' >> .config

xaviernx_disable_l1i_l2d_defconfig: xaviernx_defconfig
	@echo 'OPTS="-DKernelDebugDisableL1ICache=ON -DKernelDebugDisableL2Cache=ON"' >> .config

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

.PHONY: \
	rpi4_defconfig \
	rpi4_trace_defconfig \
	xaviernx_defconfig \
	xaviernx_disable_l2d_defconfig \
	xaviernx_disable_l1i_defconfig \
	xaviernx_disable_l1i_l2d_defconfig \
	docker

docker:
	docker build docker -t tiiuae/build:latest
	docker build docker -f docker/Dockerfile.l4t -t tiiuae/l4t:latest

linux-image:
	@scripts/build_yocto.sh

shell:
	@docker/enter_container.sh

l4t:
	@docker run -it --user l4t --name=l4t-cli --rm=true --net=host --privileged -v ${PWD}:/home/l4t --volume="/dev/bus/usb:/dev/bus/usb" tiiuae/l4t

Linux_for_Tegra/bootloader/cbo.dtb: hardware/xaviernx/cbo.dts
	dtc -I dts -O dtb -o Linux_for_Tegra/bootloader/cbo.dtb hardware/xaviernx/cbo.dts

xaviernx_buildbl:
	@hardware/xaviernx/buildbl.sh

xaviernx_flashbl: Linux_for_Tegra/bootloader/cbo.dtb
	@hardware/xaviernx/flashbl.sh
