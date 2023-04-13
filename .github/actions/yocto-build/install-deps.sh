#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

use_sudo=""
if [ "$INPUT_USE_SUDO" == "true" ]; then
  use_sudo=sudo
fi

$use_sudo apt-get update -y
$use_sudo apt-get install -y \
  gawk \
  wget \
  git \
  diffstat \
  unzip \
  texinfo \
  gcc \
  build-essential \
  chrpath \
  socat \
  cpio \
  python3 \
  python3-pip \
  python3-pexpect \
  xz-utils \
  debianutils \
  iputils-ping \
  python3-git \
  python3-jinja2 \
  libegl1-mesa \
  libsdl1.2-dev \
  pylint \
  xterm \
  python3-subunit \
  mesa-common-dev \
  zstd \
  liblz4-tool

