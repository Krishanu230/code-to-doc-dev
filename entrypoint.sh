#!/bin/sh
ls
pwd
echo "---"
ls /
echo "---"
ls /usr/app/
# `$#` expands to the number of arguments and `$@` expands to the supplied `args`
printf '%d args:' "$#"
printf " '%s'" "$@"
printf '\n'
env
