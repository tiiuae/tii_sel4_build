#!/bin/bash
#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# Check that we find the utils
if ! [[ -e "${UTILS_SCRIPT}" ]]; then
    printf "%s: Cannot find utils script!\n" "$0" >&2
    exit 1
fi
. "${UTILS_SCRIPT}"

# Apt is being run in a script
: "${DEBIAN_FRONTEND:=noninteractive}"

# Check that we are running as root
if [[ $(id -u) -ne 0 ]]; then
  die "This script must be run as root!"
fi

# Export DEBIAN_FRONTEND if not already set
$(env | grep -q 'DEBIAN_FRONTEND') || export DEBIAN_FRONTEND

# General setup

# Update everything now before installing any tools
apt-get -y update && apt-get -y upgrade

# Tools
#
apt-get -y install --no-install-recommends \
        bison \
        cmake \
        device-tree-compiler \
        dpkg-dev \
        fakeroot \
        flex \
        haskell-stack \
        libelf-dev \
        libncurses-dev \
        libssl-dev \
        libxml2-utils \
        ninja-build \
        protobuf-compiler \
        python3-future \
        python3-jinja2 \
        python3-jsonschema \
        python3-libarchive-c \
        python3-pip \
        python3-ply \
        python3-protobuf \
        python3-pyelftools \
        python3-simpleeval \
        python3-sortedcontainers \
        strace

# Yocto build dependencies, probably some of these 
# are unnecessary for our use case (like 'xterm').
#        build-essential \ # Already installed in base image
#        unzip \ # Already installed in base image
#        wget \  # Already installed in base image
# screen is required by linux menuconfig
apt-get -y install --no-install-recommends \
        chrpath \
        diffstat \
        gawk \
        gcc-multilib \
        git-core \
        liblz4-tool \
        libsdl1.2-dev \
        screen \
        socat \
        texinfo \
        xterm \
        zstd

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
apt-get -y install --no-install-recommends \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu

# Python tools
pip3 install --no-cache-dir \
    aenum \
    ordered_set \
    plyplus \
    pyfdt \
    pyyaml

# Let's build all the capdl's dependencies. Downloading, compiling and
# installing the correct GHC version and all of the dependencies takes
# lots of time and we don't want to redo that everytime we restart the
# container.
pushd . \
    && git clone https://github.com/seL4/capdl.git /tmp/capdl \
    && cd /tmp/capdl/capDL-tool \
    && stack build --only-dependencies \
    && popd \
    && rm -rf /tmp/capdl