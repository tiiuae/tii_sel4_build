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

exec docker run --rm ${INTERACTIVE} \
  `echo ${DOCKER_EXPORT} | xargs -d ' ' -Ivar -- echo --env var` \
  -v ${DIR}:/workspace:z \
  ${YOCTO_SOURCE_MIRROR_DIR:+--env YOCTO_SOURCE_MIRROR_DIR=/workspace/downloads} \
  ${YOCTO_SOURCE_MIRROR_DIR:+-v "${YOCTO_SOURCE_MIRROR_DIR}":/workspace/downloads:z} \
  -v ${HOME}/.ssh:/home/build/.ssh:z \
  -v ${HOME}/.gitconfig:/home/build/.gitconfig:z \
  --add-host host.docker.internal:host-gateway \
  tiiuae/build:latest ${CMD}
