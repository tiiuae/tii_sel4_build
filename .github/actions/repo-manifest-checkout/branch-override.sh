#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

usage() {
  cat << EOF
usage: $(basename "$0") MANIFEST BRANCH

Generates an extension manifest with branch overrides to repositories
containing BRANCH. The extension manifest is created by searching for BRANCH
from repositories defined in MANIFEST.

The generated manifest can be taken into use by including at the bottom of
the original manifest.

Arguments
MANIFEST    Input repo manifest. The modified manifest will output to stdout.
BRANCH      Branch name to be searced for.
EOF
}

usage_stderr() {
  usage 1>&2
}

array_contains() {
  printf '%s\0' "${@:2}" | grep -q -F -x -z -- "$1"
}

project_remote_name() {
  local manifest=$1
  local project=$2
  local remote_name

  remote_name=$(xmlstarlet sel -t -v "//project[@name=\"$project\"]/@remote" "$manifest")
  if [ -z "$remote_name" ]; then
    # no remote attribute, fallback to 'default'
    remote_name=$(xmlstarlet sel -t -v "//default/@remote" "$manifest")
  fi

  echo -n "$remote_name"
}

project_remote() {
  local manifest=$1
  local project=$2
  local remote_name


  xmlstarlet sel -t -v \
    "//remote[@name=\"$(project_remote_name "$manifest" "$project")\"]/@fetch" "$manifest"
}

project_url() {
  local manifest=$1
  local project=$2
  local remote

  remote=$(project_remote "$manifest" "$project")

  echo -n "${remote%/}/$project"
}

list_projects() {
  local manifest=$1
  xmlstarlet sel -T -t -m "/manifest/project" -v "concat(@name, ' ')" "$manifest"
}

list_project_urls() {
  local manifest=$1
  local projects=$2

  urls=""
  for project in $projects; do
    urls="${urls} $(project_url "$manifest" "$project")"
  done

  echo -n "$urls" | xargs
}

# returns repository names containing the matching branch name
find_matching_branches() {
  local project_names
  local project_urls
  local branch=$3
  local matches=""

  readarray -td ' ' project_names < <(printf '%s' "$1")
  readarray -td ' ' project_urls < <(printf '%s' "$2")

  for i in "${!project_names[@]}"; do
    if git ls-remote --exit-code "${project_urls[$i]}" "${branch}" &> /dev/null; then
      matches="${matches} ${project_names[$i]}"
    fi
  done

  echo -n "$matches" | xargs
}

generate_project_extend() {
  local project=$1
  local branch=$2

  echo -n "<extend-project name=\"${project}\" revision=\"${branch}\"/>"
}

generate_manifest() {
  cat << EOF
<manifest>
$(printf '%b' "${1}")
</manifest>
EOF
}

if array_contains "-h" "$@" || array_contains "--help" "$@"; then
  usage
  exit 0
fi

MANIFEST_PATH=$1
BRANCH=$2

if [ ! -r "$MANIFEST_PATH" ]; then
  usage_stderr
  exit 1
fi

if [ -z "$BRANCH" ]; then
  usage_stderr
  exit 1
fi

projects=$(list_projects "$MANIFEST_PATH")
urls=$(list_project_urls "$MANIFEST_PATH" "$projects")
matches=$(find_matching_branches "$projects" "$urls" "$BRANCH")

for project in $matches; do
  extends="${extends}\n$(generate_project_extend "${project}" "${BRANCH}")"
done

generate_manifest "${extends#\\n}"

exit 0
