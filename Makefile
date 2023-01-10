#all: vm_minimal vm_multi .config
#
#rpi4_defconfig:
#	@echo 'PLATFORM=rpi4' > .config
#	@echo 'NUM_NODES=4' >> .config
#	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> .config
#
#build_camkes: .config
#	@scripts/build_camkes.sh
#
#build_sel4test: .config
#	@scripts/build_sel4test.sh
#
#include $(wildcard projects/*/Makefile.tii_sel4_build)
#
#vm_minimal:
#	CAMKES_VM_APP=vm_minimal make build_camkes
#
#vm_multi:
#	CAMKES_VM_APP=vm_multi make build_camkes
#
#sel4test:
#	make build_sel4test
#
#.PHONY: docker
#
#docker:
#	docker build docker -t tiiuae/build:latest
#
#linux-image:
#	@scripts/build_yocto.sh
#
#shell:
#	@docker/enter_container.sh


# Docker-compatible image tool to use (could also be 'podman')
DOCKER ?= docker
DOCKERHUB ?= localhost/

HOST_DIR ?= $(shell pwd)

# Images
BASE_IMG ?= tiiuae/base
TOOLS_IMG ?= tiiuae/tools
USER_IMG ?= tiiuae/build-$(shell id -un)

# Volumes
DOCKER_VOLUME_HOME ?= tiiuae/build-$(shell id -un)-home

# Extra vars
DOCKER_BUILD ?= $(DOCKER) build
DOCKER_FLAGS ?= -f --force-rm=true
ifndef EXEC
	EXEC := /bin/bash
	DOCKER_RUN_FLAGS += -it
endif

# Extra arguments to pass to `docker run` if it is or is not `podman` - these
# are constructed in a very verbose way to be obvious about why we want to do
# certain things under regular `docker` vs` podman`
# Note that `docker --version` will not say "podman" if symlinked.
CHECK_DOCKER_IS_PODMAN  := $(DOCKER) --help 2>&1 | grep -q podman
IF_DOCKER_IS_PODMAN     := $(CHECK_DOCKER_IS_PODMAN) && echo
IF_DOCKER_IS_NOT_PODMAN := $(CHECK_DOCKER_IS_PODMAN) || echo
# If we're not `podman` then we'll use the `-u` and `-g` options to set the
# user in the container
EXTRA_DOCKER_IS_NOT_PODMAN_RUN_ARGS := $(shell $(IF_DOCKER_IS_NOT_PODMAN) \
    "-u $(shell id -u):$(shell id -g)" \
)
# If we are `podman` then we'll prefer to use `--userns=keep-id` to set up and
# use the appropriate sub{u,g}id mappings rather than end up using UID 0 in the
# container
EXTRA_DOCKER_IS_PODMAN_RUN_ARGS     := $(shell $(IF_DOCKER_IS_PODMAN) \
    "--userns=keep-id" \
)
# And we'll jam them into one variable to reduce noise in `docker run` lines
EXTRA_DOCKER_RUN_ARGS   := $(EXTRA_DOCKER_IS_NOT_PODMAN_RUN_ARGS) \
                           $(EXTRA_DOCKER_IS_PODMAN_RUN_ARGS)

.PHONY: run_checks
run_checks:
ifeq ($(shell id -u),0)
	@echo "You are running this as root (either via sudo, or directly)."
	@echo "This system is designed to run under your own user account."
	@echo "You can add yourself to the Docker group to make this work:"
	@echo "    sudo su -c usermod -aG docker your_username"
	@exit 1
endif

.PHONY: build_base
build_base: run_checks
	@docker/scripts/build_container.sh -v -b $(BASE_IMG) $(DOCKER_FLAGS)

.PHONY: build_tools
build_tools: run_checks
	@docker/scripts/build_container.sh -v -b $(TOOLS_IMG) $(DOCKER_FLAGS)

.PHONY: build_user
build_user: run_checks
	@docker/scripts/build_container.sh -v -b $(USER_IMG) $(DOCKER_FLAGS)

.PHONY: user_run
user_run:
	@docker/scripts/enter_container.sh -v -i $(USER_IMG) -e TEST=null
#user_run:
#	$(DOCKER) run \
#		$(DOCKER_RUN_FLAGS) \
#		--hostname in-container \
#		--rm \
#		$(EXTRA_DOCKER_RUN_ARGS) \
#		--group-add sudo \
#		-v $(HOST_DIR):/workspace:z \
#		-v $(DOCKER_VOLUME_HOME):/home/$(shell id -un) \
#		$(USER_IMG) $(EXEC)

.PHONY: clean_home_dir
clean_home_dir:
	$(DOCKER) volume rm $(DOCKER_VOLUME_HOME) 2> /dev/null

.PHONY: clean_data
clean_data: clean_home_dir

.PHONY: clean_images
clean_images:
	-$(DOCKER) rmi $(DOCKERHUB)$(BASE_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(TOOLS_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(USER_IMG)

.PHONY: clean
clean: clean_data clean_images