#!/bin/sh

set -e

IMAGE=""
DIR=""
ARGS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i)
      IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
    -d)
      DIR="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      ARGS+=" $1" # save positional args
      shift # past argument
      ;;
  esac
done

# Validate input arguments.
# Image name is required,
# for workspace directory
# default to current working
# directory if nothing is given.
#
case "$IMAGE" in
  sel4|yocto|buildroot|uboot|kernel)
  ;;
  *)
    printf "ERROR: Image name required (sel4|yocto|buildroot|uboot|kernel)!\n" >&2;
    exit 1
  ;;
esac

if test -z "$DIR"; then
  DIR="$(pwd)"
fi

set -- "$ARGS"

exec \
  docker build \
  -t tiiuae/"${IMAGE}"_build:latest \
  -f "${DIR}"/docker/"${IMAGE}".Dockerfile \
  "${DIR}"/docker \
  "$@"
