#!/bin/sh
set -eu
. ./xparse.sh

do_commit() { printf "Commiting\n"; }
do_add()    { printf "Adding: %s\n" "$@"; }
do_two()    { printf "%s %s\n" "${1}" "${2}"; }

xparse_add_option commit  0  do_commit
xparse_add_option add    '*' do_add
xparse_add_option two     2  do_two

xparse_execute_args "$@"
