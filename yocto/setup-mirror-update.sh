# assume we're in the same dir as layers
if [ -n "$BASH_SOURCE" ]; then
  SCRIPT=$BASH_SOURCE
else
  SCRIPT=$0
fi

SCRIPT_DIR="$(realpath -e "$(dirname "$SCRIPT")")"

export DL_DIR=${YOCTO_SOURCE_MIRROR_DIR:-${HOME}/yocto-mirror}
export BB_GENERATE_MIRROR_TARBALLS="1"
export SOURCE_MIRROR_FETCH="1"

export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_PASSTHROUGH_ADDITIONS DL_DIR BB_GENERATE_MIRROR_TARBALLS SOURCE_MIRROR_FETCH"

. "${SCRIPT_DIR}/setup.sh" "$@"
