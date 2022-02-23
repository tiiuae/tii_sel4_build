#!/bin/bash -e
# Copyright 2022, Technology Innovation Institute

export INPUT_WORKSPACE="${INPUT_WORKSPACE:-$GITHUB_WORKSPACE/workspace}"

echo "Manifest: $INPUT_MANIFEST"
echo "Manifest url: $INPUT_MANIFEST_URL"
echo "Manifest revision: $INPUT_MANIFEST_REVISION"
echo "Workspace: $INPUT_WORKSPACE"

escape_newlines() {
  # escape %, \n and \r
  { read -rd '' x; echo "${x//'%'/'%25'}"; } | \
  { read -rd '' x; echo "${x//$'\n'/'%0A'}"; } | \
  { read -rd '' x; echo "${x//$'\r'/'%0D'}"; }
}

echo "::group::Set up"

mkdir -p "$INPUT_WORKSPACE"
cd "$INPUT_WORKSPACE" || exit 1

# Use HOME instead of ~/ here because ssh doesn't use effective home
# (meaning HOME variable), but the one defined in /etc/passwd. This means
# that key and config files would not be read.
SSH_CONF_DIR="${HOME}/.ssh"

# Ensure directory for ssh configurations exist
install -m 0700 -d "$SSH_CONF_DIR"

if [ -n "$INPUT_KNOWN_HOSTS" ]; then
  echo "Add host verification keys"

  echo "$INPUT_KNOWN_HOSTS" >> "$SSH_CONF_DIR/known_hosts"
  chmod 0600 "$SSH_CONF_DIR/known_hosts"
fi

if [ -n "$INPUT_SSH_KEYSCAN_URL" ] && \
  ! ssh-keygen -F "$INPUT_SSH_KEYSCAN_URL" -f "$SSH_CONF_DIR/known_hosts"; then
  echo "Add host verification keys using keyscan"

  ssh-keyscan "$INPUT_SSH_KEYSCAN_URL" >> "$SSH_CONF_DIR/known_hosts"
  chmod 0600 "$SSH_CONF_DIR/known_hosts"
fi

if [ -n "$INPUT_SSH_KEY" ]; then
  echo "Add ssh key"

  echo "$INPUT_SSH_KEY" > "$SSH_CONF_DIR/ssh_key"
  chmod 0400 "$SSH_CONF_DIR/ssh_key"

  # ssh uses user's original home instead of effective home (i.e. HOME), so
  # use global configuration. Setting GIT_SSH_COMMAND variable, or git's
  # core.sshCommand config doesn't seem to work with 'repo sync'.
  cat << EOF > /etc/ssh/ssh_config.d/40-repo.conf
Host *
  IdentityFile $SSH_CONF_DIR/ssh_key
  IdentitiesOnly yes
  UserKnownHostsFile $SSH_CONF_DIR/known_hosts
EOF
fi

INPUT_REPO_INIT_OPTS=${INPUT_REPO_INIT_OPTS:-"-c --no-tags --no-clone-bundle
--depth 1"}
INPUT_REPO_SYNC_OPTS=${INPUT_REPO_SYNC_OPTS:-"-c --no-tags --no-clone-bundle --fail-fast -j$(nproc --all 2>/dev/null || echo 1)"}

# Ensure name, email and colors are set
git config user.name &> /dev/null || \
  git config --global user.name "build"
git config user.email &> /dev/null || \
  git config --global user.email "build@automation.ok"
git config color.ui &> /dev/null || \
  git config --global color.ui false

echo "::endgroup::"
echo "::group::Checkout sources"

# shellcheck disable=SC2086
repo init ${INPUT_REPO_INIT_OPTS} \
  -u "$INPUT_MANIFEST_URL" \
  -b "$INPUT_MANIFEST_REVISION" \
  -m "$INPUT_MANIFEST"

# shellcheck disable=SC2086
repo sync ${INPUT_REPO_SYNC_OPTS}

echo "::endgroup::"
echo "::set-output name=manifest-xml::$(repo manifest -r | escape_newlines)"
