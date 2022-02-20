#!/bin/sh

set -e

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "${SCRIPT_DIR}/../scripts/utils.sh"

# Complain if we don't have enough args
min_args 1 "$@"

IMAGE=""
WORKSPACEDIR=""
OTHER_ARGS=""

SKIP=false
# Parse arguments
for ARG in "$@"; do
  if $SKIP; then
    SKIP=false && continue
  fi
  case "$ARG" in
    -i)
      shift
      if test -n "$IMAGE"; then
        die "ERROR: Multiple definitions for parameter IMAGE (-i)!"
      else
        IMAGE="$1"
      fi
      SKIP=true
      ;;
    -w)
      shift
      if test -n "$WORKSPACEDIR"; then
        die "ERROR: Multiple definitions for parameter WORKSPACEDIR (-w)!"
      else
        WORKSPACEDIR="$1"
      fi
      SKIP=true
      ;;
    *)
      # Treat everything else as other args
      OTHER_ARGS="$OTHER_ARGS $ARG "
      ;;
  esac
  shift
done

# Validate input arguments.
# Image name is required,
# for workspace directory
# default to current directory
# if nothing was passed.
#
if test -z "$IMAGE"; then
	die "ERROR: Parameter IMAGE (-i) is required!"
fi

if test -z "$WORKSPACEDIR"; then
	WORKSPACEDIR=$(pwd)
fi

set -- "$OTHER_ARGS"

exec \
  docker run \
  --rm -it \
  -v ${WORKSPACEDIR}:/workspace:z \
  -v ${HOME}/.ssh:/home/build/.ssh:z \
  -v ${HOME}/.gitconfig:/home/build/.gitconfig:z \
  --add-host host.docker.internal:host-gateway \
  -h ${IMAGE}_build \
  tiiuae/${IMAGE}_build:latest \
  $@
