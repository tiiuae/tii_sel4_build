#!/bin/bash -e
# Copyright 2022, Technology Innovation Institute

SCRIPT_NAME=$(realpath "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_NAME}")
BRANCH_OVERRIDE_CMD=$SCRIPT_DIR/branch-override.sh
REPO_OVERRIDE_CMD=$SCRIPT_DIR/repo-override.sh
MANIFEST_DIR=".repo/manifests"

export INPUT_WORKSPACE="${INPUT_WORKSPACE:-$GITHUB_WORKSPACE/workspace}"

echo "Manifest: $INPUT_MANIFEST"
# shellcheck disable=SC2153
echo "Manifest url: $INPUT_MANIFEST_URL"
echo "Manifest revision: $INPUT_MANIFEST_REVISION"
echo "Workspace: $INPUT_WORKSPACE"

escape_newlines() {
  # escape %, \n and \r
  read -rd '' input || true

  input="${input//'%'/'%25'}"
  input="${input//$'\n'/'%0A'}"
  input="${input//$'\r'/'%0D'}"

  printf '%b' "$input"
}

unescape_newlines() {
  # unescape %, \n and \r
  read -rd '' input || true

  input=${input//'%25'/'%'}
  input=${input//$'%0A'/'\n'}
  input=${input//$'%0D'/'\r'}

  printf '%b' "$input"
}

append_manifest_include() {
  local manifest=$1
  local include_manifest=$2

  xmlstarlet ed \
    --subnode //manifest --type elem --name include \
    --append '//manifest/include[not(@name)]' --type attr --name name --value "$include_manifest" "$manifest" > /tmp/updated-manifest.xml

  # Take updated manifest into use
  mv /tmp/updated-manifest.xml "$manifest"
}

process_branch_overrides() {
  local manifest=$1
  local branch_overrides=$2
  local manifest_dir
  local tmp_manifest
  manifest_dir=$(dirname "$manifest")


  # Create temporary manifest from the repo output
  tmp_manifest=$(mktemp)
  repo manifest > "$tmp_manifest"
  $BRANCH_OVERRIDE_CMD "$tmp_manifest" "$branch_overrides" > "$manifest_dir/branch_override.xml"

  rm "$tmp_manifest"

  append_manifest_include "$manifest" branch_override.xml
}

process_repo_overrides() {
  local manifest=$1
  local repo_overrides=$2
  local manifest_dir
  local tmp_manifest
  manifest_dir=$(dirname "$manifest")

  # Create temporary manifest from the repo output
  tmp_manifest=$(mktemp)
  repo manifest > "$tmp_manifest"
  $REPO_OVERRIDE_CMD "$tmp_manifest" "$repo_overrides" > "$manifest_dir/repo_overrides.xml"

  rm "$tmp_manifest"

  append_manifest_include "$manifest" repo_overrides.xml
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

if [ -n "$INPUT_SSH_KEY" ] && [ ! -r "$SSH_CONF_DIR/actions_key" ]; then
  echo "Add ssh key"

  echo "$INPUT_SSH_KEY" > "$SSH_CONF_DIR/actions_key"
  chmod 0400 "$SSH_CONF_DIR/actions_key"

  # ssh uses user's original home instead of effective home (i.e. HOME), so
  # use global configuration. Setting GIT_SSH_COMMAND variable, or git's
  # core.sshCommand config doesn't seem to work with 'repo sync'.
  # shellcheck disable=SC2154
  if [ -f /.dockerenv ] || [ "${container}" == "podman" ]; then
    cat << EOF > /etc/ssh/ssh_config.d/40-repo.conf
Host *
  IdentityFile $SSH_CONF_DIR/actions_key
  IdentitiesOnly yes
  UserKnownHostsFile $SSH_CONF_DIR/known_hosts
EOF
  else
    cat << EOF > "$SSH_CONF_DIR/config"
Host *
  IdentityFile $SSH_CONF_DIR/actions_key
  IdentitiesOnly yes
  UserKnownHostsFile $SSH_CONF_DIR/known_hosts
EOF
    chmod 600 "$SSH_CONF_DIR/config"
  fi
fi

INPUT_REPO_INIT_OPTS=${INPUT_REPO_INIT_OPTS:-"-c --no-tags --no-clone-bundle --depth 1"}
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

# shellcheck disable=SC2046
repo init $(printf "%b" "${INPUT_REPO_INIT_OPTS}") \
  -u "$INPUT_MANIFEST_URL" \
  -b "$INPUT_MANIFEST_REVISION" \
  -m "$INPUT_MANIFEST"

if [ -z "$INPUT_MANIFEST_XML" ]; then
  echo "Processing overrides"

  MANIFEST_PATH=${MANIFEST_DIR}/${INPUT_MANIFEST}
  if [ -n "$INPUT_BRANCH_OVERRIDE" ]; then
    process_branch_overrides "$MANIFEST_PATH" "$INPUT_BRANCH_OVERRIDE"
  fi

  if [ -n "$INPUT_REPO_OVERRIDE" ]; then
    process_repo_overrides "$MANIFEST_PATH" "$INPUT_REPO_OVERRIDE"
  fi
else
  echo "Using test manifest"

  # Checking out provided manifest xml
  printf '%b' "${INPUT_MANIFEST_XML}" | unescape_newlines > "${MANIFEST_DIR}/test-manifest.xml"

  # shellcheck disable=SC2046
  repo init $(printf "%b" "${INPUT_REPO_INIT_OPTS}") -m test-manifest.xml
fi

# shellcheck disable=SC2046
repo sync $(printf "%b" "${INPUT_REPO_SYNC_OPTS}")

echo "::endgroup::"
echo "manifest-xml=$(repo manifest -r | escape_newlines)" >> "$GITHUB_OUTPUT"
