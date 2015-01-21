#!/bin/sh
C=test-mkostemp-$$.c

cat >$C <<_EOF
#include <stdio.h>
#include <string.h>
#include <fcntl.h>

static const char template[] = "mkostemp.XXXXXXXX";
int
main(int argc, char **argv)
{
	char tmpf[sizeof template];
        memcpy(tmpf, template, sizeof tmpf);
        mkostemp(tmpf, O_CLOEXEC);
        return 0;
}
_EOF
if $1 -Werror -o test-mkostemp $C 2>/dev/null; then
  echo true
fi
rm -f test-mkostemp $C
