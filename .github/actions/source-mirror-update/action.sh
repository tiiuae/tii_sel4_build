#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

export INPUT_WORKSPACE="${INPUT_WORKSPACE:-$GITHUB_WORKSPACE/workspace}"
export INPUT_MIRROR_DIR="${INPUT_MIRROR_DIR:-${YOCTO_SOURCE_MIRROR_DIR}}"


echo "Machine: ${INPUT_MACHINE:-\(default\)}"
echo "Recipes: $INPUT_RECIPES"
echo "Workspace: $INPUT_WORKSPACE"
echo "Mirror directory: ${INPUT_MIRROR_DIR:-\(default\)}"


cd "$INPUT_WORKSPACE" || exit 1

export YOCTO_SOURCE_MIRROR_DIR="${INPUT_MIRROR_DIR}"
# shellcheck disable=SC1091
. setup-mirror-update.sh
# shellcheck disable=SC2086
bitbake --runall=fetch $INPUT_RECIPES
