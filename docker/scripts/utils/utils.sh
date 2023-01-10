#!/bin/bash
#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Crude logging functions
log_stdout()
{
  printf "%s: %s\n" "$0" "$*" >&1;
}

log_stderr()
{
  printf "%s: %s\n" "$0" "$*" >&2;
}

die()
{ 
  log_stderr "${FUNCNAME[1]}: $*"; exit 1
}

command_exists() 
{
	command -v "$@" > /dev/null 2>&1
}

get_uid()
{
  id -u 2>/dev/null
}

check_argc_lt()
{
  if test "$#" -lt 2; then
    die "Not enough arguments ($# < 2)!"
  fi

  if test "$1" -lt "$2"; then
    die "${FUNCNAME[1]}: Not enough arguments ($1 < $2)!"
  fi
}

check_argc_gt()
{
  if test "$#" -lt 2; then
    die "Not enough arguments ($# < 2)!"
  fi

  if test "$1" -gt "$2"; then
    die "${FUNCNAME[1]}: Too many arguments ($1 > $2)!"
  fi
}

check_argc_eq()
{
  if test "$#" -lt 2; then
    die "Not enough arguments ($# < 2)!"
  fi

  if test "$1" -ne "$2"; then
    die "${FUNCNAME[1]}: Invalid # of arguments ($1 != $2)!"
  fi
}

get_var()
{
  check_argc_lt "$#" 2

  declare -n ref="$1"
  shift
  printf -v ref "%s" "$@"
}

get_var_fail()
{
  check_argc_lt "$#" 3

  declare -n ref="$1"
  printf -v ref "%s" "$2"

  if test -z "${ref}"; then
    shift 2
    die "$@"
  fi
}

var_set()
{
  check_argc_lt "$#" 1
  test -v "$@"
}

var_set_fail()
{
  check_argc_lt "$#" 2

  if test -v "$1"; then
   shift
   die "$@"
  fi
}

file_exists()
{
  check_argc_lt "$#" 2

  if ! test -f "$1"; then
   shift
   die "$@"
  fi
}

get_var_q()
{
  check_argc_lt "$#" 2

  declare -n ref=$1
  shift
  printf -v ref "%q" "$@"
}

var_set_q()
{
  check_argc_lt "$#" 1

  local var=
  printf -v var "%q" "$@"
  test -v "${var}"
}

var_set_q_fail()
{
  check_argc_lt "$#" 2

  if var_set_q "$1"; then
   shift
   die "$@"
  fi
}

get_timestamp()
{
  date +%F.%H%M%S
}

get_git_stamp()
{
  if git rev-parse > /dev/null 2>&1; then
    git rev-parse --short HEAD
  else
    #echo "0000000"
    echo ""
  fi
}

arr_contains()
{
  case "$#" in

    0)
    die "Invalid # of arguments ($#)!"
    ;;

    1)
    # Array cannot contain value if it doesn't
    # exist in the first place.
    return 1
    ;;

    *)
    get_var_fail value "$1" "Invalid search value!"
    shift
    local arr=("$@")
    printf '%s\0' "${arr[@]}" | grep -Fxqz -- "${value}"
    ;;
  esac
}


call_trace()
{
    local rc=0
    set -x
    "$@"
    rc=$? 
    { set +x; } 2>/dev/null 
    return $rc;
}

run_as_root() 
{
    # A function inspired from get.docker.com and https://stackoverflow.com/a/32280085
    # Designed to pick the best way to run a command as root

    local CMD=( "$@" )
    printf -v CMD_STR "%q " "${CMD[@]}"

    if [[ "$(get_uid)" -ne 0 ]]; then
        if command_exists sudo; then
          call_trace sudo -E bash -c "$CMD_STR"
        elif command_exists su; then
          call_trace su -c "$CMD_STR"
        else
          die "Cannot find a method to run commands as root!"
        fi
    else
      call_trace bash -c "$CMD_STR"
    fi
}

chown_dir()
{
  check_argc_lt "$#" 3
  run_as_root chown -R "$1":"$2" "$3"
}

chown_file()
{
  check_argc_lt "$#" 3
  run_as_root chown "$1":"$2" "$3"
}

is_docker_podman() 
{
  docker --help 2>&1 | grep podman > /dev/null 2>&1
}

get_container_engine()
{
  is_docker_podman
  [[ $? -eq 0 ]] && echo "podman" || echo "docker"
}

