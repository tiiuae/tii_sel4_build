#!/usr/bin/env bash

set -e
#set -x

# Find utility functions
SCRIPT_DIR="$(realpath $0)"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
. "${SCRIPT_DIR}"/utils.sh

# Check env variables
[[ -z "${WORKSPACE_ROOT}" ]] && die "Invalid workspace root directory!"
[[ -z "${PROJECT}" ]] && die "Invalid project name!"

# Project directory is optional, set default if not passed
[[ -z "${PROJECT_DIR}" ]] && PROJECT_DIR="${WORKSPACE_ROOT}/projects/${PROJECT}"

WORKSPACE_ROOT="$(realpath "${WORKSPACE_ROOT}")"
PROJECT_DIR="$(realpath "${PROJECT_DIR}")"

# Source the config file
# shellcheck disable=SC1091
. "${WORKSPACE_ROOT}/.config"

# Set suffix to the project name
BUILD_DIR="${WORKSPACE_ROOT}/build_${PLATFORM}_${PROJECT}"
[[ -z "${BUILD_SYMLINK}" ]] && BUILD_SYMLINK="${WORKSPACE_ROOT}/build"

# Remove old build dir and link
#rm -rf "${BUILD_DIR}" "${BUILD_SYMLINK}"

# Create new build dir and link to it
mkdir -p "${BUILD_DIR}"
ln -rs "${BUILD_DIR}" "${BUILD_SYMLINK}"

# Link settings and build init script to the build dir
ln -rs "${WORKSPACE_ROOT}/tools/seL4/cmake-tool/init-build.sh" "${BUILD_DIR}"
ln -rs "${PROJECT_DIR}/easy-settings.cmake" "${BUILD_DIR}"

# Go to the build directory and start building
cd "${BUILD_DIR}"

# shellcheck disable=SC2068
#./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" $@
./init-build.sh -B . -DPLATFORM="${PLATFORM}" -DRELEASE=FALSE -DSIMULATION=TRUE
ninja

printf "\nHere are your binaries in ${BUILD_DIR}: \n"
ls -lA --color=auto "${BUILD_DIR}"/
