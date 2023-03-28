#!/bin/bash

set -e

. ${0%/*}/functions.sh

cd vm-images
. setup.sh
bitbake vm-image-driver
bitbake vm-image-boot
