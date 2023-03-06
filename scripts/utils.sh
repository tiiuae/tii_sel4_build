#!/usr/bin/env bash

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

docker_is_podman() 
{
  docker --help 2>&1 | grep -q podman
}

get_container_engine()
{
  docker_is_podman
  [[ $? -eq 0 ]] && echo "podman" || echo "docker"
}

get_platform()
{
  awk '{ sub(/PLATFORM=/, ""); print }' "$1"
}

get_cc_prefix()
{
  awk '{ sub(/CROSS_COMPILER_PREFIX=/, ""); print }' "$1"
}

get_num_nodes()
{
  awk '{ sub(/NUM_NODES=/, ""); print }' "$1"
}
