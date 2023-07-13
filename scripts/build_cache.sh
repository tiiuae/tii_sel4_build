#! /bin/sh

set -e

. ${0%/*}/functions.sh

TMPDIR=`mktemp -d ${HOME}/capdl.XXXXXX`

git clone https://github.com/seL4/capdl.git ${TMPDIR}/capdl
cd ${TMPDIR}/capdl/capDL-tool
stack build --only-dependencies
cd ${HOME}
rm -rf ${TMPDIR}
