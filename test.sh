#!/bin/sh
set -eu
. ./xparse.sh

do_commit() { printf "Commiting\n"; }
do_add()    { printf "Adding: %s\n" "$@"; }

xparse_add_option commit  0  do_commit
xparse_add_option add    '*' do_add

xparse_execute_args "$@"
