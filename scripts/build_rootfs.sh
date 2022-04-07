#!/bin/sh

set -eE

REQUIRED_ENV_VARS="ARCH BR_CONFIG BR_BUILDDIR BR_SDK_CONFIG BR_SRCDIR CROSS_COMPILE DEST_IMGDIR ENV_ROOTDIR WORKSPACE_PATH"


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

  exec env DOCKER_IMAGE=tii_builder \
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
BR_BUILDDIR_ABSPATH="$(realpath "${BR_BUILDDIR}")"
BR_SRCDIR_ABSPATH="$(realpath "${BR_SRCDIR}")"
DEST_IMGDIR_ABSPATH="$(realpath "${DEST_IMGDIR}")"


# The -p argument ensures no
# error if the directory exists
# already, and it creates parent
# directories if needed. It is
# safe to call it here in any case,
# to avoid any hairy/repetitive 
# logic further down.
#
mkdir -p "${BR_BUILDDIR_ABSPATH}"

BR_CONFIG_SRC_ABSPATH="$(realpath "${BR_CONFIG}")"
BR_CONFIG_BASENAME="$(basename "${BR_CONFIG_SRC_ABSPATH}")"
BR_CONFIG_DEST_ABSPATH="$(realpath "${BR_BUILDDIR_ABSPATH}/${BR_CONFIG_BASENAME}")"
#SDK_CONFIG_FILE_SRC_ABSPATH="$(realpath "${BUILDROOT_SDK_CONFIG}")"
#SDK_CONFIG_FILE_DEST_ABSPATH="$(realpath "${BR_BUILDDIR_ABSPATH}")/$(basename "${SDK_CONFIG_FILE_SRC_ABSPATH}")"


call_make()
{
  make O="${BR_BUILDDIR_ABSPATH}" "$@"
}

install_defconfig_to_builddir()
{
  cp -v "${BR_CONFIG_SRC_ABSPATH}" "${BR_CONFIG_DEST_ABSPATH}"
}

save_defconfig_from_builddir()
{
  cp -v "${BR_CONFIG_DEST_ABSPATH}" "${BR_CONFIG_SRC_ABSPATH}"
}

check_install_defconfig()
{
  if ! test -f "${BR_CONFIG_DEST_ABSPATH}"; then
    install_defconfig_to_builddir
    call_make BR2_DEFCONFIG="${BR_CONFIG_DEST_ABSPATH}" defconfig
  fi
}

do_install_defconfig()
{
  install_defconfig_to_builddir
  call_make BR2_DEFCONFIG="${BR_CONFIG_DEST_ABSPATH}" defconfig
}

do_build()
{
  if test -d "${BR_BUILDDIR_ABSPATH}" && 
     test -n "$(ls -A "${BR_BUILDDIR_ABSPATH}/images" 2>/dev/null)"; then

     log_stdout "Build directory contains built target(s).\n"
     
     while true; do

       read -t10 -p "Do you want to clean build directory before continuing? (Y)es/(N)o/(C)ancel? " USER_RESP

       if [ $? -gt 128 ]; then
         log_stdout "Timeout while waiting for input, defaulting to \"(Y)es\"\n"
         USER_RESP="Y"
       fi

       case "${USER_RESP}" in
         [Yy]*)
           log_stdout "Cleaning build directory before rebuild...\n"
           call_make clean; 
           break
           ;;
         [Nn]*) 
           break
           ;;
         [Cc]*) 
           exit
           ;;
         *) 
           log_stdout "Please answer (Y)es/(N)o/(C)ancel.\n"
           ;;
       esac
     done
  fi

  JOBS=$(($(nproc)/2))
  call_make -j"${JOBS}" "$@"
}

do_install_imgdir()
{
  cp -v "${BR_CONFIG_DEST_ABSPATH}" "${BR_CONFIG_SRC_ABSPATH}"
  cp -v "${BR_BUILDDIR_ABSPATH}/images/rootfs.cpio.gz" "${DEST_IMGDIR_ABSPATH}/rootfs.cpio.gz"
  rsync -avP --delete "${BR_BUILDDIR_ABSPATH}/images/" "${DEST_IMGDIR_ABSPATH}/buildroot-images"
}

do_install()
{
  if test -d "${BR_BUILDDIR_ABSPATH}" && 
     test -n "$(ls -A "${BR_BUILDDIR_ABSPATH}/images" 2>/dev/null)"; then
    do_install_imgdir
  else
    log_stderr "ERROR: install: Build directory doesn't exist, or it is empty. Please build target(s) first before install.\n"
  fi
}

do_install_save_defconfig()
{
  if test -d "${BR_BUILDDIR_ABSPATH}" && 
     test -n "$(ls -A "${BR_BUILDDIR_ABSPATH}/images" 2>/dev/null)"; then
    call_make savedefconfig
    save_defconfig_from_builddir
    do_install_imgdir
  else
    log_stderr "ERROR: install: Build directory doesn't exist, or it is empty. Please build target(s) first before install.\n"
  fi
}


# Handle script commands
#
cd "${BR_SRCDIR_ABSPATH}"
check_install_defconfig
export ARCH="${ARCH}"
#export CROSS_COMPILE="${CROSS_COMPILE}"

case "${SCRIPT_COMMAND}" in
  all)
    do_build all
    do_install
    ;;
  build)
    do_build all
    ;;
  clean)
    call_make clean
    ;;
  dirclean)
    call_make dirclean
    ;;
  distclean)
    call_make distclean
    ;;
  install)
    do_install
    ;;
  menuconfig)
    call_make menuconfig
    ;;
  olddefconfig)
    do_install_defconfig
    ;;
  savedefconfig)
    call_make savedefconfig
    save_defconfig_from_builddir
    ;;
  shell)
    exec env \
        ARCH="${ARCH}" \
        BR_BUILDDIR="${BR_BUILDDIR_ABSPATH}" \
        BR_CONFIG="${BR_CONFIG_SRC_ABSPATH}" \
        BR_CONFIG_BASENAME="${BR_CONFIG_BASENAME}" \
        BR_CONFIG_DEST_ABSPATH="${BR_CONFIG_DEST_ABSPATH}" \
        BR_SRCDIR="${BR_SRCDIR_ABSPATH}" \
        CROSS_COMPILE="${CROSS_COMPILE}" \
        DEST_IMGDIR="${DEST_IMGDIR_ABSPATH}" \
        O="${BR_BUILDDIR_ABSPATH}" \
        /bin/bash
    ;;
  *)
    exec env \
        ARCH="${ARCH}" \
        BR_BUILDDIR="${BR_BUILDDIR_ABSPATH}" \
        BR_CONFIG="${BR_CONFIG_SRC_ABSPATH}" \
        BR_CONFIG_BASENAME="${BR_CONFIG_BASENAME}" \
        BR_CONFIG_DEST_ABSPATH="${BR_CONFIG_DEST_ABSPATH}" \
        BR_SRCDIR="${BR_SRCDIR_ABSPATH}" \
        CROSS_COMPILE="${CROSS_COMPILE}" \
        DEST_IMGDIR="${DEST_IMGDIR_ABSPATH}" \
        O="${BR_BUILDDIR_ABSPATH}" \
        /bin/bash -c "${SCRIPT_COMMAND} $@"
    ;;
esac
