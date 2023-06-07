#!/bin/bash

repo=$GITHUB_REPOSITORY
IFS="/" read -ra components <<< "$repo"
owner=${components[0]}
repository=${components[1]}

export COMMIT_SHA="$GITHUB_SHA"
export REPO_NAME="$repository"
export OWNER_NAME="$owner"
export KNOWL_BACKEND_HTTP="https://api.knowl.io/"
export BRANCH_NAME="$GITHUB_REF_NAME"
echo "---"
ls /
echo "---"
ls /usr/app/
# `$#` expands to the number of arguments and `$@` expands to the supplied `args`
printf '%d args:' "$#"
printf " '%s'" "$@"
printf '\n'
env
cd /usr/app
./start_doc_gen.sh $GITHUB_WORKSPACE
