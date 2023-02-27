SCRIPT_NAME=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT_NAME}`
SCRIPT_BASENAME=`basename ${SCRIPT_NAME}`

# Detect whether should enter container:
#   docker     -> '/.dockerenv' file exists
#   lxc/podman -> 'container' variable is set to runtime name.
#
# With 'container' variable we support native builds too:
# export container="skip", or similar, before calling make, and entering
# container is skipped.
if [ -z "${container}" ] && [ ! -f /.dockerenv ]; then
  # shellcheck disable=SC2068
  exec docker/enter_container.sh "$(pwd)" scripts/${SCRIPT_BASENAME} $@
fi

# shellcheck disable=SC1091
. `pwd`/.config

CMAKE_FLAGS=`sed -e 's/#.*$//g' < .config | xargs -Iconfig -- echo -Dconfig | xargs`
