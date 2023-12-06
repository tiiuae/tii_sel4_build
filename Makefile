TARGETS = vm_minimal vm_multi

include $(wildcard projects/*/Makefile.tii_sel4_build)

all:
	@echo Possible make targets are:
	@echo
	@for target in $(TARGETS); do echo "  $$target"; done
	@echo

%:: configs/%
	@cp $< .config

DOCKER_EXPORT = CAMKES_VM_APP
export DOCKER_EXPORT

build_cache: $(BUILD_CACHE_DIR)/stack
	@scripts/build_cache.sh

build_camkes: .config $(BUILD_CACHE_DIR)/stack
	@scripts/build_camkes.sh

build_sel4test: .config
	@scripts/build_sel4test.sh

vm_%: phony_explicit
	CAMKES_VM_APP=$@ make build_camkes

sel4test:
	make build_sel4test

phony_explicit:

.PHONY: \
	all \
	phony_explicit \
	docker

docker:
	docker build docker -t tiiuae/build:latest

linux-image:
	@scripts/build_yocto.sh

shell:
	@docker/enter_container.sh

