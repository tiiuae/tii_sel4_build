#!/bin/sh

SCRIPT_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${SCRIPT_NAME})

. "$(pwd)/.config"

SOURCE_DIR=$(ls -d projects/*/apps/Arm/${CAMKES_VM_APP} | cut -f-2 -d'/')

exec ${SCRIPT_DIR}/build_sel4.sh -b ${PLATFORM}_${CAMKES_VM_APP} -s ${SOURCE_DIR} -DNUM_NODES=${NUM_NODES} -DCAMKES_VM_APP=${CAMKES_VM_APP}
