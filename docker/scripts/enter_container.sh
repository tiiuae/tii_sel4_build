#!/bin/bash
#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -ef

############################################
# Setup

# TIIUAE images
: "${BASE_IMG:=tiiuae/base}"
: "${TOOLS_IMG:=tiiuae/tools}"
: "${USER_IMG:=tiiuae/build-$(id -un)}"
: "${DEFAULT_IMG_POSTFIX:=latest}"

# Defaults
: "${CONTAINER_VOLUME_HOME:="${USER_IMG}-home"}"
: "${CONTAINER_WORKDIR:="$(pwd)"}"
: "${CONTAINER_WORKDIR_TARGET:=/workspace}"

# Source util functions with funky bash, as per: https://stackoverflow.com/a/12694189
SCRIPTS_DIR="${0%/*}"
[[ -e "${SCRIPTS_DIR}" ]] || SCRIPTS_DIR=$(pwd)
SCRIPTS_DIR=$(realpath "${SCRIPTS_DIR}")
. "${SCRIPTS_DIR}/utils/utils.sh"

# Fail if we are running as root
if [[ $(id -u) -eq 0 ]]; then
  die "This script cannot be run as root!"
fi


############################################
# Variables

CENGINE=$(get_container_engine)
CENGINE_RUN="${CENGINE} run"
CENGINE_RUN_ARGS=()
IMG_TO_RUN=
IMG_POSTFIX=


############################################
# Helpers

volume_exists()
{
  var_set_fail "$1" "Invalid volume name!"
  ${CENGINE} volume exists "$1"
}

image_exists()
{
  var_set_fail "$1" "Invalid image name!"
  ${CENGINE} image inspect "$1" > /dev/null 2>&1
}

run_args_check_set_default()
{
  check_argc_lt "$#" 1

  case "$#" in

    1)
    # Use search value as default value if none is supplied.
    get_var_fail value "$1" "Invalid search value!"
    local def_value="${value}"
    ;;

    2)
    get_var_fail value "$1" "Invalid search value!"
    get_var_fail def_value "$2" "Invalid default value!"
    ;;

  esac

  if ! arr_contains "${value}" "${CENGINE_RUN_ARGS[@]}"; then
    CENGINE_RUN_ARGS+=(" ${def_value}")
  fi
}

common_run_args_check_set_defaults()
{
  run_args_check_set_default "--rm"
  run_args_check_set_default "--hostname" "--hostname ${image_name}"

  # Container engine specific flags
  if is_docker_podman; then
    run_args_check_set_default "--userns=keep-id"
  else
    run_args_check_set_default "-u $(id -u):$(id -g)"
  fi

  run_args_check_set_default "--group-add sudo"
}

user_img_run_args_check_set_defaults()
{
  if volume_exists "${CONTAINER_VOLUME_HOME}"; then
    run_args_check_set_default "-v ${CONTAINER_VOLUME_HOME}:/home/$(id -un)"
  fi
  
  run_args_check_set_default "-v ${CONTAINER_WORKDIR}:${CONTAINER_WORKDIR_TARGET}:z"
}

add_ssh_passthrough()
{
  var_set_fail "${SSH_AUTH_SOCK}" "SSH agent socket not found!"
  file_exists "${SSH_AUTH_SOCK}" "SSH agent socket doesn't exist!"

  local auth_sock=

  if [[ -L "${SSH_AUTH_SOCK}" ]]; then
    # Is a link file
    auth_sock="$(readlink -f "${SSH_AUTH_SOCK}" 2>/dev/null)"
    var_set_fail "${auth_sock}" "readlink failed on \"${SSH_AUTH_SOCK}\"!"
  else
    # Is a normal file
    auth_sock="${SSH_AUTH_SOCK}"
  fi

  # Get absolute path
  auth_sock="$(realpath "${auth_sock}")"
  var_set_fail "${auth_sock}" "Failed to get absolute path to \"${auth_sock}\"!"

  CENGINE_RUN_ARGS+=(" -v ${auth_sock}:/ssh-agent")
  CENGINE_RUN_ARGS+=(" -e SSH_AUTH_SOCK=/ssh-agent")
}

validate_image_name()
{
  var_set_fail "$1" "Invalid target image name!"

  # Workaround for -e mode
  if ! image_exists "$1" > /dev/null 2>&1; then
    die "Target image \"$1\" doesn't exist!"
  fi
}

check_set_interactive()
{
  # Support for non-terminal runs
  if [[ -t 0 ]]; then
    CENGINE_RUN_ARGS+=(" -it")
  fi
}

check_set_image_tag()
{
  check_argc_lt "$#" 2

  var_set_fail "$1" "Invalid target variable!"
  var_set_fail "$2" "Invalid image name!"

  declare -n target="$1"
  get_var img_name "$2"

  # Check if image name has any tag appended to it.
  # Match alphanumeric and punctuation chars.
  # If not, append the default tag.
  # Otherwise just return the same string.
  if ! echo "${img_name}" | grep -Eq ':[[:graph:]]+$'; then
    printf -v target " %s:%s" "-t ${img_name}" "${DEFAULT_IMG_POSTFIX}"
  else
    printf -v target " %s" "-t ${img_name}"
  fi
}

############################################
# Actual magic

run_image()
{
    local image_name="$1"
    shift  # any params left over are just injected into the build presumably as flags

    # Some sanity checks
    validate_image_name "${image_name}"

    # Check/set default run args
    common_run_args_check_set_defaults

    # Test for non-interactive runs
    check_set_interactive

    # Add SSH passthrough
    add_ssh_passthrough

    # Check image tag
    check_set_image_tag image_tag "${image_name}"

    echo "${CENGINE_RUN} \
        ${CENGINE_RUN_ARGS[*]} \
        ${image_tag} \
        "$@"
        "
        
}



############################################
# Argparsing

show_help()
{
    cat << 'HELP'
${0} [-v] -i IMG -e TOOLS_GROUP=tools -a --group-add=sudo -a --rm ... -e PATH=/some/path -t :latest ...
 -v     Verbose mode
 -i     Image to run
 -a     Run arguments. Use -a for each run arg.
 -e     Container env values (e.g PATH=/some/path).
 -t     Image tag (e.g ":latest" )
HELP

}

while getopts 'h?vi:a:e:t:' opt;
do
    case "${opt}" in

        h|\?)
        show_help
        exit 0
        ;;

        v)
        set -x
        ;;

        i)
        IMG_TO_RUN="${OPTARG}"
        ;;

        a)
        CENGINE_RUN_ARGS+=("${OPTARG}")
        ;;

        e)
        CENGINE_RUN_ARGS+=(" -e ${OPTARG}")
        ;;

        t)
        IMG_POSTFIX="${OPTARG}"
        ;;

        :)
        die "Option -${opt} requires an argument."
        ;;

    esac
done

shift "$(($OPTIND - 1))"
var_set_fail "${IMG_TO_RUN}" "You need to supply image name with \"-i\""



############################################
# Processing

case "${IMG_TO_RUN}" in

    "tiiuae/base")
    run_image "${IMG_TO_RUN}${IMG_POSTFIX}"
    exit 0
    ;;

    "tiiuae/tools")
    run_image "${IMG_TO_RUN}${IMG_POSTFIX}"
    exit 0
    ;;

    *tiiuae/build-*)
    # Check/set defaults for user image
    user_img_run_args_check_set_defaults
    run_image "${IMG_TO_RUN}${IMG_POSTFIX}"
    exit 0
    ;;

    *)
    die "Invalid image \"${IMG_TO_RUN}\""
    ;;

esac