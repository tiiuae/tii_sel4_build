#! /bin/bash

. docker/utils.sh

# Function in 'utils.sh'
trap cleanup 0 1 2 3 6 14 15

WORKSPACE_DIR=$1
if ! [[ -e "${WORKSPACE_DIR}" ]] ; then
  WORKSPACE_DIR=$(pwd)
else
  shift
fi

CONTAINER_CMD="$*"
if [[ -z "${CONTAINER_CMD}" ]]; then
  CONTAINER_CMD="/bin/bash"
fi

# Support for non-terminal runs
CONTAINER_INTERACTIVE=
if [[ -t 0 ]]; then
  CONTAINER_INTERACTIVE="-it"
fi

setup_env "${HOME}/.gitconfig"
CONTAINER_ARGS=$(get_args)

${CONTAINER_RUNNER} run --rm -h tiiuae-build \
  ${CONTAINER_INTERACTIVE} \
  -v ${WORKSPACE_DIR}:/workspace:z \
  ${CONTAINER_ARGS} \
  tiiuae/build:latest ${CONTAINER_CMD}
