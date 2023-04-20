#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

use_sudo=""
if [ "$INPUT_USE_SUDO" == "true" ]; then
  use_sudo=sudo
fi

$use_sudo apt-get update -y
$use_sudo apt-get install -y \
  repo \
  git \
  xmlstarlet
