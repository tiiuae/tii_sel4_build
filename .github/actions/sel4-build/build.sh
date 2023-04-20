#!/bin/bash -e
# Copyright 2022, Technology Innovation Institute

export INPUT_WORKSPACE="${INPUT_WORKSPACE:-$GITHUB_WORKSPACE/workspace}"

echo "Config: $INPUT_CONFIG"
echo "Target: $INPUT_TARGET"
echo "Workspace: $INPUT_WORKSPACE"

mkdir -p "$INPUT_WORKSPACE"
cd "$INPUT_WORKSPACE" || exit 1

make "$INPUT_CONFIG"
make "$INPUT_TARGET"

