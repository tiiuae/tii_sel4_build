#! /bin/sh

set -e

. ${0%/*}/functions.sh

exec ${SCRIPT_DIR}/build_sel4.sh ${PLATFORM}_sel4test projects/sel4test
