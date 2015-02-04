#!/bin/sh
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

