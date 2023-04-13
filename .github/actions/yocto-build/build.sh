#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

export INPUT_WORKSPACE=${INPUT_WORKSPACE:-$GITHUB_WORKSPACE/workspace}
export INPUT_SETUP_PATH=${INPUT_SETUP_PATH:-setup.sh}

echo "Machine: ${INPUT_MACHINE:-\(default\)}"
echo "Recipes: $INPUT_RECIPES"
echo "Setup: $INPUT_SETUP_PATH"
echo "Workspace: $INPUT_WORKSPACE"

cd "$INPUT_WORKSPACE" || exit 1

export YOCTO_SOURCE_MIRROR_DIR=${YOCTO_SOURCE_MIRROR_DIR:-${HOME}/yocto-mirror}
[ -n "$INPUT_MACHINE" ] && export MACHINE=$INPUT_MACHINE
[ ! -r "$INPUT_SETUP_PATH" ] && exit 1

# shellcheck source=/dev/null
. "$INPUT_SETUP_PATH"

# shellcheck disable=SC2046
bitbake $(printf "%b" "$INPUT_RECIPES")
