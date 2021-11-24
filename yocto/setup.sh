# qemuarm64 is a more generic target
export MACHINE=raspberrypi4-64

. poky/oe-init-build-env

grep meta-sel4 conf/bblayers.conf 2>/dev/null 1>&2 || echo 'BBLAYERS += "/workspace/vm-images/meta-sel4"' >> conf/bblayers.conf
grep meta-raspberrypi conf/bblayers.conf 2>/dev/null 1>&2 || echo 'BBLAYERS += "/workspace/vm-images/meta-raspberrypi"' >> conf/bblayers.conf
