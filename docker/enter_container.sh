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
  `echo ${DOCKER_EXPORT} | xargs -Ivar -- echo --env var` \
  -v ${DIR}:/workspace:z \
  -v ${HOME}/.ssh:/home/build/.ssh:z \
  -v ${HOME}/.gitconfig:/home/build/.gitconfig:z \
  --add-host host.docker.internal:host-gateway \
  tiiuae/build:latest ${CMD}
