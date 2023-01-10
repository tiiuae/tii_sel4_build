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

# Check that we are running as root
if [[ $(id -u) -ne 0 ]]; then
  die "This script must be run as root!"
fi

# It seems that clashes with group names or GIDs is more common
# than one might think. Here we attempt to make a matching group
# inside the container, but if it fails, we abandon the attempt.

# Try to create the group to match the GID. If a group already exists
# with that name, but a different GID, no change will be made.
# We therefore run groupmod to ensure the GID does match what was
# requested.
# However, either of these steps could fail - but if they do,
# that's OK.
groupadd -fg "${GROUPID}" "${GROUPNAME}" || true
groupmod -g "${GROUPID}" "${GROUPNAME}" || true


# Split the group info into an array
IFS=":" read -r -a group_info <<< "$(getent group "${GROUPNAME}")"
fgroup="${group_info[0]}"
fgid="${group_info[2]}"

GROUP_OK=0
if [ "${fgroup}" == "${GROUPNAME}" ] \
&& [ "${fgid}" == "${GROUPID}" ] ; then
    # This means the group creation has gone OK, 
    # so make a user with the corresponding group
    GROUP_OK=1
fi

if [ ${GROUP_OK} ]; then
    useradd -s ${USHELL} -G sudo -o -u "${USERID}" -g "${GROUPID}" "${USERNAME}"
else
    # If creating the group didn't work well, that's OK, just
    # make the user without the same group as the host. Not as
    # nice, but still works fine.
    useradd -s ${USHELL} -G sudo -o -u "${USERID}" "${USERNAME}"
fi

# Remove the user's password
passwd -d "${USERNAME}"


####################################################################
# Setup sudo for inside the container

# Whenever someone uses sudo, be annoying and remind them that
# it won't be permanent
cat << EOF >> /etc/sudoers
Defaults        lecture_file = /etc/sudoers.lecture
Defaults        lecture = always
EOF

cat << EOF > /etc/sudoers.lecture
##################### Warning! #####################################
This is an ephemeral container environment! You can do things to 
it using sudo, but when you exit, changes made outside of 
the /workspace directory will be lost.
####################################################################
EOF


# Set an appropriate chown setting, based on if the group setup went OK
CHOWN="${USERNAME}"
if [ ${GROUP_OK} ]; then
  CHOWN="${USERNAME}:${GROUPNAME}"
fi


####################################################################
# Setup home dir

# NOTE: the user's home directory is stored in a Docker volume.
#       (normally called $USERNAME-home on the host)
#       That implies that these instructions will only run if said
#       Docker volume does not exist. Therefore, if the below
#       changes, users will only see the effect if they run:
#          docker volume rm $USERNAME-home

mkdir -m 0700 "/home/${USERNAME}"

# Make sure the user owns their home dir
chown -R "${CHOWN}" "/home/${USERNAME}"
chmod -R ug+rw "/home/${USERNAME}"

# Put in some branding
# shellcheck disable=SC2129
cat << EOF >> "/home/${USERNAME}/.bashrc"
echo '                                                  ';
echo '___ ____ ____ _  _ _  _ ____ _    ____ ____ _   _ ';
echo ' |  |___ |    |__| |\ | |  | |    |  | | __  \_/  ';
echo ' |  |___ |___ |  | | \| |__| |___ |__| |__]   |   ';
echo '                                                  ';
echo '_ _  _ _  _ ____ _  _ ____ ___ _ ____ _  _        ';
echo '| |\ | |\ | |  | |  | |__|  |  | |  | |\ |        ';
echo '| | \| | \| |__|  \/  |  |  |  | |__| | \|        ';
echo '                                                  ';
echo '_ _  _ ____ ___ _ ___ _  _ ___ ____               ';
echo '| |\ | [__   |  |  |  |  |  |  |___               ';
echo '| | \| ___]  |  |  |  |__|  |  |___               ';
echo '                                                  ';
echo '                                                  ';
echo 'Hello, welcome to the TII seL4/CAmkES/Yocto       ';
echo '            build environment                     ';
echo '                                                  ';
EOF

# This is a small hack. When the Dockerfiles are building, many of
# the env things are set into the .bashrc of root (since they're
# building as the root user). Here we just copy all those declarations
# and put them in this user's .bashrc.
# This can be an issue with regard to the NOTE above, about Docker
# volumes.
grep "export" /root/.bashrc >> "/home/${USERNAME}/.bashrc"

# Note that this block does not do parameter expansion, so will be
# copied verbatim into the user's .bashrc.
cat << EOF >> /home/${USERNAME}/.bashrc
cd ${WORKDIR}
EOF