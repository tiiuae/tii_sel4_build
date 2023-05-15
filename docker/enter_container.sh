#! /bin/sh

DIR=$1
if test "x${DIR}" = "x"; then
  DIR=`pwd`
else
  shift
fi

CMD=$@
if test "x${CMD}" = "x"; then
  CMD="/bin/bash"
fi

# Support for non-terminal runs
INTERACTIVE=
if test -t 0; then
  INTERACTIVE="-it"
fi

CONTAINER_ENGINE=${CONTAINER_ENGINE:-"docker"}
if test "${CONTAINER_ENGINE}" = "podman"; then
  CONTAINER_ENGINE_OPTS="--userns keep-id --pids-limit -1"
  CONTAINER_REGISTRY_PREFIX="localhost/"
else
  CONTAINER_ENGINE_OPTS="--add-host host.docker.internal:host-gateway"
fi

exec ${CONTAINER_ENGINE} run --rm ${INTERACTIVE} \
  `echo ${DOCKER_EXPORT} | xargs -d ' ' -Ivar -- echo --env var` \
  -v ${DIR}:/workspace:z \
  ${YOCTO_SOURCE_MIRROR_DIR:+--env YOCTO_SOURCE_MIRROR_DIR=/workspace/downloads} \
  ${YOCTO_SOURCE_MIRROR_DIR:+-v "${YOCTO_SOURCE_MIRROR_DIR}":/workspace/downloads:z} \
  -v ${HOME}/.ssh:/home/build/.ssh:z \
  -v ${HOME}/.gitconfig:/home/build/.gitconfig:z \
  ${CONTAINER_ENGINE_OPTS} \
  ${CONTAINER_REGISTRY_PREFIX}tiiuae/build:latest ${CMD}
