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
  -w "${DIR}" \
  -v "${DIR}:${DIR}:z" \
  ${YOCTO_SOURCE_MIRROR_DIR:+--env YOCTO_SOURCE_MIRROR_DIR="${DIR}"/downloads} \
  ${YOCTO_SOURCE_MIRROR_DIR:+-v "${YOCTO_SOURCE_MIRROR_DIR}":"${DIR}"/downloads:z} \
  ${BUILD_CACHE_DIR:+--env BUILD_CACHE_DIR="${HOME}"/.stack} \
  ${BUILD_CACHE_DIR:+-v "${BUILD_CACHE_DIR}"/stack:"${HOME}"/.stack:z} \
  -v "${HOME}/.ssh:${HOME}/.ssh:z" \
  -v "${HOME}/.gitconfig:${HOME}/.gitconfig:z" \
  ${CONTAINER_ENGINE_OPTS} \
  "${CONTAINER_REGISTRY_PREFIX}tiiuae/build:latest" ${CMD}
