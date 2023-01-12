
WORKSPACE_ROOT ?= $(shell pwd)
CONFIG_FILE ?= $(WORKSPACE_ROOT)/.config
USERNAME ?= $(shell id -un)
GROUPNAME ?= $(shell id -gn)
USERID ?= $(shell id -u)
GROUPID ?= $(shell id -g)
IMAGE ?= tiiuae/build
IMAGE_TAG ?= latest

# Container engine vars
CENGINE := $(shell docker 2>&1 | grep -q podman && echo "podman" || echo "docker")
CENGINE_BUILD ?= $(CENGINE) build
CONTAINER_BUILD_FLAGS ?= --force-rm=true
ifndef CENGINE_EXEC
	CENGINE_EXEC := bash
	CENGINE_RUN_FLAGS += --rm -it
endif

CENGINE_BUILD_CTX ?= $(WORKSPACE_ROOT)


# Extra arguments to pass depending if we have Docker or Podman  - these
# are constructed in a very verbose way to be obvious about why we want to do
# certain things under regular 'docker' vs 'podman'.
# Note that 'docker --version' will not say "podman" if symlinked.
DOCKER_IS_PODMAN  := docker --help 2>&1 | grep -q podman
IF_DOCKER_IS_PODMAN     := $(DOCKER_IS_PODMAN) && echo
IF_DOCKER_IS_NOT_PODMAN := $(DOCKER_IS_PODMAN) || echo

# If we're having Docker then we'll use the `-u` and `-g` options to set the user in the container.
DOCKER_IS_NOT_PODMAN_RUN_ARGS := $(shell $(IF_DOCKER_IS_NOT_PODMAN) "-u $(USERID):$(GROUPID)")

# If we're having Podman then we'll prefer to use '--userns=keep-id' to set up and
# use the appropriate sub{u,g}id mappings rather than end up using UID 0 in the container
DOCKER_IS_PODMAN_RUN_ARGS := $(shell $(IF_DOCKER_IS_PODMAN) "--userns=keep-id")

# And we'll jam them into one variable to reduce noise in `docker run` lines
EXTRA_CONTAINER_RUN_ARGS := $(DOCKER_IS_NOT_PODMAN_RUN_ARGS) $(DOCKER_IS_PODMAN_RUN_ARGS)



#all: vm_minimal vm_multi $(CONFIG_FILE)

arm_defconfig:
	@echo 'PLATFORM=qemu-arm-virt' > $(CONFIG_FILE)
	@echo 'NUM_NODES=4' >> $(CONFIG_FILE)
	@echo 'CROSS_COMPILE=aarch64-linux-gnu-' >> $(CONFIG_FILE)

riscv_defconfig:
	@echo 'PLATFORM=qemu-arm-riscv' > $(CONFIG_FILE)
	@echo 'NUM_NODES=4' >> $(CONFIG_FILE)
	@echo 'CROSS_COMPILE=riscv64-unknown-linux-gnu-' >> $(CONFIG_FILE)

x86_defconfig:
	@echo 'PLATFORM=x86_64' > $(CONFIG_FILE)
	@echo 'NUM_NODES=4' >> $(CONFIG_FILE)

#build_camkes: $(CONFIG_FILE)
#	@scripts/build_camkes.sh

build_sel4test: $(CONFIG_FILE)
	@scripts/build_sel4.sh \
	$(WORKSPACE_ROOT) \
	$(CENGINE) \
	$(IMAGE):$(IMAGE_TAG) \
	projects/build_sel4test

build_sel4dynamic: $(CONFIG_FILE)
	@scripts/build_sel4.sh \
	$(WORKSPACE_ROOT) \
	$(CENGINE) \
	$(IMAGE):$(IMAGE_TAG) \
	projects/sel4_dynamic_loader

sel4test:
	make build_sel4test

sel4dynamic:
	make build_sel4dynamic

.PHONY: container
container: 
	$(CENGINE_BUILD) \
	$(CONTAINER_BUILD_FLAGS) \
	--build-arg USERNAME=$(USERNAME) \
	--build-arg GROUPNAME=$(GROUPNAME) \
	--build-arg UID=$(USERID) \
	--build-arg GID=$(GROUPID) \
	-t $(IMAGE):$(IMAGE_TAG) \
	$(CENGINE_BUILD_CTX)

.PHONY: shell
shell:
	@docker/enter_container.sh \
	$(CENGINE) \
	$(WORKSPACE_ROOT) \
	$(IMAGE):$(IMAGE_TAG) \
	$(CENGINE_EXEC)

