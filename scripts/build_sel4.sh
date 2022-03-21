#!/bin/sh

set -e


REQUIRED_ENV_VARS="CROSS_COMPILE ARCH WORKSPACE_PATH ENV_ROOTDIR BUILDDIR SRCDIR PLATFORM NUM_NODES CAMKES_VM_APP"


# Crude logging functions
log_stdout()
{
  printf "%s: %b" "$0" "$1" >&1;
}
log_stderr()
{
  printf "%s: %b" "$0" "$1" >&2;
}


# Setup handler to remove the DOCKER_ENVFILE
# always regardless of whether we exit normally
# or through an error.
#
cleanup()
{
  exit_status=$?
  log_stderr "Cleaning up on exit...\n"
  [ -f "${DOCKER_ENVFILE}" ] && rm "${DOCKER_ENVFILE}"
  exit "$exit_status"
}
trap cleanup 0 1 2 3 6 14 15


# Init helper functions, variables etc.
#
check_env_vars()
{
  for VAR in ${REQUIRED_ENV_VARS}; do
    printenv "${VAR}" 1>/dev/null
    if [ $? -ne 0 ]; then
      log_stderr "ERROR: Required environment variable \"${VAR}\" is not defined!\n"
      exit 1
    fi
  done
}

generate_env_file()
{
  DOCKER_ENVFILE="$(realpath $(mktemp --suffix=.list env-XXXXXXXX))"
  chmod 644 "${DOCKER_ENVFILE}"

  for VAR in ${REQUIRED_ENV_VARS}; do
    VALUE=$(printenv "${VAR}")
    printf "%s=%s\n" "${VAR}" "${VALUE}" >> "${DOCKER_ENVFILE}"
  done
}


SCRIPT_ABSPATH="$(realpath "$0")"
SCRIPT_DIR_ABSPATH="$(dirname "${SCRIPT_ABSPATH}")"
SCRIPT_CWD="$(pwd)"
SCRIPT_RELPATH="${SCRIPT_ABSPATH#${SCRIPT_CWD}}"

# Now be mad if all the required
# variables are not set
check_env_vars


# Enter the build container if necessary
#
if head -n 1 < /proc/1/sched | grep -q 'init\|systemd'; then

  log_stdout "Entering build container...\n"

  # Update ENV_ROOTDIR in case it is needed later
  # in container. Assume that in container it 
  # will be the same as WORKSPACE_PATH.
  # TODO: can this be hardcoded/assumed such?
  #
  DOCKER_DIR_ABSPATH="$(realpath "${ENV_ROOTDIR}/docker")"
  ENV_ROOTDIR="${WORKSPACE_PATH}"

  # Pass environment variables to Docker.
  # Add DOCKER_ENVFILE to list, as the
  # exec will cause us to lose our local variable.
  #
  generate_env_file
  printf "%s=%s\n" "DOCKER_ENVFILE" "${WORKSPACE_PATH}/$(basename "${DOCKER_ENVFILE}")" >> "${DOCKER_ENVFILE}"

  exec "${DOCKER_DIR_ABSPATH}/enter_container.sh" --envfile "${DOCKER_ENVFILE}" --image sel4_builder --workspacedir "${SCRIPT_CWD}" "${WORKSPACE_PATH}/${SCRIPT_RELPATH}" $@
else
  log_stdout "Running in build container, continuing...\n"
fi


# Configure file paths and misc stuff
# for the commands to use
#
BUILDDIR_ABSPATH="$(realpath "${WORKSPACE_PATH}/${BUILDDIR}")"
SRCDIR_ABSPATH="$(realpath "${WORKSPACE_PATH}/${SRCDIR}")"


# Setup build directory
#
rm -rf "${BUILDDIR_ABSPATH}"
mkdir -p "${BUILDDIR_ABSPATH}"
ln -s "${WORKSPACE_PATH}/tools/seL4/cmake-tool/init-build.sh" "${BUILDDIR_ABSPATH}/init-build.sh"
ln -s "${SRCDIR_ABSPATH}/easy-settings.cmake" "${BUILDDIR_ABSPATH}/easy-settings.cmake"


# Build
#
cd "${BUILDDIR_ABSPATH}"
./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" -DNUM_NODES="${NUM_NODES}" -DCAMKES_VM_APP="${CAMKES_VM_APP}" $@
ninja

# Generate U-Boot script
ARHC="${ARCH}" "${SCRIPT_DIR_ABSPATH}/generate_uboot_bootscript.sh" -b . -t images -s elfloader/elfloader

echo "--------------------------------------------------------"
echo "--------------------------------------------------------"
echo "--------------------------------------------------------"
echo "                                                        "
echo "Here are your binaries in "${BUILDDIR_ABSPATH}/images": "
echo "                                                        "
ls -la ./images
