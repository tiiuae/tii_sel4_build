#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

err_print() {
  printf "%s" "$*" >&2
}

err_exit() {
  local rc=$1
  shift
  err_print "$@"
  exit "$rc"
}

echo "::group::Input validation"

[ ! "$RT_URL" ] && err_exit 1 "RT_URL undefined"
[ ! "$RT_USER" ] && err_exit 1 "RT_USER undefined"
[ ! "$RT_API_KEY" ] && err_exit 1 "RT_API_KEY undefined"

for input in $INPUT_PATHS; do
  SOURCE_DIR=$(echo "$input" | cut -d ":" -f 1)
  DEST_DIR=$(echo "$input" | cut -d ":" -f 2)
  [ ! "$SOURCE_DIR" ] && err_exit 1 "SOURCE_DIR undefined"
  [ ! "$DEST_DIR" ] && err_exit 1 "SOURCE_DIR undefined"
done

echo "::endgroup::"
echo "::group::Artifact upload"

jf c add --url "$RT_URL" --user "$RT_USER" --password "$RT_API_KEY"
jf rt ping

for input in $INPUT_PATHS; do
  SOURCE_DIR=$(echo "$input" | cut -d ":" -f 1)
  DEST_DIR=$(echo "$input" | cut -d ":" -f 2)

  UPLOAD_DIR=$SOURCE_DIR
  if [ "$BUILD_NUM" ]; then
    UPLOAD_DIR=$SOURCE_DIR-b$BUILD_NUM
    mv "$SOURCE_DIR" "$UPLOAD_DIR"
  fi
  jf rt u "$UPLOAD_DIR" "$DEST_DIR" --flat=true
done

echo "::endgroup::"
