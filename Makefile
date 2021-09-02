all: vm_minimal vm_multi vm_cross_connector .config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > .config
	@echo 'NUM_NODES=4' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

xaviernx_defconfig:
	@echo 'PLATFORM=xaviernx' > .config
	@echo 'NUM_NODES=1' >> .config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config

build_camkes: .config
	@scripts/build_camkes.sh

build_sel4test: .config
	@scripts/build_sel4test.sh

vm_minimal:
	CAMKES_VM_APP=vm_minimal make build_camkes

vm_multi:
	CAMKES_VM_APP=vm_multi make build_camkes

vm_cross_connector:
	CAMKES_VM_APP=vm_cross_connector make build_camkes

sel4test:
	make build_sel4test

.PHONY: docker

docker:
	docker build docker -t tiiuae/build:latest
	docker build docker -f docker/Dockerfile.l4t -t tiiuae/l4t:latest

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
