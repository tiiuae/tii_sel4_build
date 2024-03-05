TARGETS = vm_minimal vm_multi

include $(wildcard projects/*/Makefile.tii_sel4_build)

all:
	@echo Possible make targets are:
	@echo
	@for target in $(TARGETS); do echo "  $$target"; done
	@echo

%:: configs/%
	@cp $< .config

BUILD_CACHE_DIR ?= $(shell realpath .tii_sel4_build)
export BUILD_CACHE_DIR

DOCKER_EXPORT = CAMKES_VM_APP
export DOCKER_EXPORT

$(BUILD_CACHE_DIR)/stack:
	mkdir -p $(BUILD_CACHE_DIR)/stack
	@scripts/build_cache.sh

build_cache: $(BUILD_CACHE_DIR)/stack

build_camkes: .config build_cache
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
	docker build \
		--build-arg UID=$(shell id -u) \
		--build-arg GID=$(shell id -g) \
		docker -t tiiuae/build:latest

linux-image:
	@scripts/build_yocto.sh

shell:
	@docker/enter_container.sh

