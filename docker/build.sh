#! /bin/sh
#
# This script allows us to combine several repos in git-repo manifest.
# Docker refuses symbolic links due to security reasons, but we can work
# around it by creating a temporary copy of this directory, with all
# symbolic links dereferenced.

umask 077

tmpdir=''

cleanup () {
  test -z ${tmpdir} || rm -rf "${tmpdir}"
}

trap cleanup EXIT

tmpdir=$(mktemp -d)

cp docker/* ${tmpdir}

docker build ${tmpdir} -t tiiuae/build:latest
