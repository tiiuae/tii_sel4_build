#!/bin/bash
#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Global variables
CONTAINER_RUNNER=
CONTAINER_SSH_DIR=
CONTAINER_PRIVDATA_DIR=
CONTAINER_PRIVDATA_DIR_MODE=700
SSH_DIR_MODE=700
SSH_PRIV_KEY_MODE=600
SSH_PUB_KEY_MODE=644
SSH_DIR_SKIP_PATTERN="authorized*"
SSH_ALL_KEYS_PATTERN="public|private"
SSH_PUB_KEYS_PATTERN="public"
SSH_PRIV_KEYS_PATTERN="private"





# When using rootless Podman on a SELinux
# enabled system, it is difficult to reasonably
# pass through data that should be kept secure,
# in this case SSH keys. 
#
# If your users .ssh directory is directly bind
# mounted to the Podman container, it cannot be
# accessed inside the container as the SELinux
# prevents access due to label mismatch.
#
# The next option is to use relabeling flag (:z or :Z)
# with the bind mount of .ssh directory.
# This will work, but it creates another problem,
# as when you run the container, your users .ssh
# directory is relabeled for container access. After
# you exit the container, the .ssh directory isn't
# relabeled back to previous label.
#
# I'm not sure if this is an actual issue, but
# I think its still reasonable to try to avoid
# this issue altogether with some scripting.
# 
# Podman supports 'secrets', for details see 
# here: https://docs.podman.io/en/latest/markdown/podman-secret.1.html
# All secrets are visible to the container in "run/secrets/" path.
#
# Docker also has support for secrets, but only
# in Swarm mode, and not on standalone containers
# like what we use here. For this case, this script
# will generate a temporary private data directory
# for the container, where the SSH keys (and possibly
# other wanted files) are copied to, and then this
# directory is passed through to the container with
# bind mount.
#
# Naturally, using secrets with Podman is more secure
# way, as it is a tool designed to keep the data secure.
# The "copy keys to temp dir" approach with Docker
# isn't optimal, but it works reasonably as long as
# the directory is deleted right after the container exits.
#
podman run --rm -it -v $(readlink -f $SSH_AUTH_SOCK 2>/dev/null):/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent test-debian:latest /bin/bash


copy_ssh_keys() {

  if ! [[ -e "${CONTAINER_PRIVDATA_DIR}" ]]; then
    die "Cannot find container private data directory!"
  fi

  # Remove previous keys,
  # if not removed already
  delete_ssh_keys

  # Ensure we are using absolute paths.
  CONTAINER_SSH_DIR="$(realpath "${CONTAINER_PRIVDATA_DIR}")/.ssh"

  if ! mkdir -m "${SSH_DIR_MODE}" "${CONTAINER_SSH_DIR}"; then
    die "Failed to create SSH directory!"
  fi

  while IFS= read -r -d '' filename; do

    # Skip if 'find' somehow globs
    # together a non-existing filename.
    [[ -e "${filename}" ]] || continue

    # Skip non-wanted if encountered
    [[ "${filename}" =~ ${SSH_DIR_SKIP_PATTERN} ]] && continue

    local file_output="$(file "${filename}")"

    # Copy only public/private keys
    if [[ "${file_output}" =~ ${SSH_ALL_KEYS_PATTERN} ]]; then
      cp -p "${filename}" "${CONTAINER_SSH_DIR}/$(basename "${filename}")"
    fi

  done < <(find "${HOME}/.ssh/" -type f -print0)
}

delete_ssh_keys() {
  if [[ -n "${CONTAINER_SSH_DIR}" ]] && \
     [[ -e "${CONTAINER_SSH_DIR}" ]]; then
    rm -rf "${CONTAINER_SSH_DIR}"
    unset CONTAINER_SSH_DIR
  fi
}

setup_env() {

  # Set runner engine
  if is_docker_podman; then
    CONTAINER_RUNNER="podman"
  else
    CONTAINER_RUNNER="docker"
  fi

  # Setup private data directory
  setup_privdata $@

  # Copy SSH keys to temp folder
  copy_ssh_keys
}

#ssh_args=$(
#            IFS="${ENV_IFS}" read -r -a keys <<< "${CONTAINER_SSH_KEYS}"
#            printf " -v %s:/home/${user}/%s:Z \\ \n" "${keys[@]}" "${keys[@]##*/}"
#          )

get_args() {

  local base_args=""
  local ssh_args=""
  local mount_args=""
  local user="build"

  if is_docker_podman; then
    base_args="-e CONTAINER_RUNNER=podman --userns=keep-id --cap-add=CAP_SYS_MODULE"
    ssh_args=$(printf " --secret %s " "${CONTAINER_SSH_SECRETS[@]}")
  else
    base_args="-e CONTAINER_RUNNER=docker --add-host host.docker.internal:host-gateway"
    ssh_args=$(printf " -v %s:/home/${user}/.ssh:Z " "${CONTAINER_SSH_DIR}")
  fi

  # Bind mount all the input files/folders.
  # Ignore hidden files and folders.

  if [[ -e "${CONTAINER_PRIVDATA_DIR}" ]]; then

    # Bash >=4.4 supports readarray.
    # Otherwise need to use construct:
    # while IFS= read -r -d '' filename; do
    #   do stuff...
    # done < <(find "${CONTAINER_PRIVDATA_DIR}" -mindepth 1 -not \( -path "${CONTAINER_PRIVDATA_DIR}/.ssh" -prune \) -print0)
    
    readarray -d '' files < <(find "${CONTAINER_PRIVDATA_DIR}" -mindepth 1 -not \( -path "${CONTAINER_PRIVDATA_DIR}/.ssh" -prune \) -print0)

    if [[ -n "${files}" ]]; then
      mount_args=$(printf " -v %s:/home/${user}/%s:Z " "${files[@]}" "${files[@]##*/}")
    fi
  fi

  printf " %s %s %s " "${base_args}" "${ssh_args}" "${mount_args}"
}

create_privdata_directory() {

  delete_privdata_directory

  # Create private data dir with randomized name
  CONTAINER_PRIVDATA_DIR="$(pwd)/.container_$(openssl rand -hex 10)"

  if ! mkdir -m "${CONTAINER_PRIVDATA_DIR_MODE}" "${CONTAINER_PRIVDATA_DIR}"; then
    die "Failed to create private data directory!"
  fi
}

delete_privdata_directory() {
  if [[ -n "${CONTAINER_PRIVDATA_DIR}" ]] && \
     [[ -e "${CONTAINER_PRIVDATA_DIR}" ]]; then
    rm -rf "${CONTAINER_PRIVDATA_DIR}"
    unset CONTAINER_PRIVDATA_DIR
  fi
}

setup_privdata() {

  local files="$@"

  create_privdata_directory

  # Copy over any input files
  if [[ -n "${files}" ]]; then
    for f in ${files}; do
      cp "${f}" "${CONTAINER_PRIVDATA_DIR}/$(basename "${f}")"
    done
  fi
}

cleanup() {
  delete_ssh_secrets
  delete_ssh_keys
  delete_privdata_directory
}
