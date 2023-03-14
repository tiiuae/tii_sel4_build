#!/usr/bin/env bash
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

for input in $INPUT_PATHS; do
  IMAGE=$(echo "$input" | cut -d ":" -f 1)
  TEST=$(echo "$input" | cut -d ":" -f 2)
  [ ! "$IMAGE" ] && err_exit 1 "IMAGE undefined"
  [ ! "$TEST" ] && err_exit 1 "TEST undefined"
done

echo "::endgroup::"
echo "::group::Run tests"

for input in $INPUT_PATHS; do
  IMAGE=$(basename $(echo "$input" | cut -d ":" -f 1))
  TEST=$(echo "$input" | cut -d ":" -f 2)
  IMAGE="workspace/${TEST}/${IMAGE}"
  run_tests $TEST -i ${IMAGE} -m ${BUILD_LABEL} --usehost
done

echo "::endgroup::"
