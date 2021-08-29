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

exec docker run --rm -it -v ${DIR}:/workspace:z tiiuae/build:latest ${CMD}
