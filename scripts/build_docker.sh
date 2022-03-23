#!/bin/sh

set -e

# Look for these first
# in the environment
# variables.
#
DOCKER_IMAGE="${DOCKER_IMAGE}"
WORKSPACE_DIR="${WORKSPACE_DIR}"
DOCKER_ARGS="${DOCKER_ARGS}"
OTHER_ARGS=""

# Then parse args. Passed
# argument value overrides
# the environment variable
# value (if set).
#
while [ $# -gt 0 ]; do
  case "${1}" in
    -d|--dockerimage)
      DOCKER_IMAGE="${2}"
      shift # past argument
      shift # past value
      ;;
    -w|--workspacedir)
      WORKSPACE_DIR="${2}"
      shift # past argument
      shift # past value
      ;;
    -a|--dockerarg)
      DOCKER_ARGS="${DOCKER_ARGS:+${DOCKER_ARGS}} ${2}"
      shift # past argument
      shift # past value
      ;;
    *)
      OTHER_ARGS="${OTHER_ARGS:+${OTHER_ARGS}} ${1}" # save positional args
      shift # past argument
      ;;
  esac
done

# Validate input arguments.
# Image name is required,
# for workspace directory
# default to current working
# directory if nothing is given.
#
case "${DOCKER_IMAGE}" in
  sel4_builder|yocto_builder|tii_builder)
  ;;
  *)
    printf "%s: ERROR: Docker image name required (sel4_builder|yocto_builder|tii_builder)!\n" "$0" >&2;
    exit 1
  ;;
esac

if test -z "${WORKSPACE_DIR}"; then
  WORKSPACE_DIR="$(pwd)"
fi

set -- "${OTHER_ARGS}"

exec \
  docker build \
  -t "tiiuae/${DOCKER_IMAGE}:latest" \
  -f "${WORKSPACE_DIR}/docker/${DOCKER_IMAGE}.Dockerfile" \
  "${WORKSPACE_DIR}/docker/" \
  ${DOCKER_ARGS} \
  $@
