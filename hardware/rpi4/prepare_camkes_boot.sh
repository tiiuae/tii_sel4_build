#! /bin/sh

TFTPBOOT="${TFTPBOOT:-/var/lib/tftpboot}"
DEPLOYDIR="${DEPLOYDIR:-vm-images/build/tmp/deploy/images/vm-raspberrypi4-64}"

# shellcheck disable=SC1091
. "$(pwd)"/.config

if test "$1" = ""; then
  echo "Usage: $0 <CAmkES project name>" 1>&2
  exit 1
fi

IMAGE=$(ls "${PLATFORM}_$1/images/*")
if test ! -e "${IMAGE}"; then
  echo "$1 is not built for ${PLATFORM}"
  exit 1
fi

cp "${IMAGE}" "${TFTPBOOT}/image.rpi4"
cp "${DEPLOYDIR}/bootscripts/tftpboot-bootefi.scr" "${TFTPBOOT}/boot.scr.rpi4"
