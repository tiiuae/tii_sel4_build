all: vm_minimal vm_multi vm_cross_connector /workspace/.config

rpi4_defconfig:
	@echo 'PLATFORM=rpi4' > /workspace/.config
	@echo 'NUM_NODES=4' >> /workspace/.config
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> /workspace/.config

build_camkes: /workspace/.config
	@/workspace/scripts/build_camkes.sh

vm_minimal:
	env `cat /workspace/.config` CAMKES_VM_APP=vm_minimal make build_camkes

vm_multi:
	env `cat /workspace/.config` CAMKES_VM_APP=vm_multi make build_camkes

vm_cross_connector:
	env `cat /workspace/.config` CAMKES_VM_APP=vm_cross_connector make build_camkes

build:
	docker build . -t tiiuae/build:latest
	docker build -f Dockerfile.l4t . -t tiiuae/l4t:latest

shell:
	docker run -it --user l4t --name=l4t-cli --rm=true --net=host --privileged -v ${PWD}:/home/l4t --volume="/dev/bus/usb:/dev/bus/usb" tiiuae/l4t:latest
