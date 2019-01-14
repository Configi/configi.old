#!/bin/sh
set -efuo pipefail
TMP=$(mktemp -d)
touch "$TMP"/three
touch "$TMP"/four
rm "$TMP"/three
rm "$TMP"/four
rmdir "$TMP"
