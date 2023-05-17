#! /bin/sh

DIR=$1
if [ -z "${DIR}" ]; then
  DIR=$(pwd)
else
  shift
fi

CMD=$*
if [ -z "${CMD}" ]; then
  CMD="/bin/bash"
fi

# Support for non-terminal runs
INTERACTIVE=
if [ -t 0 ]; then
  INTERACTIVE="-it"
fi

# Resolve runtime specific options
CONTAINER_ENGINE=${CONTAINER_ENGINE:-"docker"}
if [ "${CONTAINER_ENGINE}" = "podman" ]; then
  CONTAINER_ENGINE_OPTS="--userns keep-id --pids-limit -1"
  CONTAINER_REGISTRY_PREFIX="localhost/"
else
  CONTAINER_ENGINE_OPTS="--add-host host.docker.internal:host-gateway"
fi

CONTAINER_ENV_FLAGS=
if [ -n "${DOCKER_EXPORT}" ]; then
  CONTAINER_ENV_FLAGS=$(echo "${DOCKER_EXPORT}" | xargs -d ' ' -Ivar -- echo --env var)
fi

# shellcheck disable=SC2086
exec ${CONTAINER_ENGINE} run --rm ${INTERACTIVE} \
  ${CONTAINER_ENV_FLAGS} \
  -v "${DIR}:/workspace:z" \
  ${YOCTO_SOURCE_MIRROR_DIR:+--env YOCTO_SOURCE_MIRROR_DIR=/workspace/downloads} \
  ${YOCTO_SOURCE_MIRROR_DIR:+-v "${YOCTO_SOURCE_MIRROR_DIR}":/workspace/downloads:z} \
  -v "${HOME}/.ssh:/home/build/.ssh:z" \
  -v "${HOME}/.gitconfig:/home/build/.gitconfig:z" \
  ${CONTAINER_ENGINE_OPTS} \
  "${CONTAINER_REGISTRY_PREFIX}tiiuae/build:latest" ${CMD}
