#!/bin/sh
USAGE="Usage: $0 DIRECTORY"
[ "$1" = "-h" ] && { echo $USAGE; exit 0; }
[ -d "lib/policy" ] || { echo "ERROR: Should be run in the top-level directory of configi." ; exit 1; }
[ $# -eq 0 ] && { echo "ERROR: Directory argument missing. $USAGE" ; exit 1; }
[ -d "lib/policy/src" ] || mkdir "lib/policy/src"
SRC="$PWD/lib/policy/src/policy.lua"
pushd "$1"
  echo "local policy = {}" > $SRC
  for f in $(find . -type f| cut -f2- -d '/')
  do
    echo "policy[\"$f\"] = [==[" >> $SRC
    cat $1/$f >> $SRC
    echo "]==]" >> $SRC
  done
  echo "return policy" >> $SRC
popd

