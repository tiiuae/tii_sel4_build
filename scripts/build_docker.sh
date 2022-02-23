#!/bin/sh

set -e

IMAGE="$1"
shift
WORKSPACEDIR="$1"
shift

# Validate input arguments.
# Image name is required,
# for workspace directory
# default to current working
# directory.
#
case "$IMAGE" in
  sel4|yocto|buildroot|uboot|kernel)
  ;;
  *)
    printf "ERROR: Image name required (sel4|yocto|buildroot|uboot|kernel)!" >&2;
    exit 1
  ;;
esac

if test -z "$WORKSPACEDIR"; then
	WORKSPACEDIR=$(pwd)
fi

exec \
  docker build \
  -t tiiuae/${IMAGE}_build:latest \
  -f ${WORKSPACEDIR}/docker/${IMAGE}.Dockerfile \
  ${WORKSPACEDIR}/docker \
  $@
