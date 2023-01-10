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

# General tools/scripts location
: "${TOOLS_DIR:=/tools/bin}"

# Localization
: "${TZ:="Europe/Helsinki"}"
: "${LANG:="en_us.UTF-8"}"
: "${LANGUAGE:="en_US:en:C"}"

# Check that we are running as root
if [[ $(id -u) -ne 0 ]]; then
  die "This script must be run as root!"
fi

# Apt is being run in a script
: "${DEBIAN_FRONTEND:=noninteractive}"

# Export DEBIAN_FRONTEND if not already set
$(env | grep -q 'DEBIAN_FRONTEND') || export DEBIAN_FRONTEND

# General setup

# Update package lists
apt-get -y update

# Configure timezone
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && LC_ALL=C dpkg-reconfigure tzdata

# Configure locale
LC_ALL=C apt-get -y install locales \
    && sed -i -e "s/#\s*\(${LANG}.*\)$/\1/g" /etc/locale.gen \
    && echo "LANG=${LANG}" > /etc/default/locale \
    && echo "LANGUAGE=${LANGUAGE}" >> /etc/default/locale \
    && locale-gen \
    && dpkg-reconfigure locales \
    && update-locale "LANG=${LANG}"

# Configure keyboard layout just in case
apt-get -y install keyboard-configuration
cat <<- EOF > /etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="fi"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF
dpkg-reconfigure keyboard-configuration


# Update everything now before installing any tools
apt-get -y update && apt-get -y upgrade

# Basic tools
#
# Note: Don't really know if all these
# are required or if something is missing.
# seL4 docs about host dependencies are
# inconsistent when compared with
# seL4-CAmkES-L4v-dockerfiles.
#
# Also some tools are our requirements/needs.
#
apt-get -y install --no-install-recommends \
        bc \
        build-essential \
        ca-certificates \
        cpio \
        curl \
        emacs \
        expect \
        file \
        git \
        iproute2 \
        iputils-ping \
        jq \
        man \
        nano \
        python \
        python3-dev \
        python3-pip \
        rsync \
        ssh \
        sudo \
        traceroute \
        unzip \
        vim \
        wget

# Install python dependencies for both python 2 & 3
# Upgrade pip first, then install setuptools (required for other pip packages)
# Install some basic python tools
pip3 install --no-cache-dir \
    setuptools
pip3 install --no-cache-dir \
    gitlint \
    nose \
    reuse

# Setup group for common tools
groupadd -g "${TOOLS_GID}" "${TOOLS_GROUP}" || die "Failed to create group for common tools!"

# Prepare directory for common tools
mkdir -p "${TOOLS_DIR}" && chown -R "$(id -u)":"${TOOLS_GID}" "${TOOLS_DIR}"

# Set parent directory permissions also
#chown -R "$(id -u)":"${TOOLS_GID}" $(dirname "${TOOLS_DIR}")

# Set SGID bit so all tools/scripts setup in this directory
# can be used by all group members
chmod g+s "${TOOLS_DIR}"

# Install Google's repo
wget -O - https://storage.googleapis.com/git-repo-downloads/repo > "${TOOLS_DIR}/repo"
chmod g+x "${TOOLS_DIR}/repo"

# Set up path
echo "export PATH=\$PATH:${TOOLS_DIR}" >> "${HOME}/.bashrc"