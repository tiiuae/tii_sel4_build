#!/bin/sh

set -e

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "${SCRIPT_DIR}//utils.sh"

# Complain if we don't have enough args
min_args 1 "$@"

IMAGE=""
WORKSPACEDIR=""
DOCKER_ARGS=""

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
      # Treat everything else as args to Docker
      DOCKER_ARGS="$DOCKER_ARGS $ARG "
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

exec \
  docker build \
  -t tiiuae/${IMAGE}_build:latest \
  -f ${WORKSPACEDIR}/docker/${IMAGE}.Dockerfile \
  ${WORKSPACEDIR}/docker \
  ${DOCKER_ARGS}
