#! /bin/sh

WORKDIR=$1
if test "x${WORKDIR}" = "x"; then
  WORKDIR=`pwd`
else
  shift
fi

DOCKERIMG=$2
if test "x${DOCKERIMG}" = "x"; then
  echo "Please specify the Docker image to run!"
  exit 1
else
  shift
fi

CMD=$@
if test "x${CMD}" = "x"; then
  CMD="/bin/bash"
fi

exec docker run --rm -it \
  -v ${WORKDIR}:/workspace:z \
  -v ${HOME}/.ssh:/home/build/.ssh:z \
  -v ${HOME}/.gitconfig:/home/build/.gitconfig:z \
  --add-host host.docker.internal:host-gateway \
  tiiuae/${DOCKERIMG}:latest ${CMD}
