#! /bin/sh

SCRIPT_NAME=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT_NAME}`

exec ${SCRIPT_DIR}/build_sel4.sh ${PLATFORM}_sel4test projects/sel4test
