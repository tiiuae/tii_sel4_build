#!/bin/sh

set -e

DOCKER_IMAGE=""
WORKSPACE_DIR=""
ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    -i|--image)
      DOCKER_IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
    -w|--workspacedir)
      WORKSPACE_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      ARGS+=" $1" # save positional args
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

if test -z "{$WORKSPACE_DIR}"; then
  WORKSPACE_DIR="$(pwd)"
fi

set -- "${ARGS}"

exec \
  docker build \
  -t "tiiuae/${DOCKER_IMAGE}:latest" \
  -f "${WORKSPACE_DIR}/docker/${DOCKER_IMAGE}.Dockerfile" \
  "${WORKSPACE_DIR}/docker/" \
  $@
