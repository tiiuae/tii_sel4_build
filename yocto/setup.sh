# assume we're in the same dir as layers
if [ -n "$BASH_SOURCE" ]; then
  SCRIPT=$BASH_SOURCE
else
  SCRIPT=$0
fi
LAYERS_ROOT="$(realpath -e "$(dirname "$SCRIPT")")"

# default to VM target
export MACHINE=${MACHINE:-vm-raspberrypi4-64}

. "${LAYERS_ROOT}/poky/oe-init-build-env" "$@"

grep meta-sel4 conf/bblayers.conf 2>/dev/null 1>&2 || \
  printf 'BBLAYERS += "%s/meta-sel4"\n' "$LAYERS_ROOT" >> conf/bblayers.conf

grep meta-raspberrypi conf/bblayers.conf 2>/dev/null 1>&2 || \
  printf 'BBLAYERS += "%s/meta-raspberrypi"\n' "$LAYERS_ROOT" >> conf/bblayers.conf

grep meta-oe conf/bblayers.conf 2>/dev/null 1>&2 || \
  printf 'BBLAYERS += "%s/meta-openembedded/meta-oe"\n' "$LAYERS_ROOT" >> conf/bblayers.conf

grep meta-networking conf/bblayers.conf 2>/dev/null 1>&2 || \
  printf 'BBLAYERS += "%s/meta-openembedded/meta-networking"\n' "$LAYERS_ROOT" >> conf/bblayers.conf

# meta-networking needs meta-python
grep meta-python conf/bblayers.conf 2>/dev/null 1>&2 || \
  printf 'BBLAYERS += "%s/meta-openembedded/meta-python"\n' "$LAYERS_ROOT" >> conf/bblayers.conf
