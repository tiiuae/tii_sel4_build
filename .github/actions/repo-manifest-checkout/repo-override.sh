#!/bin/bash -e
# Copyright 2023, Technology Innovation Institute

usage() {
  cat << EOF
usage: $(basename "$0") MANIFEST REPO_OVERRIDES

Generates an extension manifest with REPO_OVERRIDES. The REPO_OVERRIDES is a
list of pipe '|' separated git repository URLs where the last element must
match the project name within the manifest (as defined in manifest
specification).

Example:
git://foo/bar.git|https://baz/qux

This generates a manifest with overrides to projects 'bar.git' and 'qux'.

The generated manifest can be taken into use by including it at the bottom of
the original manifest.

Arguments
MANIFEST        Input repo manifest. The modified manifest will output to stdout.
REPO_OVERRIDES  String containing list of repositories following format defined above.
EOF
}

usage_stderr() {
  usage 1>&2
}

# first arg value to be searched, the rest are array
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

parse_project() {
  entry="${1%/}"
  echo "${entry##*/}"
}

parse_fetch_url() {
  echo "${1%/}" | sed 's/\/[^\/]*$//'
}

validate_overrides() {
  local manifest=$1
  local overrides
  local manifest_projects

  readarray -td '|' overrides < <(printf '%s' "$2")
  readarray -td ' ' manifest_projects < <(printf '%s' "$(list_projects "$manifest")")

  for entry in "${overrides[@]}"; do
    project=$(parse_project "$entry")
    fetch_url=$(parse_fetch_url "$entry")

    if [ -z "$project" ] || [ -z "$fetch_url" ]
    then
      echo "invalid REPO_OVERRIDES entry: '${entry}'" 1>&2
      exit 22;
    elif ! array_contains "${project}" "${manifest_projects[@]}"; then
      echo "no such project in manifest: '${project}'" 1>&2
      exit 22
    fi
  done
}

generate_project_extend() {
  local project=$1
  local remote=$2

  echo -n "<extend-project name=\"${project}\" remote=\"${remote}\"/>"
}

generate_remote() {
  local remote_name=$1
  local remote_url=$2

  echo -n "<remote name=\"${remote_name}\" fetch=\"${remote_url}\"/>"
}

generate_manifest() {
  cat << EOF
<manifest>
$(printf '%b' "${1}")

$(printf '%b' "${2}")
</manifest>
EOF
}

# Lets begin!
if array_contains "-h" "$@" || array_contains "--help" "$@"; then
  usage
  exit 0
fi

MANIFEST_PATH=$1
REPO_OVERRIDES=$2

if [ ! -r "$MANIFEST_PATH" ]; then
  usage_stderr
  exit 1
fi

if [ -z "$REPO_OVERRIDES" ]; then
  usage_stderr
  exit 1
fi

validate_overrides "$MANIFEST_PATH" "$REPO_OVERRIDES"

readarray -td '|' overrides < <(printf '%s' "$REPO_OVERRIDES")
readarray -td ' ' manifest_urls < <(printf '%s' "$(list_project_urls "$MANIFEST_PATH")")

override_extends=""
override_remotes=""

for entry in "${overrides[@]}"; do
  project=$(parse_project "$entry")
  fetch_url=$(parse_fetch_url "$entry")
  remote="override_${project}"

  if array_contains "${entry}" "${manifest_urls[@]}"; then
    # Nothing to override
    continue
  fi

  override_extends="${override_extends}\n$(generate_project_extend "$project" "$remote")"
  override_remotes="${override_remotes}\n$(generate_remote "$remote" "$fetch_url")"
done

generate_manifest "${override_remotes#\\n}" "${override_extends#\\n}"

