
# Use bash as shell
SHELL := /usr/bin/env bash

# Cosmetics and helpers
RED_FG     := 31
YELLOW_FG  := 33
CYAN_FG    := 36

BOLD   := 1
ITALIC := 3

ECHO_COLOR := \e[$(BOLD);$(CYAN_FG)m
INFO_COLOR := \e[$(BOLD);$(YELLOW_FG)m
WARN_COLOR := \e[$(BOLD);$(RED_FG)m
ENDCOLOR := \e[0m

# Bash helpers
ECHO := @bash -c 'printf "$(ECHO_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE
INFO := @bash -c 'printf "$(INFO_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE
WARN := @bash -c 'printf "$(WARN_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE

ECHO_INSHELL := bash -c 'printf "$(ECHO_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE
INFO_INSHELL := bash -c 'printf "$(INFO_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE
WARN_INSHELL := bash -c 'printf "$(WARN_COLOR)=> $$1\n$(ENDCOLOR)" ' VALUE


# Variables
WORKSPACE_ROOT  ?= $(shell pwd)
SCRIPTS_DIR     ?= $(WORKSPACE_ROOT)/scripts
CONFIG_FILE     ?= $(WORKSPACE_ROOT)/.config
BUILD_SYMLINK   ?= $(WORKSPACE_ROOT)/build
USERNAME        ?= $(shell id -un)
GROUPNAME       ?= $(shell id -gn)
USERID          ?= $(shell id -u)
GROUPID         ?= $(shell id -g)
IMAGE           ?= tiiuae/build
IMAGE_TAG       ?= latest
IMAGE_TAG_DATE  ?= $(shell date +%F.%H%M%S)
PLATFORMS       ?= pc99 qemu-arm-virt qemu-riscv-virt
PLATFORM        ?= pc99

# Container engine vars
CENGINE            := $(shell docker 2>&1 | grep -q podman && echo "podman" || echo "docker")
CENGINE_IMAGE      ?= $(IMAGE):$(IMAGE_TAG)

# Container build vars
CENGINE_BUILD      ?= $(CENGINE) build

# Always remove intermediate containers
CENGINE_BUILD_ARGS ?= --force-rm=true

# Insert build args
CENGINE_BUILD_ARGS += --build-arg USERNAME=$(USERNAME)
CENGINE_BUILD_ARGS += --build-arg GROUPNAME=$(GROUPNAME)
CENGINE_BUILD_ARGS += --build-arg UID=$(USERID)
CENGINE_BUILD_ARGS += --build-arg GID=$(GROUPID)
CENGINE_BUILD_ARGS += -t $(CENGINE_IMAGE)

# Dockerfile build context directory
CENGINE_BUILD_CTX ?= $(WORKSPACE_ROOT)/docker



# Run Bash by default
CENGINE_RUN_EXEC ?= bash

# Use "--rm" flag to remove the container after use
# Support for non-terminal runs by testing if the
# terminal is interactive
CENGINE_RUN_ARGS ?= $(shell test -t 0 && echo '--rm -it' || echo '--rm')

# If we're having Docker then we'll use the `-u` and `-g` options to set the user in the container.
# If we're having Podman then we'll prefer to use '--userns=keep-id' to set up and use the appropriate 
# sub{u,g}id mappings rather than end up using UID 0 in the container
CENGINE_RUN_ARGS += $(shell docker 2>&1 | grep -q podman && echo "--userns=keep-id" || echo "-u $(USERID):$(GROUPID)")

# Set env flags and misc stuff
CENGINE_RUN_ARGS += -e CENGINE=$(CENGINE) -e IN_CONTAINER=true --hostname $(IMAGE)

# Mount .gitconfig to the container if it exists
CENGINE_RUN_ARGS += $(shell test -e $$HOME/.gitconfig && echo " -v $$HOME/.gitconfig:/home/$(USERNAME)/.gitconfig:ro")

# Mount SSH agent to the container if it is running
CENGINE_RUN_ARGS += $(shell test -e $$SSH_AUTH_SOCK && echo " -v $$(realpath $$SSH_AUTH_SOCK):/ssh-agent:ro -e SSH_AUTH_SOCK=/ssh-agent")

# Mount workspace
CENGINE_RUN_ARGS += -v $(WORKSPACE_ROOT):/workspace:z

# Container run command
CENGINE_RUN := $(CENGINE) run $(CENGINE_RUN_ARGS)

all: clean sel4dynamic

.PHONY: check_config build_project sel4dynamic container shell clean_builddirs clean_images

# Force config recreation by removing the config file if 
# platform changes. If the config file doesn't exist at all 
# ("$(PREV_PLATFORM)" is a empty string), do nothing.
check_config: PREV_PLATFORM = $(shell [ -e "$(CONFIG_FILE)" ] && awk -F'=' '/PLATFORM/{print $$2}' "$(CONFIG_FILE)")
check_config:
	@[[ ! -z "$(PREV_PLATFORM)" ]] && [[ "$(PREV_PLATFORM)" != "$(PLATFORM)" ]] && rm -f "$(CONFIG_FILE)" || true

$(CONFIG_FILE):
	$(INFO) '$@: Creating "$(CONFIG_FILE)" for "$(PLATFORM)"'
	@echo -ne "PLATFORM=$(PLATFORM)\nNUM_NODES=4\n" > $@
	@case "$(PLATFORM)" in \
		"qemu-arm-virt") echo -ne "CROSS_COMPILE=aarch64-linux-gnu-\n" >> $@ ;; \
		"qemu-riscv-virt") echo -ne "CROSS_COMPILE=riscv64-unknown-linux-gnu-\n" >> $@ ;; \
	esac


build_project: check_config $(CONFIG_FILE)
	@if [[ -z "$(IN_CONTAINER)" ]]; then \
		$(INFO_INSHELL) '$@: Entering build container "$(CENGINE_IMAGE)"'; \
		$(CENGINE_RUN) $(CENGINE_IMAGE) $(MAKE) $(MAKE_TARGET); \
	else \
		$(INFO_INSHELL) '$@: Building project "$(PROJECT)"'; \
		PROJECT='$(PROJECT)' \
		WORKSPACE_ROOT='$(WORKSPACE_ROOT)' \
		BUILD_SYMLINK='$(BUILD_SYMLINK)' \
		$(SCRIPTS_DIR)/build_sel4.sh; \
	fi


sel4dynamic: MAKE_TARGET = sel4dynamic
sel4dynamic: PROJECT = sel4_dynamic_loader
sel4dynamic: build_project


container:
	$(INFO) '$@: Building container "$(CENGINE_IMAGE)"'
	$(CENGINE_BUILD) $(CENGINE_BUILD_ARGS) $(CENGINE_BUILD_CTX)


shell:
	$(INFO) '$@: Entering container "$(CENGINE_IMAGE)"'
	$(CENGINE_RUN) $(CENGINE_IMAGE) $(CENGINE_EXEC)


clean_builddirs:
	@for plat in $(PLATFORMS); do \
		while IFS= read -r -d $$'\0' builddir; do \
			$(INFO_INSHELL) "$@: Removing build directory \"$$builddir\""; \
			rm -rf "$$builddir"; \
		done < <(find "$(WORKSPACE_ROOT)" -maxdepth 1 -type d -name "build_$${plat}*" -print0); \
	done
	@if [[ -L "$(BUILD_SYMLINK)" ]]; then \
		$(INFO_INSHELL) '$@: Removing symlink "$(BUILD_SYMLINK)"'; \
		rm -f "$(BUILD_SYMLINK)"; \
	fi
# find "$(WORKSPACE_ROOT)" -maxdepth 1 -type d -name "*" -print0 | xargs -0 -I {}


clean_images:
	@if [[ ! $$($(CENGINE) image exists $(IMAGE)) ]]; then \
		$(INFO_INSHELL) '$@: Removing container image "$(IMAGE)"'; \
		$(CENGINE) rmi -f $(IMAGE) 2> /dev/null || true; \
	fi


clean: clean_builddirs
	@if [[ -e "$(CONFIG_FILE)" ]]; then \
		$(INFO_INSHELL) '$@: Removing config "$(CONFIG_FILE)"'; \
		rm -f $(CONFIG_FILE); \
	fi
