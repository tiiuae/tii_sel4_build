#! /bin/bash

# Global variables
SSH_DIR="${HOME}/.ssh"
SSH_DIR_MODE=700
SSH_PRIV_KEY_MODE=600
SSH_PUB_KEY_MODE=644
SSH_ALL_KEYS_PATTERN="public|private"
SSH_PUB_KEYS_PATTERN="public"
SSH_PRIV_KEYS_PATTERN="private"

# Crude logging functions
log_stdout()
{
  printf "%s: %s\n" "$0" "$*" >&1;
}

log_stderr()
{
  printf "%s: %s\n" "$0" "$*" >&2;
}

die()
{ 
  log_stderr "$*"; exit 111
}

check_container_runner() {
  if [[ -z "${CONTAINER_RUNNER}" ]]; then
    die "CONTAINER_RUNNER env variable not set!"
  else
    echo "Running inside \"${CONTAINER_RUNNER}\" container"
  fi
}

ssh_secrets_to_files() {

  while IFS= read -r -d '' filename; do

  # Skip if 'find' somehow globs
  # together a non-existing filename.
  [[ -e "${filename}" ]] || continue

  local file_output="$(file "${filename}")"
  local key_dest="${SSH_DIR}/$(basename "${filename}")"

  # Only accept OpenSSH key files
  if [[ "${file_output}" =~ ${SSH_ALL_KEYS_PATTERN} ]]; then

    cp "${filename}" "${key_dest}"
    chown "$(id -un):$(id -gn)" "${key_dest}"

    if [[ "${file_output}" =~ public ]]; then
      chmod "${SSH_PUB_KEY_MODE}" "${key_dest}"
    elif [[ "${file_output}" =~ private ]]; then
      chmod "${SSH_PRIV_KEY_MODE}" "${key_dest}"
    fi

    # Delete the secret file as it isn't needed anymore
    rm -f "${filename}" > /dev/null 2>&1
  fi

  done < <(find "/run/secrets/" -type f -print0)
}

get_ssh_keys() {

  if [[ "${CONTAINER_RUNNER}" == "podman" ]]; then

    # Convert Podman secrets to SSH keys
    ssh_secrets_to_files

  elif [[ "${CONTAINER_RUNNER}" == "docker" ]]; then

    # With Docker, the directory should already exist
    # as a bind mount. Fail if this isn't the case.

    if ! [[ -e "${SSH_DIR}" ]]; then
      die "${SSH_DIR} directory doesn't exist!"
    fi

  else
    die "CONTAINER_RUNNER env variable not set!"
  fi

  # Now add all private SSH keys to agent.
  ssh_keys=()

  while IFS= read -r -d '' filename; do

    # Skip if 'find' somehow globs
    # together a non-existing filename.
    [[ -e "${filename}" ]] || continue

    # Only accept OpenSSH key files
    if [[ "$(file "${filename}")" =~ ${SSH_PRIV_KEYS_PATTERN} ]]; then
      ssh_keys+=( "${filename}" )
    fi
  done < <(find "${SSH_DIR}" -type f -print0)

  if [[ -z "${ssh_keys}" ]]; then
    die "Did not find any SSH keys!"
  fi

  for ssh_key in "${ssh_keys[@]}"; do
    ssh-add "${ssh_key}" > /dev/null
  done
}

setup_env() {

  local cur_user=$(id -un)
  local cur_group=$(id -gn)
  local ssh_dir_user=$(stat -c "%U" "${SSH_DIR}")
  local ssh_dir_group=$(stat -c "%G" "${SSH_DIR}")

  # Create directory if it doesn't exist.
  # Otherwise, check ownership and permissions,
  # correct them if necessary.
  if ! [[ -e "${SSH_DIR}" ]]; then
    mkdir -m "${SSH_DIR_MODE}" "${SSH_DIR}" && \
      chown -R "${cur_user}:${cur_group}" "${SSH_DIR}"
  else
    if [[ "${cur_user}" != "${ssh_dir_user}" ]] || \
       [[ "${cur_group}" != "${ssh_dir_group}" ]]; then
       chown -R "${cur_user}:${cur_group}" "${SSH_DIR}"
    fi

    if [[ "${SSH_DIR_MODE}" != $(stat -c "%a" "${SSH_DIR}") ]]; then
      chmod "${SSH_DIR_MODE}" "${SSH_DIR}"
    fi
  fi

  # Check if SSH agent is running
  if [[ -z "${SSH_AUTH_SOCK}" || -z "${SSH_AGENT_PID}" ]]; then
    eval "$(ssh-agent -s)"
    sleep 1
  fi

  # Bail out if the agent does not start
  if [[ -z "${SSH_AUTH_SOCK}" || -z "${SSH_AGENT_PID}" ]]; then
    die "SSH agent refuses to start!"
  fi


  get_ssh_keys
}

setup_env