#!/usr/bin/env bash

set -ex

# Find utility functions
SCRIPT_DIR="$(realpath $0)"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
. "${SCRIPT_DIR}"/utils.sh

# Check number of args, if there are 4 we probably
# aren't in container yet. Try to handle it.
# Otherwise continue building.
if [[ "$#" -eq 4 ]] \
|| [[ "$#" -gt 4 ]]; then

  # With 'container' variable we support native builds too:
  # export container="skip", or similar, before calling make, 
  # and entering container is skipped.
  if [[ -z "${container}" ]] \
  && [[ -z "${IN_CONTAINER}" ]]; then
    # shellcheck disable=SC2068
    exec docker/enter_container.sh "$1" "$2" "$3" "scripts/build_sel4.sh" "/workspace" "$4"
  fi
fi

#build_sel4dynamic: $(CONFIG_FILE)
#	@scripts/build_sel4dynamic.sh \
#	$(WORKSPACE_ROOT) \
#	$(CENGINE) \
#	$(IMAGE):$(IMAGE_TAG) \
#	projects/sel4_dynamic_loader


[[ "$#" -ne 2 ]] && die "Invalid # of arguments!" 

WORKSPACE_ROOT="$(realpath $1)"
[[ -z "${WORKSPACE_ROOT}" ]] && die "Invalid workspace root directory!"

SRCDIR="$(realpath $2)"
[[ -z "${SRCDIR}" ]] && die "Invalid source directory!"

# Set suffix to the basename of the source directory.
BUILDDIR_SUFFIX="${SRCDIR##*/}"

# Get config
# shellcheck disable=SC1091
. "${WORKSPACE_ROOT}/.config"

BUILDDIR="${WORKSPACE_ROOT}/build_${PLATFORM}_${BUILDDIR_SUFFIX}"
[[ -z "${BUILDDIR}" ]] && die "Invalid build directory!"

if [[ -e "${BUILDDIR}" ]] \
&& [[ -d "${BUILDDIR}" ]]; then
  rm -rf "${BUILDDIR}"
fi

mkdir -p "${BUILDDIR}"

ln -rs "${WORKSPACE_ROOT}/tools/seL4/cmake-tool/init-build.sh" "${BUILDDIR}"
ln -rs "${SRCDIR}/easy-settings.cmake" "${BUILDDIR}"

pushd .
cd "${BUILDDIR}" || die "Failed to enter build directory!"

# shellcheck disable=SC2068
#./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" $@
./init-build.sh -B . -DPLATFORM="${PLATFORM}" -DRELEASE=FALSE -DSIMULATION=TRUE
ninja
popd

echo "Here are your binaries in ${BUILDDIR}: "
ls -lA "${BUILDDIR}"/