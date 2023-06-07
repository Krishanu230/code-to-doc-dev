#!/bin/sh
echo "COMMIT_SHA=${{ github.sha }}" >> ${GITHUB_ENV}
echo "REPO_NAME=${{ github.event.repository.name }}" >> ${GITHUB_ENV}
echo "OWNER_NAME=${{ github.repository_owner }}" >> ${GITHUB_ENV}
echo "KNOWL_BACKEND_HTTP=https://staging-api.knowl.io/" >> ${GITHUB_ENV}
echo "BRANCH_NAME=${{ github.ref_name }}" >> ${GITHUB_ENV}
echo "${{ github.action_path }}" >> "$GITHUB_PATH"
echo "---"
ls /
echo "---"
ls /usr/app/
# `$#` expands to the number of arguments and `$@` expands to the supplied `args`
printf '%d args:' "$#"
printf " '%s'" "$@"
printf '\n'
env
/usr/app/start_doc_gen.sh /github/workspace
