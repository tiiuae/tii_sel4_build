#!/bin/sh

set -eE


# Look for these first
# in the environment
# variables.
#
DOCKER_ENVFILE="${DOCKER_ENVFILE}"
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
    -e|--envfile)
      DOCKER_ENVFILE="${2}"
      shift # past argument
      shift # past value
      ;;
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
# Env file is optional,
# Docker image name is required,
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

# The printf is a hack for getting
# around the problem that parameter
# expansion encloses the result in single
# quotes, which wreaks havoc when inserted
# to Docker run arguments. Printing the
# the expansion result removes the quotes.
#

set -- "${OTHER_ARGS}"

exec \
  docker run \
  --rm -it \
  $(printf "%b" "${DOCKER_ENVFILE:+"--env-file ${DOCKER_ENVFILE}"}") \
  -v "${WORKSPACE_DIR}":/workspace:z \
  -v "${HOME}"/.ssh:/home/build/.ssh:z \
  -v "${HOME}"/.gitconfig:/home/build/.gitconfig:z \
  --add-host host.docker.internal:host-gateway \
  -h "${DOCKER_IMAGE}" \
  "tiiuae/${DOCKER_IMAGE}:latest" \
  ${DOCKER_ARGS} \
  $@
