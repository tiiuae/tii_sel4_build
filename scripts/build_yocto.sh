#!/bin/bash
set -e

# Detect whether should enter container:
#   docker     -> '/.dockerenv' file exists
#   lxc/podman -> 'container' variable is set to runtime name.
#
# With 'container' variable we support native builds too:
# export container="skip", or similar, before calling make, and entering
# container is skipped.
if [ -z "${container}" ] && [ ! -f /.dockerenv ]; then
  # shellcheck disable=SC2068
  exec docker/enter_container.sh "$(pwd)" scripts/build_yocto.sh $@
fi

cd vm-images
. setup.sh
bitbake vm-image-driver