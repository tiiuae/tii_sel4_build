#!/bin/sh

set -eE

REQUIRED_ENV_VARS="ARCH CROSS_COMPILE DEST_IMGDIR ENV_ROOTDIR LINUX_BUILDDIR MODULE_MAKEFILE MODULE_SRCDIR WORKSPACE_PATH"

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
SCRIPT_CWD="$(pwd)"
SCRIPT_RELPATH="${SCRIPT_ABSPATH#"${SCRIPT_CWD}"}"


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

  exec env DOCKER_IMAGE=linux \
       env WORKSPACE_DIR="${SCRIPT_CWD}" \
       env DOCKER_ENVFILE="${DOCKER_ENVFILE}" \
       "${DOCKER_DIR_ABSPATH}/enter_container.sh" "${WORKSPACE_PATH}/${SCRIPT_RELPATH}" $@
else
  log_stdout "Running in build container, continuing...\n"
fi


# Figure out what caller wants us to do.
#
# First possible source is the first
# script parameter, the second is an
# environment variable COMMAND.
# Default to "all" if nothing is given.
#
SCRIPT_COMMAND=""

if test -n "$1"; then
  SCRIPT_COMMAND="$1"
  shift
elif test -n "${COMMAND}"; then
  SCRIPT_COMMAND="${COMMAND}"
else
  log_stdout "No command given, defaulting to \"all\"!\n"
  SCRIPT_COMMAND=all
fi



# Configure file paths and misc stuff
# for the commands to use
#
LINUX_BUILDDIR_ABSPATH="$(realpath "${LINUX_BUILDDIR}")"
MODULE_SRCDIR_ABSPATH="$(realpath "${MODULE_SRCDIR}")"
DEST_IMGDIR_ABSPATH="$(realpath "${DEST_IMGDIR}")"
MODULE_MAKEFILE_ABSPATH="$(realpath "${MODULE_MAKEFILE}")"


call_make()
{
  make KERNEL_SRC="${LINUX_BUILDDIR_ABSPATH}" "$@"
}

do_install_makefile()
{
  cp -v "${MODULE_MAKEFILE_ABSPATH}" "${MODULE_SRCDIR_ABSPATH}/Makefile"
}

check_install_makefile()
{
  if ! test -f "${MODULE_SRCDIR_ABSPATH}/Makefile"; then
    do_install_makefile
  fi
}

do_clean()
{
  pushd "${MODULE_SRCDIR_ABSPATH}"
  call_make clean
  popd
}

do_build()
{
  pushd "${MODULE_SRCDIR_ABSPATH}"
  #if test -n "$(ls -A "${MODULE_SRCDIR_ABSPATH}/*.ko" 2>/dev/null)"
  if test -f "./connection.ko"; then
     call_make clean
  fi

  call_make modules
  popd
}

do_install()
{
  pushd "${MODULE_SRCDIR_ABSPATH}"
  call_make INSTALL_MOD_PATH="${DEST_IMGDIR_ABSPATH}/linux-modules/" modules_install
  popd
}


# Handle script commands
#
do_install_makefile
export ARCH="${ARCH}"
export CROSS_COMPILE="${CROSS_COMPILE}"


case "${SCRIPT_COMMAND}" in
  all)
    do_build
    do_install
    ;;
  build)
    do_build
    ;;
  clean)
    do_clean
    ;;
  install)
    do_install
    ;;
  shell)
    exec env \
        ARCH="${ARCH}" \
        CROSS_COMPILE="${CROSS_COMPILE}" \
        DEST_IMGDIR="${DEST_IMGDIR_ABSPATH}" \
        LINUX_BUILDDIR="${LINUX_BUILDDIR_ABSPATH}" \
        MODULE_MAKEFILE="${MODULE_MAKEFILE_ABSPATH}" \
        MODULE_SRCDIR="${MODULE_SRCDIR_ABSPATH}" \
        /bin/bash
    ;;
  *)
    exec env \
        ARCH="${ARCH}" \
        CROSS_COMPILE="${CROSS_COMPILE}" \
        DEST_IMGDIR="${DEST_IMGDIR_ABSPATH}" \
        LINUX_BUILDDIR="${LINUX_BUILDDIR_ABSPATH}" \
        MODULE_MAKEFILE="${MODULE_MAKEFILE_ABSPATH}" \
        MODULE_SRCDIR="${MODULE_SRCDIR_ABSPATH}" \
        /bin/bash -c "${SCRIPT_COMMAND} $@"
    ;;
esac
