#! /bin/sh

set -e

. ${0%/*}/functions.sh

DIR=`ls -d projects/*/apps/Arm/${CAMKES_VM_APP} | cut -f-2 -d/`

exec ${SCRIPT_DIR}/build_sel4.sh \
  ${PLATFORM}_${CAMKES_VM_APP} \
  ${DIR} \
  -DCAMKES_VM_APP=${CAMKES_VM_APP}
