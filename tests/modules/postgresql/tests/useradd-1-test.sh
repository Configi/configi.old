#!/usr/bin/env roundup
#
#/ usage:  rerun stubbs:test -m postgresql -p useradd [--answers <>]
#

# Helpers
# -------
[[ -f ./functions.sh ]] && . ./functions.sh

# The Plan
# --------
describe "useradd"

# ------------------------------
# Replace this test. 
it_fails_without_a_real_test() {
    exit 1
}
# ------------------------------

