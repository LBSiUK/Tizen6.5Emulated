#!/bin/bash
# Build tizen-keyrouter.so -- the weston module that advertises the
# tizen_keyrouter global DALi's TV key routing insists on.
#
#   ./build.sh            build in place
#   INSTALL=1 ./build.sh  also copy into /usr/lib64/weston/ (sudo)
#
# Needs: gcc, pkg-config, wayland-devel (wayland-scanner), weston-devel.
set -eu
d=$(cd "$(dirname "$0")" && pwd)
cd "$d"

wayland-scanner server-header tizen-keyrouter.xml tizen-keyrouter-server.h
wayland-scanner private-code  tizen-keyrouter.xml tizen-keyrouter-protocol.c

gcc -O2 -Wall -fPIC -shared -o tizen-keyrouter.so \
	tizen-keyrouter.c tizen-keyrouter-protocol.c \
	$(pkg-config --cflags --libs weston)

ls -l tizen-keyrouter.so

if [ "${INSTALL:-0}" = 1 ]; then
	sudo install -m 755 tizen-keyrouter.so /usr/lib64/weston/
fi
