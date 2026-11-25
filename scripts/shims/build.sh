#!/bin/bash
# Build the two compat shims into the TV tree.  Needs an ARM cross gcc that
# targets the tree's glibc (arm-linux-gnueabi-gcc); linking against the tree's
# own libc.so.6 keeps the shims free of Debian version requirements.
set -eu
T=${1:?usage: build.sh <tree-root>}
CC=${CC:-arm-linux-gnueabi-gcc}
d=$(cd "$(dirname "$0")" && pwd)
$CC -shared -fPIC -nostdlib -o /tmp/libglibcxx-assert.so "$d/glibcxx-assert.c" \
    "$T/usr/lib/libc.so.6" -Wl,-soname,libglibcxx-assert.so
$CC -shared -fPIC -nostdlib -o /tmp/libisoc23.so "$d/isoc23-shim.S" \
    "$T/usr/lib/libc.so.6" -Wl,-soname,libisoc23.so
ls -l /tmp/libglibcxx-assert.so /tmp/libisoc23.so
