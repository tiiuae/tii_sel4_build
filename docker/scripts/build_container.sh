#!/bin/bash
#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -ef

############################################
# Setup

# Base images
: "${DEBIAN_IMG:=debian:bullseye}"

# TIIUAE images
: "${BASE_IMG:=tiiuae/base}"
: "${BASE_IMG_DOCKERFILE:=base.Dockerfile}"
: "${TOOLS_IMG:=tiiuae/tools}"
: "${TOOLS_IMG_DOCKERFILE:=tools.Dockerfile}"
: "${USER_IMG:=tiiuae/build-$(id -un)}"
: "${USER_IMG_DOCKERFILE:=user.Dockerfile}"
: "${DEFAULT_IMG_POSTFIX:=latest}"

# Common tools group and GID, so everyone in group can use them
: "${TOOLS_GROUP:=tools}"
: "${TOOLS_GID:=10000}"

# Source util functions with funky bash, as per: https://stackoverflow.com/a/12694189
SCRIPTS_DIR="${0%/*}"
[[ -e "${SCRIPTS_DIR}" ]] || SCRIPTS_DIR=$(pwd)
SCRIPTS_DIR=$(realpath "${SCRIPTS_DIR}")
. "${SCRIPTS_DIR}/utils/utils.sh"

# Fail if we are running as root
if [[ $(id -u) -eq 0 ]]; then
  die "This script cannot be run as root!"
fi

# Use parent directory for context so that
# Docker/Podman can find required files
CONTEXT_DIR=$(realpath "${SCRIPTS_DIR}/../")
[[ -e "${CONTEXT_DIR}" ]] || die "Cannot find parent directory for context!"

# Check that we can find Dockerfiles
DOCKERFILE_DIR="${CONTEXT_DIR}/dockerfiles"
[[ -e "${DOCKERFILE_DIR}" ]] || die "Cannot find Dockerfiles directory!"
DOCKERFILE_DIR=$(realpath "${DOCKERFILE_DIR}")



############################################
# Variables

CENGINE=$(get_container_engine)
CENGINE_BUILD="${CENGINE} build"
CENGINE_BUILD_FLAGS=()
CENGINE_BUILD_ARGS=()
IMG_TO_BUILD=
IMG_POSTFIX=


############################################
# Helpers

build_args_check_set_default()
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

  if ! arr_contains "${value}" "${CENGINE_BUILD_ARGS[@]}"; then
    CENGINE_BUILD_ARGS+=(" --build-arg ${def_value}")
  fi
}

image_exists()
{
  var_set_fail "$1" "Invalid image name!"
  ${CENGINE} image inspect "$1" > /dev/null 2>&1
}

validate_base_image()
{
  var_set_fail "$1" "Base image name not set!"

  # Workaround for -e mode
  if ! image_exists "$1" > /dev/null 2>&1; then
    die "Base image \"$1\" doesn't exist!"
  fi
}

validate_dockerfile()
{
    var_set_fail "$1" "Dockerfile filename not set!"
    file_exists "$1" "Dockerfile \"$1\" doesn't exist!"
}

validate_target_image()
{
    var_set_fail "$1" "Target image name not set!"
    #[[ -n "$1" ]] || die "Target image name not set!"
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

build_image()
{
    check_argc_lt "$#" 3

    local base_image="$1"
    local dockerfile="${DOCKERFILE_DIR}/$2"
    local target_image="$3"
    shift 3  # any params left over are just injected into the build presumably as flags

    # Some sanity checks
    validate_base_image "${base_image}"
    validate_dockerfile "${dockerfile}"
    validate_target_image "${target_image}"

    # Image tagging
    check_set_image_tag image_tag "${target_image}"

    ${CENGINE_BUILD} ${CENGINE_BUILD_FLAGS[*]} \
        --build-arg BASE_IMG="${base_image}" \
        ${CENGINE_BUILD_ARGS[*]} \
        -f "${dockerfile}" \
        ${image_tag} \
        "$@" \
        "${CONTEXT_DIR}"
        
        
}



############################################
# Argparsing

show_help()
{
    cat << 'HELP'
${0} [-r] [-v] -b IMG -e TOOLS_GROUP=tools -e ... -f -q -f --rm -t :latest ...
 -r     Rebuild container images (don't use the cache)
 -v     Verbose mode
 -b     Image to build
 -e     Build arguments (NAME=VALUE) to container build. Use -e for each build arg.
 -f     Flags to container build. Use -f for each build flag.
 -t     Build image tag (e.g ":latest" )
HELP

}

while getopts 'h?vb:re:f:t:' opt;
do
    case "${opt}" in

        h|\?)
        show_help
        exit 0
        ;;

        v)
        set -x
        ;;

        b)
        IMG_TO_BUILD="${OPTARG}"
        ;;

        r)
        CENGINE_BUILD_FLAGS+=(" --no-cache")
        ;;

        e)
        CENGINE_BUILD_ARGS+=(" --build-arg ${OPTARG}")
        ;;

        f)
        CENGINE_BUILD_FLAGS+=(" ${OPTARG}")
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
var_set_fail "${IMG_TO_BUILD}" "You need to supply image name with \"-b\""


############################################
# Processing

case "${IMG_TO_BUILD}" in

    "tiiuae/base")
    # Test for supplied args, set defaults if necessary
    build_args_check_set_default "TOOLS_GROUP" "TOOLS_GROUP=${TOOLS_GROUP}"
    build_args_check_set_default "TOOLS_GID" "TOOLS_GID=${TOOLS_GID}"

    build_image "${DEBIAN_IMG}" "${BASE_IMG_DOCKERFILE}" "${IMG_TO_BUILD}${IMG_POSTFIX}"
    exit 0
    ;;

    "tiiuae/tools")
    build_image "${BASE_IMG}" "${TOOLS_IMG_DOCKERFILE}" "${IMG_TO_BUILD}${IMG_POSTFIX}"
    exit 0
    ;;

    *tiiuae/build-*)
    # Test for supplied args, set defaults if necessary
    build_args_check_set_default "USERNAME" "USERNAME=$(id -un)"
    build_args_check_set_default "USERID" "USERID=$(id -u)"
    build_args_check_set_default "GROUPID" "GROUPID=$(id -g)"
    build_args_check_set_default "GROUPNAME" "GROUPNAME=$(id -gn)"
    
    build_image "${TOOLS_IMG}" "${USER_IMG_DOCKERFILE}" "${IMG_TO_BUILD}${IMG_POSTFIX}"
    exit 0
    ;;

    *)
    die "Invalid image \"${IMG_TO_BUILD}\""
    ;;

esac