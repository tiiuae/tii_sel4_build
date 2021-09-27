#! /bin/sh

SCRIPT_NAME=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT_NAME}`

. `pwd`/.config

exec ${SCRIPT_DIR}/build_sel4.sh ${PLATFORM}_${CAMKES_VM_APP} projects/vm-examples -DNUM_NODES=${NUM_NODES} -DCAMKES_VM_APP=${CAMKES_VM_APP}
