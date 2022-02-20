#!/bin/sh

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "$(pwd)/.config"

exec ${SCRIPT_DIR}/build_sel4.sh -b ${PLATFORM}_sel4test -s projects/sel4test
