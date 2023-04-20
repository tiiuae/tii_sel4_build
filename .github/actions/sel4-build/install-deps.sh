#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

pip_opts="--user"
use_sudo=""
if [ "$INPUT_USE_SUDO" == "true" ]; then
  use_sudo=sudo
  pip_opts=""
fi

$use_sudo apt-get update -y
$use_sudo apt-get install -y \
  build-essential \
  cmake \
  ccache \
  ninja-build \
  cmake-curses-gui \
  libxml2-utils \
  ncurses-dev \
  curl \
  cpio \
  git \
  doxygen \
  device-tree-compiler \
  haskell-stack \
  python3-dev \
  python3-pip \
  python-is-python3 \
  protobuf-compiler \
  python3-protobuf \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu \
  haskell-stack \
  clang \
  libssl-dev \
  libclang-dev \
  libcunit1-dev \
  libsqlite3-dev

# shellcheck disable=SC2086
$use_sudo pip3 install $pip_opts setuptools
# shellcheck disable=SC2086
$use_sudo pip3 install $pip_opts \
  sel4-deps \
  camkes-deps
